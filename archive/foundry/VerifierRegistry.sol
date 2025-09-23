// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./RemovalTask.sol";

/**
 * @title VerifierRegistry
 * @dev Registry for verifiers who stake tokens to review removal proofs
 * @notice Handles verifier staking, slashing, and majority-vote verification
 * @author Pierce
 */
contract VerifierRegistry is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // ============ Constants ============
    
    bytes32 public constant VERIFIER_MANAGER_ROLE = keccak256("VERIFIER_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    uint256 public constant MIN_VERIFIER_STAKE = 500 * 10**18;  // Minimum 500 RN tokens
    uint256 public constant VERIFICATION_REWARD = 5 * 10**18;  // 5 RN tokens per verification
    uint256 public constant SLASH_PERCENTAGE = 20;             // 20% slashing for frivolous approvals
    uint256 public constant MIN_VERIFIERS_FOR_TASK = 3;        // Minimum verifiers required
    uint256 public constant MAJORITY_THRESHOLD = 51;           // 51% for majority vote
    
    // ============ Structs ============
    
    /**
     * @dev Verifier information
     */
    struct Verifier {
        bool isRegistered;
        uint256 stake;                  // Staked amount
        uint256 verificationsCompleted; // Total verifications completed
        uint256 correctVerifications;   // Number of correct verifications
        uint256 reputation;             // Reputation score (0-100)
        string description;             // Verifier description
        bool isSlashed;                 // Whether verifier has been slashed
        uint256 registrationTime;       // When verifier registered
        uint256 lastActivityTime;       // Last verification activity
    }
    
    /**
     * @dev Verification session for a task
     */
    struct VerificationSession {
        uint256 taskId;
        address taskContract;
        uint256 requiredVerifiers;      // Number of verifiers needed
        uint256 votesForApproval;       // Votes to approve
        uint256 votesForRejection;      // Votes to reject
        uint256 totalVotes;             // Total votes cast
        bool isCompleted;               // Whether verification is complete
        bool isApproved;                // Final verification result
        uint256 deadline;               // Deadline for verification
        mapping(address => bool) hasVoted;           // Verifier => has voted
        mapping(address => bool) verifierVote;       // Verifier => vote (true = approve)
        address[] assignedVerifiers;    // Verifiers assigned to this session
    }
    
    // ============ State Variables ============
    
    // Contract references
    address public immutable paymentToken;         // RN token contract
    
    // Verifier management
    mapping(address => Verifier) public verifiers;
    address[] public allVerifiers;
    uint256 public totalVerifiers;
    uint256 public totalActiveVerifiers;
    
    // Verification sessions
    mapping(uint256 => VerificationSession) public verificationSessions;  // taskId => session
    mapping(address => uint256[]) public verifierTasks;                   // verifier => task IDs
    
    // Reward pool
    uint256 public verifierRewardPool;
    uint256 public totalRewardsDistributed;
    
    // Statistics
    uint256 public totalVerificationsCompleted;
    uint256 public totalTasksVerified;
    
    // ============ Events ============
    
    event VerifierRegistered(
        address indexed verifier,
        uint256 stake,
        string description
    );
    
    event VerifierStakeIncreased(
        address indexed verifier,
        uint256 additionalStake,
        uint256 newTotal
    );
    
    event VerificationSessionStarted(
        uint256 indexed taskId,
        address indexed taskContract,
        address[] assignedVerifiers,
        uint256 deadline
    );
    
    event VerificationVoteCast(
        uint256 indexed taskId,
        address indexed verifier,
        bool vote,
        uint256 totalVotes
    );
    
    event VerificationCompleted(
        uint256 indexed taskId,
        bool approved,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 totalVotes
    );
    
    event VerifierRewarded(
        address indexed verifier,
        uint256 amount,
        uint256 indexed taskId
    );
    
    event VerifierSlashed(
        address indexed verifier,
        uint256 slashedAmount,
        string reason,
        uint256 indexed taskId
    );
    
    event RewardPoolFunded(
        address indexed funder,
        uint256 amount,
        uint256 newTotal
    );
    
    // ============ Modifiers ============
    
    modifier onlyVerifierManager() {
        require(hasRole(VERIFIER_MANAGER_ROLE, msg.sender), "Caller is not a verifier manager");
        _;
    }
    
    modifier onlyRegisteredVerifier() {
        require(verifiers[msg.sender].isRegistered, "Verifier not registered");
        require(!verifiers[msg.sender].isSlashed, "Verifier is slashed");
        _;
    }
    
    modifier validTaskId(uint256 taskId) {
        require(verificationSessions[taskId].taskContract != address(0), "Verification session does not exist");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _paymentToken) {
        require(_paymentToken != address(0), "Invalid payment token");
        
        paymentToken = _paymentToken;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_MANAGER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }
    
    // ============ Verifier Registration Functions ============
    
    /**
     * @dev Register as a verifier
     */
    function registerVerifier(
        uint256 stakeAmount,
        string calldata description
    ) external whenNotPaused {
        require(!verifiers[msg.sender].isRegistered, "Already registered");
        require(stakeAmount >= MIN_VERIFIER_STAKE, "Insufficient stake");
        require(bytes(description).length > 0, "Description required");
        
        // Transfer stake to this contract
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), stakeAmount);
        
        verifiers[msg.sender] = Verifier({
            isRegistered: true,
            stake: stakeAmount,
            verificationsCompleted: 0,
            correctVerifications: 0,
            reputation: 100, // Start with good reputation
            description: description,
            isSlashed: false,
            registrationTime: block.timestamp,
            lastActivityTime: block.timestamp
        });
        
        allVerifiers.push(msg.sender);
        totalVerifiers++;
        totalActiveVerifiers++;
        
        emit VerifierRegistered(msg.sender, stakeAmount, description);
    }
    
    /**
     * @dev Increase verifier stake
     */
    function increaseStake(uint256 additionalStake) external onlyRegisteredVerifier {
        require(additionalStake > 0, "Additional stake must be greater than 0");
        
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), additionalStake);
        
        verifiers[msg.sender].stake += additionalStake;
        
        emit VerifierStakeIncreased(msg.sender, additionalStake, verifiers[msg.sender].stake);
    }
    
    // ============ Verification Functions ============
    
    /**
     * @dev Start verification session for a task
     */
    function startVerificationSession(
        uint256 taskId,
        address taskContract
    ) external onlyVerifierManager whenNotPaused returns (address[] memory assignedVerifiers) {
        require(verificationSessions[taskId].taskContract == address(0), "Session already exists");
        require(totalActiveVerifiers >= MIN_VERIFIERS_FOR_TASK, "Not enough active verifiers");
        
        // Select verifiers for this task
        assignedVerifiers = _selectVerifiersForTask(taskId);
        require(assignedVerifiers.length >= MIN_VERIFIERS_FOR_TASK, "Could not assign enough verifiers");
        
        // Create verification session
        VerificationSession storage session = verificationSessions[taskId];
        session.taskId = taskId;
        session.taskContract = taskContract;
        session.requiredVerifiers = assignedVerifiers.length;
        session.votesForApproval = 0;
        session.votesForRejection = 0;
        session.totalVotes = 0;
        session.isCompleted = false;
        session.isApproved = false;
        session.deadline = block.timestamp + 3 days; // 3-day verification window
        session.assignedVerifiers = assignedVerifiers;
        
        // Add verifiers as authorized for the task contract
        for (uint256 i = 0; i < assignedVerifiers.length; i++) {
            RemovalTask(taskContract).addAuthorizedVerifier(assignedVerifiers[i]);
            verifierTasks[assignedVerifiers[i]].push(taskId);
        }
        
        emit VerificationSessionStarted(taskId, taskContract, assignedVerifiers, session.deadline);
    }
    
    /**
     * @dev Cast verification vote
     */
    function castVerificationVote(
        uint256 taskId,
        bool approve
    ) external onlyRegisteredVerifier validTaskId(taskId) {
        VerificationSession storage session = verificationSessions[taskId];
        require(!session.isCompleted, "Verification already completed");
        require(block.timestamp <= session.deadline, "Verification deadline passed");
        require(!session.hasVoted[msg.sender], "Already voted");
        require(_isAssignedVerifier(taskId, msg.sender), "Not assigned to this task");
        
        // Record vote
        session.hasVoted[msg.sender] = true;
        session.verifierVote[msg.sender] = approve;
        session.totalVotes++;
        
        if (approve) {
            session.votesForApproval++;
        } else {
            session.votesForRejection++;
        }
        
        // Update verifier activity
        verifiers[msg.sender].lastActivityTime = block.timestamp;
        
        emit VerificationVoteCast(taskId, msg.sender, approve, session.totalVotes);
        
        // Check if verification is complete
        if (session.totalVotes == session.requiredVerifiers || _hasMajority(session)) {
            _completeVerification(taskId);
        }
    }
    
    /**
     * @dev Complete verification (can be called if deadline passed)
     */
    function completeVerification(uint256 taskId) external validTaskId(taskId) {
        VerificationSession storage session = verificationSessions[taskId];
        require(!session.isCompleted, "Verification already completed");
        require(
            block.timestamp > session.deadline || 
            session.totalVotes == session.requiredVerifiers,
            "Verification not ready for completion"
        );
        
        _completeVerification(taskId);
    }
    
    // ============ Dispute Functions ============
    
    /**
     * @dev Handle dispute resolution - slash verifiers who voted incorrectly
     */
    function handleDisputeResolution(
        uint256 taskId,
        bool finalDecision,
        string calldata reason
    ) external onlyVerifierManager validTaskId(taskId) {
        VerificationSession storage session = verificationSessions[taskId];
        require(session.isCompleted, "Verification not completed");
        
        // Slash verifiers who voted against the final decision
        for (uint256 i = 0; i < session.assignedVerifiers.length; i++) {
            address verifierAddr = session.assignedVerifiers[i];
            if (session.hasVoted[verifierAddr] && 
                session.verifierVote[verifierAddr] != finalDecision) {
                _slashVerifier(verifierAddr, reason, taskId);
            }
        }
    }
    
    // ============ Reward Functions ============
    
    /**
     * @dev Fund the verifier reward pool
     */
    function fundRewardPool(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), amount);
        verifierRewardPool += amount;
        
        emit RewardPoolFunded(msg.sender, amount, verifierRewardPool);
    }
    
    /**
     * @dev Distribute rewards to verifiers who participated in verification
     */
    function distributeVerificationRewards(uint256 taskId) external validTaskId(taskId) {
        VerificationSession storage session = verificationSessions[taskId];
        require(session.isCompleted, "Verification not completed");
        
        uint256 rewardPerVerifier = VERIFICATION_REWARD;
        uint256 totalReward = rewardPerVerifier * session.totalVotes;
        
        require(verifierRewardPool >= totalReward, "Insufficient reward pool");
        
        // Distribute rewards to all verifiers who voted
        for (uint256 i = 0; i < session.assignedVerifiers.length; i++) {
            address verifierAddr = session.assignedVerifiers[i];
            if (session.hasVoted[verifierAddr] && !verifiers[verifierAddr].isSlashed) {
                verifierRewardPool -= rewardPerVerifier;
                totalRewardsDistributed += rewardPerVerifier;
                
                IERC20(paymentToken).safeTransfer(verifierAddr, rewardPerVerifier);
                
                // Update verifier stats
                verifiers[verifierAddr].verificationsCompleted++;
                _updateVerifierReputation(verifierAddr, true);
                
                emit VerifierRewarded(verifierAddr, rewardPerVerifier, taskId);
            }
        }
        
        totalVerificationsCompleted += session.totalVotes;
        totalTasksVerified++;
    }
    
    // ============ Administrative Functions ============
    
    /**
     * @dev Slash verifier for malicious behavior
     */
    function slashVerifier(
        address verifierAddr,
        string calldata reason
    ) external onlyVerifierManager {
        _slashVerifier(verifierAddr, reason, 0);
    }
    
    /**
     * @dev Update verifier reputation manually
     */
    function updateVerifierReputation(
        address verifierAddr,
        uint256 newReputation
    ) external onlyVerifierManager {
        require(verifiers[verifierAddr].isRegistered, "Verifier not registered");
        require(newReputation <= 100, "Reputation cannot exceed 100");
        
        verifiers[verifierAddr].reputation = newReputation;
    }
    
    /**
     * @dev Pause the contract
     */
    function pause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "Caller is not a pauser");
        _pause();
    }
    
    /**
     * @dev Unpause the contract
     */
    function unpause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "Caller is not a pauser");
        _unpause();
    }
    
    // ============ View Functions ============
    
    /**
     * @dev Get all registered verifiers
     */
    function getAllVerifiers() external view returns (address[] memory) {
        return allVerifiers;
    }
    
    /**
     * @dev Get active verifiers (not slashed)
     */
    function getActiveVerifiers() external view returns (address[] memory activeVerifiers) {
        address[] memory tempVerifiers = new address[](totalActiveVerifiers);
        uint256 count = 0;
        
        for (uint256 i = 0; i < allVerifiers.length; i++) {
            address verifierAddr = allVerifiers[i];
            if (verifiers[verifierAddr].isRegistered && !verifiers[verifierAddr].isSlashed) {
                tempVerifiers[count] = verifierAddr;
                count++;
            }
        }
        
        activeVerifiers = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            activeVerifiers[i] = tempVerifiers[i];
        }
    }
    
    /**
     * @dev Get verification session details
     */
    function getVerificationSession(uint256 taskId) external view validTaskId(taskId) returns (
        uint256 id,
        address taskContract,
        uint256 requiredVerifiers,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 totalVotes,
        bool isCompleted,
        bool isApproved,
        uint256 deadline,
        address[] memory assignedVerifiers
    ) {
        VerificationSession storage session = verificationSessions[taskId];
        return (
            session.taskId,
            session.taskContract,
            session.requiredVerifiers,
            session.votesForApproval,
            session.votesForRejection,
            session.totalVotes,
            session.isCompleted,
            session.isApproved,
            session.deadline,
            session.assignedVerifiers
        );
    }
    
    /**
     * @dev Get verifier's assigned tasks
     */
    function getVerifierTasks(address verifierAddr) external view returns (uint256[] memory) {
        return verifierTasks[verifierAddr];
    }
    
    /**
     * @dev Get registry statistics
     */
    function getRegistryStats() external view returns (
        uint256 totalVerifiers_,
        uint256 activeVerifiers,
        uint256 totalVerifications,
        uint256 totalTasks,
        uint256 rewardPool,
        uint256 rewardsDistributed
    ) {
        return (
            totalVerifiers,
            totalActiveVerifiers,
            totalVerificationsCompleted,
            totalTasksVerified,
            verifierRewardPool,
            totalRewardsDistributed
        );
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Select verifiers for a task based on reputation and availability
     */
    function _selectVerifiersForTask(uint256 taskId) internal view returns (address[] memory selectedVerifiers) {
        address[] memory candidates = new address[](totalActiveVerifiers);
        uint256 candidateCount = 0;
        
        // Get all active verifiers
        for (uint256 i = 0; i < allVerifiers.length; i++) {
            address verifierAddr = allVerifiers[i];
            if (verifiers[verifierAddr].isRegistered && 
                !verifiers[verifierAddr].isSlashed &&
                verifiers[verifierAddr].reputation >= 50) { // Minimum reputation threshold
                candidates[candidateCount] = verifierAddr;
                candidateCount++;
            }
        }
        
        // Select up to 5 verifiers (or all available if less than 5)
        uint256 selectCount = candidateCount > 5 ? 5 : candidateCount;
        selectCount = selectCount < MIN_VERIFIERS_FOR_TASK ? MIN_VERIFIERS_FOR_TASK : selectCount;
        
        if (candidateCount < selectCount) {
            selectCount = candidateCount;
        }
        
        selectedVerifiers = new address[](selectCount);
        
        // Simple selection based on index (in production, would use better randomization)
        uint256 step = candidateCount > selectCount ? candidateCount / selectCount : 1;
        for (uint256 i = 0; i < selectCount; i++) {
            uint256 index = (i * step + uint256(keccak256(abi.encode(taskId, i))) % step) % candidateCount;
            selectedVerifiers[i] = candidates[index];
        }
    }
    
    /**
     * @dev Check if verifier is assigned to task
     */
    function _isAssignedVerifier(uint256 taskId, address verifierAddr) internal view returns (bool) {
        VerificationSession storage session = verificationSessions[taskId];
        for (uint256 i = 0; i < session.assignedVerifiers.length; i++) {
            if (session.assignedVerifiers[i] == verifierAddr) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Check if session has reached majority vote
     */
    function _hasMajority(VerificationSession storage session) internal view returns (bool) {
        uint256 majorityThreshold = (session.requiredVerifiers * MAJORITY_THRESHOLD) / 100;
        return session.votesForApproval > majorityThreshold || 
               session.votesForRejection > majorityThreshold;
    }
    
    /**
     * @dev Complete verification session
     */
    function _completeVerification(uint256 taskId) internal {
        VerificationSession storage session = verificationSessions[taskId];
        
        session.isCompleted = true;
        session.isApproved = session.votesForApproval > session.votesForRejection;
        
        // If approved, trigger task completion
        if (session.isApproved) {
            RemovalTask(session.taskContract).verifyCompletion();
        }
        
        emit VerificationCompleted(
            taskId,
            session.isApproved,
            session.votesForApproval,
            session.votesForRejection,
            session.totalVotes
        );
    }
    
    /**
     * @dev Internal function to slash verifier
     */
    function _slashVerifier(address verifierAddr, string memory reason, uint256 taskId) internal {
        require(verifiers[verifierAddr].isRegistered, "Verifier not registered");
        require(!verifiers[verifierAddr].isSlashed, "Verifier already slashed");
        
        uint256 slashAmount = (verifiers[verifierAddr].stake * SLASH_PERCENTAGE) / 100;
        
        verifiers[verifierAddr].stake -= slashAmount;
        verifiers[verifierAddr].isSlashed = true;
        verifiers[verifierAddr].reputation = 0;
        totalActiveVerifiers--;
        
        // Transfer slashed amount to reward pool
        verifierRewardPool += slashAmount;
        
        emit VerifierSlashed(verifierAddr, slashAmount, reason, taskId);
    }
    
    /**
     * @dev Update verifier reputation based on verification accuracy
     */
    function _updateVerifierReputation(address verifierAddr, bool correctVerification) internal {
        Verifier storage verifier = verifiers[verifierAddr];
        
        if (correctVerification) {
            verifier.correctVerifications++;
        }
        
        // Calculate accuracy percentage
        uint256 accuracy = (verifier.correctVerifications * 100) / verifier.verificationsCompleted;
        
        // Reputation is based on accuracy with bonus for experience
        verifier.reputation = accuracy;
        if (verifier.verificationsCompleted >= 20) {
            verifier.reputation = verifier.reputation * 105 / 100; // 5% bonus for experience
        }
        if (verifier.reputation > 100) {
            verifier.reputation = 100;
        }
    }
}
