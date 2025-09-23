// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title RemovalTask
 * @dev Individual bounty/escrow task for data broker removal with status transitions
 * @notice Represents a single removal request for one broker + subject combination
 * @author Pierce
 */
contract RemovalTask is ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // ============ Enums ============
    
    /**
     * @dev Status transitions that align with Intel Techniques workbook columns
     */
    enum Status {
        Created,        // Task created, awaiting worker assignment
        Requested,      // Removal request sent to broker
        Responded,      // Broker responded (may need follow-up)
        Verified,       // Removal verified and completed
        Disputed,       // Verification disputed, under review
        Failed,         // Task failed, deadline passed or broker unresponsive
        Refunded        // Task refunded to creator
    }
    
    // ============ Structs ============
    
    /**
     * @dev Evidence submission for verification
     */
    struct Evidence {
        string evidenceCid;     // IPFS/Arweave CID for evidence files
        string summary;         // Brief description of evidence
        uint256 timestamp;      // When evidence was submitted
        address submitter;      // Who submitted the evidence
    }
    
    // ============ State Variables ============
    
    // Task identification
    uint256 public immutable taskId;
    uint256 public immutable brokerId;      // ID from DataBrokerRegistry
    bytes32 public immutable subjectCommit; // Hash of salt + off-chain PII
    
    // Task parameters
    address public immutable creator;       // Who created/funded the task
    address public immutable paymentToken; // Token used for payment (RN)
    uint256 public immutable payout;       // Total payout amount
    uint256 public immutable weight;       // Weight multiplier from broker registry
    uint256 public immutable deadline;     // Task must be completed by this time
    
    // Task state
    Status public currentStatus;
    address public assignedWorker;
    uint256 public createdAt;
    uint256 public requestedAt;     // When removal was requested
    uint256 public respondedAt;     // When broker responded
    uint256 public completedAt;     // When task was completed
    
    // Evidence and verification
    Evidence[] public evidenceSubmissions;
    mapping(address => bool) public authorizedVerifiers;
    uint256 public verificationDeadline;
    
    // Dispute handling
    bool public isDisputed;
    address public disputeInitiator;
    uint256 public disputeBond;
    string public disputeReason;
    
    // Contracts
    address public immutable factory;
    address public immutable verifierRegistry;
    
    // ============ Events ============
    
    event TaskCreated(
        uint256 indexed taskId,
        uint256 indexed brokerId,
        address indexed creator,
        uint256 payout,
        uint256 deadline
    );
    
    event WorkerAssigned(
        uint256 indexed taskId,
        address indexed worker,
        uint256 timestamp
    );
    
    event RemovalRequested(
        uint256 indexed taskId,
        address indexed worker,
        uint256 timestamp,
        string requestSummary
    );
    
    event BrokerResponded(
        uint256 indexed taskId,
        address indexed worker,
        uint256 timestamp,
        string responseSummary
    );
    
    event EvidenceSubmitted(
        uint256 indexed taskId,
        address indexed submitter,
        string evidenceCid,
        uint256 evidenceIndex
    );
    
    event TaskVerified(
        uint256 indexed taskId,
        address indexed verifier,
        uint256 timestamp
    );
    
    event TaskDisputed(
        uint256 indexed taskId,
        address indexed disputeInitiator,
        string reason,
        uint256 bondAmount
    );
    
    event TaskCompleted(
        uint256 indexed taskId,
        address indexed worker,
        uint256 workerPayout,
        uint256 verifierReward
    );
    
    event TaskFailed(
        uint256 indexed taskId,
        string reason,
        uint256 timestamp
    );
    
    event TaskRefunded(
        uint256 indexed taskId,
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );
    
    // ============ Modifiers ============
    
    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call");
        _;
    }
    
    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can call");
        _;
    }
    
    modifier onlyAssignedWorker() {
        require(msg.sender == assignedWorker, "Only assigned worker can call");
        _;
    }
    
    modifier onlyAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender], "Not authorized verifier");
        _;
    }
    
    modifier inStatus(Status expectedStatus) {
        require(currentStatus == expectedStatus, "Invalid status for this operation");
        _;
    }
    
    modifier beforeDeadline() {
        require(block.timestamp <= deadline, "Task deadline has passed");
        _;
    }
    
    modifier notDisputed() {
        require(!isDisputed, "Task is currently disputed");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(
        uint256 _taskId,
        uint256 _brokerId,
        bytes32 _subjectCommit,
        address _creator,
        address _paymentToken,
        uint256 _payout,
        uint256 _weight,
        uint256 _deadline,
        address _verifierRegistry
    ) {
        require(_creator != address(0), "Invalid creator address");
        require(_paymentToken != address(0), "Invalid payment token");
        require(_payout > 0, "Payout must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_verifierRegistry != address(0), "Invalid verifier registry");
        
        taskId = _taskId;
        brokerId = _brokerId;
        subjectCommit = _subjectCommit;
        creator = _creator;
        paymentToken = _paymentToken;
        payout = _payout;
        weight = _weight;
        deadline = _deadline;
        verifierRegistry = _verifierRegistry;
        factory = msg.sender;
        
        currentStatus = Status.Created;
        createdAt = block.timestamp;
        
        emit TaskCreated(_taskId, _brokerId, _creator, _payout, _deadline);
    }
    
    // ============ Task Workflow Functions ============
    
    /**
     * @dev Assign a worker to this task
     */
    function assignWorker(address worker) external onlyFactory inStatus(Status.Created) {
        require(worker != address(0), "Invalid worker address");
        require(worker != creator, "Creator cannot be worker");
        
        assignedWorker = worker;
        
        emit WorkerAssigned(taskId, worker, block.timestamp);
    }
    
    /**
     * @dev Worker marks that removal request has been sent to broker
     */
    function markRemovalRequested(
        string calldata requestSummary
    ) external onlyAssignedWorker inStatus(Status.Created) beforeDeadline {
        currentStatus = Status.Requested;
        requestedAt = block.timestamp;
        
        emit RemovalRequested(taskId, msg.sender, block.timestamp, requestSummary);
    }
    
    /**
     * @dev Worker reports that broker has responded
     */
    function markBrokerResponded(
        string calldata responseSummary
    ) external onlyAssignedWorker inStatus(Status.Requested) beforeDeadline {
        currentStatus = Status.Responded;
        respondedAt = block.timestamp;
        
        emit BrokerResponded(taskId, msg.sender, block.timestamp, responseSummary);
    }
    
    /**
     * @dev Submit evidence for verification (worker or verifier can submit)
     */
    function submitEvidence(
        string calldata evidenceCid,
        string calldata summary
    ) external beforeDeadline returns (uint256 evidenceIndex) {
        require(
            msg.sender == assignedWorker || authorizedVerifiers[msg.sender],
            "Only worker or verifier can submit evidence"
        );
        require(
            currentStatus == Status.Requested || currentStatus == Status.Responded,
            "Invalid status for evidence submission"
        );
        require(bytes(evidenceCid).length > 0, "Evidence CID cannot be empty");
        
        evidenceIndex = evidenceSubmissions.length;
        evidenceSubmissions.push(Evidence({
            evidenceCid: evidenceCid,
            summary: summary,
            timestamp: block.timestamp,
            submitter: msg.sender
        }));
        
        emit EvidenceSubmitted(taskId, msg.sender, evidenceCid, evidenceIndex);
    }
    
    /**
     * @dev Verify task completion (requires authorized verifier)
     */
    function verifyCompletion() external onlyAuthorizedVerifier notDisputed {
        require(
            currentStatus == Status.Responded || currentStatus == Status.Requested,
            "Invalid status for verification"
        );
        require(evidenceSubmissions.length > 0, "No evidence submitted");
        require(block.timestamp <= deadline, "Verification deadline passed");
        
        currentStatus = Status.Verified;
        completedAt = block.timestamp;
        verificationDeadline = block.timestamp + 7 days; // 7-day dispute window
        
        emit TaskVerified(taskId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Initiate dispute on verification (requires bond)
     */
    function initiateDispute(
        string calldata reason,
        uint256 bondAmount
    ) external inStatus(Status.Verified) {
        require(block.timestamp <= verificationDeadline, "Dispute window closed");
        require(!isDisputed, "Already disputed");
        require(bytes(reason).length > 0, "Dispute reason required");
        require(bondAmount > 0, "Dispute bond required");
        
        // Transfer dispute bond from disputer
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), bondAmount);
        
        isDisputed = true;
        disputeInitiator = msg.sender;
        disputeBond = bondAmount;
        disputeReason = reason;
        currentStatus = Status.Disputed;
        
        emit TaskDisputed(taskId, msg.sender, reason, bondAmount);
    }
    
    /**
     * @dev Complete task and distribute payments (after verification period)
     */
    function completeTask() external nonReentrant {
        require(currentStatus == Status.Verified, "Task not verified");
        require(block.timestamp > verificationDeadline, "Still in dispute window");
        require(!isDisputed, "Task is disputed");
        
        currentStatus = Status.Verified; // Final status
        
        // Calculate payouts (80% to worker, 20% to verifier pool)
        uint256 workerPayout = (payout * 80) / 100;
        uint256 verifierReward = payout - workerPayout;
        
        // Transfer payments
        IERC20(paymentToken).safeTransfer(assignedWorker, workerPayout);
        // TODO: Distribute verifier reward to verifier pool in VerifierRegistry
        
        emit TaskCompleted(taskId, assignedWorker, workerPayout, verifierReward);
    }
    
    /**
     * @dev Mark task as failed (deadline passed or irrecoverable failure)
     */
    function markFailed(string calldata reason) external {
        require(
            msg.sender == factory || msg.sender == assignedWorker || msg.sender == creator,
            "Not authorized to mark failed"
        );
        require(
            block.timestamp > deadline || 
            currentStatus == Status.Created || 
            currentStatus == Status.Requested,
            "Cannot mark as failed in current state"
        );
        
        currentStatus = Status.Failed;
        
        emit TaskFailed(taskId, reason, block.timestamp);
    }
    
    /**
     * @dev Refund task to creator (if failed or deadline passed)
     */
    function refund() external nonReentrant {
        require(
            currentStatus == Status.Failed || 
            (block.timestamp > deadline && currentStatus != Status.Verified),
            "Task not eligible for refund"
        );
        require(currentStatus != Status.Refunded, "Already refunded");
        
        currentStatus = Status.Refunded;
        
        // Return escrowed funds to creator
        uint256 refundAmount = payout;
        if (isDisputed) {
            refundAmount += disputeBond; // Return dispute bond as well
        }
        
        IERC20(paymentToken).safeTransfer(creator, refundAmount);
        
        emit TaskRefunded(taskId, creator, refundAmount, block.timestamp);
    }
    
    // ============ Verifier Management ============
    
    /**
     * @dev Add authorized verifier (called by VerifierRegistry)
     */
    function addAuthorizedVerifier(address verifier) external {
        require(msg.sender == verifierRegistry, "Only verifier registry can add verifiers");
        authorizedVerifiers[verifier] = true;
    }
    
    /**
     * @dev Remove authorized verifier (called by VerifierRegistry)
     */
    function removeAuthorizedVerifier(address verifier) external {
        require(msg.sender == verifierRegistry, "Only verifier registry can remove verifiers");
        authorizedVerifiers[verifier] = false;
    }
    
    // ============ View Functions ============
    
    /**
     * @dev Get task summary information
     */
    function getTaskSummary() external view returns (
        uint256 id,
        uint256 broker,
        Status status,
        address worker,
        uint256 payoutAmount,
        uint256 taskDeadline,
        uint256 evidenceCount,
        bool disputed
    ) {
        return (
            taskId,
            brokerId,
            currentStatus,
            assignedWorker,
            payout,
            deadline,
            evidenceSubmissions.length,
            isDisputed
        );
    }
    
    /**
     * @dev Get all evidence submissions
     */
    function getAllEvidence() external view returns (Evidence[] memory) {
        return evidenceSubmissions;
    }
    
    /**
     * @dev Get evidence by index
     */
    function getEvidence(uint256 index) external view returns (Evidence memory) {
        require(index < evidenceSubmissions.length, "Evidence index out of bounds");
        return evidenceSubmissions[index];
    }
    
    /**
     * @dev Get dispute information
     */
    function getDisputeInfo() external view returns (
        bool disputed,
        address initiator,
        uint256 bond,
        string memory reason,
        uint256 deadline_
    ) {
        return (
            isDisputed,
            disputeInitiator,
            disputeBond,
            disputeReason,
            verificationDeadline
        );
    }
    
    /**
     * @dev Check if task is past deadline
     */
    function isPastDeadline() external view returns (bool) {
        return block.timestamp > deadline;
    }
    
    /**
     * @dev Check if task is in dispute window
     */
    function isInDisputeWindow() external view returns (bool) {
        return currentStatus == Status.Verified && 
               block.timestamp <= verificationDeadline;
    }
    
    /**
     * @dev Get time remaining until deadline
     */
    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
}
