// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./RemovalTask.sol";
import "./VerifierRegistry.sol";
import "./DataBrokerRegistry.sol";

/**
 * @title DisputeResolution
 * @dev Lightweight dispute resolution system with commit-reveal voting
 * @notice Handles disputes on verification decisions with challenge bonds
 * @author Pierce
 */
contract DisputeResolution is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // ============ Constants ============
    
    bytes32 public constant ARBITRATOR_ROLE = keccak256("ARBITRATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    uint256 public constant MIN_DISPUTE_BOND = 50 * 10**18;     // Minimum 50 RN tokens
    uint256 public constant VOTING_PERIOD = 5 days;            // 5-day voting period
    uint256 public constant REVEAL_PERIOD = 2 days;            // 2-day reveal period
    uint256 public constant MIN_ARBITRATORS = 3;               // Minimum arbitrators for valid decision
    uint256 public constant ARBITRATOR_REWARD = 10 * 10**18;   // 10 RN tokens per arbitrator
    
    // ============ Enums ============
    
    enum DisputeStatus {
        Created,        // Dispute created, arbitrators being assigned
        Voting,         // Arbitrators are voting (commit phase)
        Revealing,      // Arbitrators are revealing votes
        Resolved,       // Dispute resolved
        Expired         // Dispute expired without resolution
    }
    
    enum DisputeDecision {
        Pending,        // No decision yet
        UpholdOriginal, // Uphold original verification
        OverrideOriginal, // Override original verification
        Inconclusive    // Not enough votes or tie
    }
    
    // ============ Structs ============
    
    /**
     * @dev Dispute information
     */
    struct Dispute {
        uint256 disputeId;
        uint256 taskId;                 // Associated task ID
        address taskContract;           // RemovalTask contract
        address initiator;              // Who initiated the dispute
        address defendant;              // The verifier being disputed (if applicable)
        uint256 bondAmount;             // Dispute bond amount
        string reason;                  // Reason for dispute
        string evidence;                // Additional evidence CID
        DisputeStatus status;           // Current dispute status
        DisputeDecision decision;       // Final decision
        uint256 createdAt;              // When dispute was created
        uint256 votingDeadline;         // Voting deadline
        uint256 revealDeadline;         // Reveal deadline
        address[] assignedArbitrators;  // Arbitrators assigned to this dispute
        uint256 totalVotes;             // Total votes cast
        uint256 votesForOriginal;       // Votes to uphold original verification
        uint256 votesForOverride;       // Votes to override original verification
        bool bondReturned;              // Whether bond has been returned
    }
    
    /**
     * @dev Arbitrator information
     */
    struct Arbitrator {
        bool isRegistered;
        uint256 stake;                  // Staked amount
        uint256 disputesResolved;       // Total disputes resolved
        uint256 correctDecisions;       // Number of correct decisions
        uint256 reputation;             // Reputation score (0-100)
        string description;             // Arbitrator description
        bool isSlashed;                 // Whether arbitrator has been slashed
        uint256 registrationTime;       // When arbitrator registered
    }
    
    /**
     * @dev Vote commitment for commit-reveal voting
     */
    struct VoteCommitment {
        bytes32 commitment;             // Hash of vote + salt
        bool hasCommitted;              // Whether arbitrator has committed
        bool hasRevealed;               // Whether arbitrator has revealed
        bool vote;                      // Actual vote (revealed)
        string reason;                  // Reason for vote
    }
    
    // ============ State Variables ============
    
    // Contract references
    address public immutable paymentToken;         // RN token contract
    address public immutable verifierRegistry;     // VerifierRegistry contract
    address public immutable dataBrokerRegistry;   // DataBrokerRegistry contract
    
    // Dispute management
    uint256 public nextDisputeId = 1;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => VoteCommitment)) public voteCommitments; // disputeId => arbitrator => commitment
    mapping(address => uint256[]) public arbitratorDisputes; // arbitrator => dispute IDs
    
    // Arbitrator management
    mapping(address => Arbitrator) public arbitrators;
    address[] public allArbitrators;
    uint256 public totalArbitrators;
    uint256 public totalActiveArbitrators;
    uint256 public minArbitratorStake = 1000 * 10**18;     // Minimum 1000 RN tokens
    
    // Statistics
    uint256 public totalDisputesCreated;
    uint256 public totalDisputesResolved;
    uint256 public totalBondsSlashed;
    
    // ============ Events ============
    
    event ArbitratorRegistered(
        address indexed arbitrator,
        uint256 stake,
        string description
    );
    
    event DisputeCreated(
        uint256 indexed disputeId,
        uint256 indexed taskId,
        address indexed initiator,
        uint256 bondAmount,
        string reason
    );
    
    event ArbitratorsAssigned(
        uint256 indexed disputeId,
        address[] arbitrators
    );
    
    event VoteCommitted(
        uint256 indexed disputeId,
        address indexed arbitrator,
        bytes32 commitment
    );
    
    event VoteRevealed(
        uint256 indexed disputeId,
        address indexed arbitrator,
        bool vote,
        string reason
    );
    
    event DisputeResolved(
        uint256 indexed disputeId,
        DisputeDecision decision,
        uint256 votesForOriginal,
        uint256 votesForOverride,
        bool bondReturned
    );
    
    event ArbitratorRewarded(
        address indexed arbitrator,
        uint256 amount,
        uint256 indexed disputeId
    );
    
    event ArbitratorSlashed(
        address indexed arbitrator,
        uint256 slashedAmount,
        string reason
    );
    
    event DisputeBondSlashed(
        uint256 indexed disputeId,
        address indexed initiator,
        uint256 bondAmount
    );
    
    // ============ Modifiers ============
    
    modifier onlyRegisteredArbitrator() {
        require(arbitrators[msg.sender].isRegistered, "Arbitrator not registered");
        require(!arbitrators[msg.sender].isSlashed, "Arbitrator is slashed");
        _;
    }
    
    modifier validDisputeId(uint256 disputeId) {
        require(disputeId > 0 && disputeId < nextDisputeId, "Invalid dispute ID");
        _;
    }
    
    modifier inStatus(uint256 disputeId, DisputeStatus expectedStatus) {
        require(disputes[disputeId].status == expectedStatus, "Invalid dispute status");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(
        address _paymentToken,
        address _verifierRegistry,
        address _dataBrokerRegistry
    ) {
        require(_paymentToken != address(0), "Invalid payment token");
        require(_verifierRegistry != address(0), "Invalid verifier registry");
        require(_dataBrokerRegistry != address(0), "Invalid data broker registry");
        
        paymentToken = _paymentToken;
        verifierRegistry = _verifierRegistry;
        dataBrokerRegistry = _dataBrokerRegistry;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ARBITRATOR_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }
    
    // ============ Arbitrator Registration Functions ============
    
    /**
     * @dev Register as an arbitrator
     */
    function registerArbitrator(
        uint256 stakeAmount,
        string calldata description
    ) external whenNotPaused {
        require(!arbitrators[msg.sender].isRegistered, "Already registered");
        require(stakeAmount >= minArbitratorStake, "Insufficient stake");
        require(bytes(description).length > 0, "Description required");
        
        // Transfer stake to this contract
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), stakeAmount);
        
        arbitrators[msg.sender] = Arbitrator({
            isRegistered: true,
            stake: stakeAmount,
            disputesResolved: 0,
            correctDecisions: 0,
            reputation: 100, // Start with good reputation
            description: description,
            isSlashed: false,
            registrationTime: block.timestamp
        });
        
        allArbitrators.push(msg.sender);
        totalArbitrators++;
        totalActiveArbitrators++;
        
        emit ArbitratorRegistered(msg.sender, stakeAmount, description);
    }
    
    // ============ Dispute Functions ============
    
    /**
     * @dev Create a new dispute
     */
    function createDispute(
        uint256 taskId,
        address taskContract,
        uint256 bondAmount,
        string calldata reason,
        string calldata evidenceCid
    ) external whenNotPaused nonReentrant returns (uint256 disputeId) {
        require(bondAmount >= MIN_DISPUTE_BOND, "Insufficient dispute bond");
        require(bytes(reason).length > 0, "Reason required");
        require(totalActiveArbitrators >= MIN_ARBITRATORS, "Not enough active arbitrators");
        
        // Verify task exists and is in correct state
        RemovalTask task = RemovalTask(taskContract);
        require(task.taskId() == taskId, "Task ID mismatch");
        require(task.currentStatus() == RemovalTask.Status.Verified, "Task not in verified status");
        require(task.isInDisputeWindow(), "Dispute window closed");
        
        // Transfer dispute bond
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), bondAmount);
        
        disputeId = nextDisputeId++;
        
        // Select arbitrators
        address[] memory selectedArbitrators = _selectArbitrators(disputeId);
        
        disputes[disputeId] = Dispute({
            disputeId: disputeId,
            taskId: taskId,
            taskContract: taskContract,
            initiator: msg.sender,
            defendant: address(0), // Could be set later if disputing specific verifier
            bondAmount: bondAmount,
            reason: reason,
            evidence: evidenceCid,
            status: DisputeStatus.Voting,
            decision: DisputeDecision.Pending,
            createdAt: block.timestamp,
            votingDeadline: block.timestamp + VOTING_PERIOD,
            revealDeadline: block.timestamp + VOTING_PERIOD + REVEAL_PERIOD,
            assignedArbitrators: selectedArbitrators,
            totalVotes: 0,
            votesForOriginal: 0,
            votesForOverride: 0,
            bondReturned: false
        });
        
        totalDisputesCreated++;
        
        // Add dispute to each arbitrator's list
        for (uint256 i = 0; i < selectedArbitrators.length; i++) {
            arbitratorDisputes[selectedArbitrators[i]].push(disputeId);
        }
        
        emit DisputeCreated(disputeId, taskId, msg.sender, bondAmount, reason);
        emit ArbitratorsAssigned(disputeId, selectedArbitrators);
    }
    
    /**
     * @dev Commit vote (commit phase of commit-reveal voting)
     */
    function commitVote(
        uint256 disputeId,
        bytes32 commitment
    ) external onlyRegisteredArbitrator validDisputeId(disputeId) inStatus(disputeId, DisputeStatus.Voting) {
        require(block.timestamp <= disputes[disputeId].votingDeadline, "Voting period ended");
        require(_isAssignedArbitrator(disputeId, msg.sender), "Not assigned to this dispute");
        require(!voteCommitments[disputeId][msg.sender].hasCommitted, "Already committed");
        
        voteCommitments[disputeId][msg.sender].commitment = commitment;
        voteCommitments[disputeId][msg.sender].hasCommitted = true;
        
        emit VoteCommitted(disputeId, msg.sender, commitment);
        
        // Check if all arbitrators have committed
        if (_allArbitratorsCommitted(disputeId)) {
            disputes[disputeId].status = DisputeStatus.Revealing;
        }
    }
    
    /**
     * @dev Reveal vote (reveal phase of commit-reveal voting)
     */
    function revealVote(
        uint256 disputeId,
        bool vote,
        string calldata reason,
        uint256 salt
    ) external onlyRegisteredArbitrator validDisputeId(disputeId) {
        Dispute storage dispute = disputes[disputeId];
        require(
            dispute.status == DisputeStatus.Revealing || 
            (dispute.status == DisputeStatus.Voting && block.timestamp > dispute.votingDeadline),
            "Not in reveal phase"
        );
        require(block.timestamp <= dispute.revealDeadline, "Reveal period ended");
        require(voteCommitments[disputeId][msg.sender].hasCommitted, "No commitment found");
        require(!voteCommitments[disputeId][msg.sender].hasRevealed, "Already revealed");
        
        // Verify commitment
        bytes32 hash = keccak256(abi.encodePacked(vote, reason, salt));
        require(hash == voteCommitments[disputeId][msg.sender].commitment, "Invalid reveal");
        
        // Record vote
        voteCommitments[disputeId][msg.sender].hasRevealed = true;
        voteCommitments[disputeId][msg.sender].vote = vote;
        voteCommitments[disputeId][msg.sender].reason = reason;
        
        dispute.totalVotes++;
        if (vote) {
            dispute.votesForOriginal++;
        } else {
            dispute.votesForOverride++;
        }
        
        emit VoteRevealed(disputeId, msg.sender, vote, reason);
        
        // Check if all votes revealed or reveal period ended
        if (dispute.totalVotes == dispute.assignedArbitrators.length || 
            block.timestamp > dispute.revealDeadline) {
            _resolveDispute(disputeId);
        }
    }
    
    /**
     * @dev Force resolve dispute (can be called after deadlines)
     */
    function resolveDispute(uint256 disputeId) external validDisputeId(disputeId) {
        Dispute storage dispute = disputes[disputeId];
        require(
            dispute.status == DisputeStatus.Revealing || 
            block.timestamp > dispute.revealDeadline,
            "Dispute not ready for resolution"
        );
        
        _resolveDispute(disputeId);
    }
    
    // ============ Administrative Functions ============
    
    /**
     * @dev Slash arbitrator for malicious behavior
     */
    function slashArbitrator(
        address arbitratorAddr,
        uint256 slashAmount,
        string calldata reason
    ) external onlyRole(ARBITRATOR_ROLE) {
        require(arbitrators[arbitratorAddr].isRegistered, "Arbitrator not registered");
        require(!arbitrators[arbitratorAddr].isSlashed, "Arbitrator already slashed");
        require(slashAmount <= arbitrators[arbitratorAddr].stake, "Slash amount exceeds stake");
        
        arbitrators[arbitratorAddr].stake -= slashAmount;
        arbitrators[arbitratorAddr].isSlashed = true;
        arbitrators[arbitratorAddr].reputation = 0;
        totalActiveArbitrators--;
        
        // Add slashed amount to dispute resolution fund
        // (could be used for future arbitrator rewards)
        
        emit ArbitratorSlashed(arbitratorAddr, slashAmount, reason);
    }
    
    /**
     * @dev Update minimum arbitrator stake
     */
    function updateMinArbitratorStake(uint256 newStake) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minArbitratorStake = newStake;
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
     * @dev Get dispute details
     */
    function getDispute(uint256 disputeId) external view validDisputeId(disputeId) returns (
        uint256 id,
        uint256 taskId,
        address initiator,
        uint256 bondAmount,
        string memory reason,
        DisputeStatus status,
        DisputeDecision decision,
        uint256 votingDeadline,
        uint256 revealDeadline,
        address[] memory assignedArbitrators,
        uint256 totalVotes,
        uint256 votesForOriginal,
        uint256 votesForOverride
    ) {
        Dispute storage dispute = disputes[disputeId];
        return (
            dispute.disputeId,
            dispute.taskId,
            dispute.initiator,
            dispute.bondAmount,
            dispute.reason,
            dispute.status,
            dispute.decision,
            dispute.votingDeadline,
            dispute.revealDeadline,
            dispute.assignedArbitrators,
            dispute.totalVotes,
            dispute.votesForOriginal,
            dispute.votesForOverride
        );
    }
    
    /**
     * @dev Get arbitrator's assigned disputes
     */
    function getArbitratorDisputes(address arbitratorAddr) external view returns (uint256[] memory) {
        return arbitratorDisputes[arbitratorAddr];
    }
    
    /**
     * @dev Get all active arbitrators
     */
    function getActiveArbitrators() external view returns (address[] memory activeArbitrators) {
        address[] memory tempArbitrators = new address[](totalActiveArbitrators);
        uint256 count = 0;
        
        for (uint256 i = 0; i < allArbitrators.length; i++) {
            address arbitratorAddr = allArbitrators[i];
            if (arbitrators[arbitratorAddr].isRegistered && !arbitrators[arbitratorAddr].isSlashed) {
                tempArbitrators[count] = arbitratorAddr;
                count++;
            }
        }
        
        activeArbitrators = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            activeArbitrators[i] = tempArbitrators[i];
        }
    }
    
    /**
     * @dev Get dispute resolution statistics
     */
    function getDisputeStats() external view returns (
        uint256 totalDisputes,
        uint256 resolvedDisputes,
        uint256 totalArbitrators_,
        uint256 activeArbitrators,
        uint256 bondsSlashed
    ) {
        return (
            totalDisputesCreated,
            totalDisputesResolved,
            totalArbitrators,
            totalActiveArbitrators,
            totalBondsSlashed
        );
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Select arbitrators for a dispute
     */
    function _selectArbitrators(uint256 disputeId) internal view returns (address[] memory selectedArbitrators) {
        address[] memory candidates = new address[](totalActiveArbitrators);
        uint256 candidateCount = 0;
        
        // Get all active arbitrators
        for (uint256 i = 0; i < allArbitrators.length; i++) {
            address arbitratorAddr = allArbitrators[i];
            if (arbitrators[arbitratorAddr].isRegistered && 
                !arbitrators[arbitratorAddr].isSlashed &&
                arbitrators[arbitratorAddr].reputation >= 50) {
                candidates[candidateCount] = arbitratorAddr;
                candidateCount++;
            }
        }
        
        // Select arbitrators (minimum 3, maximum 5)
        uint256 selectCount = candidateCount > 5 ? 5 : candidateCount;
        selectCount = selectCount < MIN_ARBITRATORS ? MIN_ARBITRATORS : selectCount;
        
        if (candidateCount < selectCount) {
            selectCount = candidateCount;
        }
        
        selectedArbitrators = new address[](selectCount);
        
        // Simple pseudo-random selection
        for (uint256 i = 0; i < selectCount; i++) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(disputeId, i, block.timestamp))) % candidateCount;
            selectedArbitrators[i] = candidates[randomIndex];
            
            // Remove selected arbitrator from candidates to avoid duplicates
            candidates[randomIndex] = candidates[candidateCount - 1];
            candidateCount--;
        }
    }
    
    /**
     * @dev Check if arbitrator is assigned to dispute
     */
    function _isAssignedArbitrator(uint256 disputeId, address arbitratorAddr) internal view returns (bool) {
        address[] memory assigned = disputes[disputeId].assignedArbitrators;
        for (uint256 i = 0; i < assigned.length; i++) {
            if (assigned[i] == arbitratorAddr) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Check if all arbitrators have committed
     */
    function _allArbitratorsCommitted(uint256 disputeId) internal view returns (bool) {
        address[] memory assigned = disputes[disputeId].assignedArbitrators;
        for (uint256 i = 0; i < assigned.length; i++) {
            if (!voteCommitments[disputeId][assigned[i]].hasCommitted) {
                return false;
            }
        }
        return true;
    }
    
    /**
     * @dev Resolve dispute and distribute rewards/penalties
     */
    function _resolveDispute(uint256 disputeId) internal {
        Dispute storage dispute = disputes[disputeId];
        
        dispute.status = DisputeStatus.Resolved;
        
        // Determine decision
        if (dispute.totalVotes == 0) {
            dispute.decision = DisputeDecision.Inconclusive;
        } else if (dispute.votesForOriginal > dispute.votesForOverride) {
            dispute.decision = DisputeDecision.UpholdOriginal;
        } else if (dispute.votesForOverride > dispute.votesForOriginal) {
            dispute.decision = DisputeDecision.OverrideOriginal;
        } else {
            dispute.decision = DisputeDecision.Inconclusive;
        }
        
        // Handle bond return/slash
        bool returnBond = dispute.decision == DisputeDecision.OverrideOriginal;
        if (returnBond && !dispute.bondReturned) {
            IERC20(paymentToken).safeTransfer(dispute.initiator, dispute.bondAmount);
            dispute.bondReturned = true;
        } else if (!returnBond) {
            totalBondsSlashed += dispute.bondAmount;
            emit DisputeBondSlashed(disputeId, dispute.initiator, dispute.bondAmount);
        }
        
        // Distribute rewards to arbitrators who voted with majority
        _distributeArbitratorRewards(disputeId);
        
        // Update verifier registry with resolution
        if (dispute.decision != DisputeDecision.Inconclusive) {
            bool finalDecision = dispute.decision == DisputeDecision.UpholdOriginal;
            VerifierRegistry(verifierRegistry).handleDisputeResolution(
                dispute.taskId,
                finalDecision,
                "Dispute resolution"
            );
        }
        
        // Record dispute in data broker registry
        DataBrokerRegistry(dataBrokerRegistry).recordDispute(
            RemovalTask(dispute.taskContract).brokerId()
        );
        
        totalDisputesResolved++;
        
        emit DisputeResolved(
            disputeId,
            dispute.decision,
            dispute.votesForOriginal,
            dispute.votesForOverride,
            returnBond
        );
    }
    
    /**
     * @dev Distribute rewards to arbitrators
     */
    function _distributeArbitratorRewards(uint256 disputeId) internal {
        Dispute storage dispute = disputes[disputeId];
        
        if (dispute.decision == DisputeDecision.Inconclusive) {
            return; // No rewards for inconclusive decisions
        }
        
        bool majorityVote = dispute.decision == DisputeDecision.UpholdOriginal;
        
        for (uint256 i = 0; i < dispute.assignedArbitrators.length; i++) {
            address arbitratorAddr = dispute.assignedArbitrators[i];
            
            if (voteCommitments[disputeId][arbitratorAddr].hasRevealed &&
                voteCommitments[disputeId][arbitratorAddr].vote == majorityVote) {
                
                // Reward arbitrator who voted with majority
                IERC20(paymentToken).safeTransfer(arbitratorAddr, ARBITRATOR_REWARD);
                
                // Update arbitrator stats
                arbitrators[arbitratorAddr].disputesResolved++;
                arbitrators[arbitratorAddr].correctDecisions++;
                _updateArbitratorReputation(arbitratorAddr);
                
                emit ArbitratorRewarded(arbitratorAddr, ARBITRATOR_REWARD, disputeId);
            }
        }
    }
    
    /**
     * @dev Update arbitrator reputation
     */
    function _updateArbitratorReputation(address arbitratorAddr) internal {
        Arbitrator storage arbitrator = arbitrators[arbitratorAddr];
        
        if (arbitrator.disputesResolved > 0) {
            uint256 accuracy = (arbitrator.correctDecisions * 100) / arbitrator.disputesResolved;
            arbitrator.reputation = accuracy;
            
            // Bonus for experience
            if (arbitrator.disputesResolved >= 10) {
                arbitrator.reputation = arbitrator.reputation * 105 / 100;
            }
            
            if (arbitrator.reputation > 100) {
                arbitrator.reputation = 100;
            }
        }
    }
}
