// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./RemovalTask.sol";
import "./DataBrokerRegistry.sol";

/**
 * @title RemovalTaskFactory
 * @dev Factory contract for creating and managing RemovalTask instances
 * @notice Creates bounty/escrow tasks for data broker removals
 * @author Pierce
 */
contract RemovalTaskFactory is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // ============ Constants ============
    
    bytes32 public constant TASK_MANAGER_ROLE = keccak256("TASK_MANAGER_ROLE");
    bytes32 public constant WORKER_ROLE = keccak256("WORKER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    uint256 public constant MIN_TASK_DURATION = 7 days;     // Minimum task duration
    uint256 public constant MAX_TASK_DURATION = 90 days;    // Maximum task duration
    uint256 public constant MIN_PAYOUT = 10 * 10**18;      // Minimum 10 RN tokens
    uint256 public constant PLATFORM_FEE_RATE = 5;         // 5% platform fee
    
    // ============ Structs ============
    
    /**
     * @dev Task creation parameters
     */
    struct TaskParams {
        uint256 brokerId;           // ID from DataBrokerRegistry
        bytes32 subjectCommit;      // Hash of salt + PII (no PII on-chain)
        uint256 payout;             // Total payout amount
        uint256 duration;           // Task duration in seconds
        string description;         // Task description/requirements
        address preferredWorker;    // Optional: preferred worker address
    }
    
    /**
     * @dev Worker information
     */
    struct Worker {
        bool isRegistered;
        uint256 stake;              // Staked amount
        uint256 completedTasks;     // Number of completed tasks
        uint256 successRate;        // Success rate (0-100)
        uint256 reputation;         // Reputation score
        string description;         // Worker description
        bool isSlashed;             // Whether worker has been slashed
    }
    
    // ============ State Variables ============
    
    // Contract references
    address public immutable paymentToken;         // RN token contract
    address public immutable dataBrokerRegistry;   // DataBrokerRegistry contract
    address public immutable verifierRegistry;     // VerifierRegistry contract
    
    // Task management
    uint256 public nextTaskId = 1;
    mapping(uint256 => address) public tasks;              // taskId -> RemovalTask address
    mapping(address => uint256[]) public userTasks;        // user -> task IDs created
    mapping(address => uint256[]) public workerTasks;      // worker -> task IDs assigned
    
    // Worker management
    mapping(address => Worker) public workers;
    address[] public allWorkers;
    uint256 public totalWorkers;
    uint256 public minWorkerStake = 100 * 10**18;          // Minimum 100 RN tokens
    
    // Platform settings
    address public platformTreasury;
    uint256 public platformFeesCollected;
    
    // Statistics
    uint256 public totalTasksCreated;
    uint256 public totalTasksCompleted;
    uint256 public totalPayoutsDistributed;
    
    // ============ Events ============
    
    event TaskCreated(
        uint256 indexed taskId,
        address indexed creator,
        uint256 indexed brokerId,
        address taskContract,
        uint256 payout
    );
    
    event WorkerRegistered(
        address indexed worker,
        uint256 stake,
        string description
    );
    
    event WorkerAssignedToTask(
        uint256 indexed taskId,
        address indexed worker,
        address indexed taskContract
    );
    
    event TaskCompleted(
        uint256 indexed taskId,
        address indexed worker,
        uint256 payout,
        uint256 platformFee
    );
    
    event WorkerSlashed(
        address indexed worker,
        uint256 slashedAmount,
        string reason
    );
    
    event PlatformFeeUpdated(
        uint256 oldRate,
        uint256 newRate
    );
    
    event MinWorkerStakeUpdated(
        uint256 oldStake,
        uint256 newStake
    );
    
    event PlatformTreasuryUpdated(
        address indexed oldTreasury,
        address indexed newTreasury
    );
    
    // ============ Modifiers ============
    
    modifier onlyTaskManager() {
        require(hasRole(TASK_MANAGER_ROLE, msg.sender), "Caller is not a task manager");
        _;
    }
    
    modifier onlyRegisteredWorker() {
        require(workers[msg.sender].isRegistered, "Worker not registered");
        require(!workers[msg.sender].isSlashed, "Worker is slashed");
        _;
    }
    
    modifier validTaskId(uint256 taskId) {
        require(taskId > 0 && taskId < nextTaskId, "Invalid task ID");
        require(tasks[taskId] != address(0), "Task does not exist");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(
        address _paymentToken,
        address _dataBrokerRegistry,
        address _verifierRegistry,
        address _platformTreasury
    ) {
        require(_paymentToken != address(0), "Invalid payment token");
        require(_dataBrokerRegistry != address(0), "Invalid broker registry");
        require(_verifierRegistry != address(0), "Invalid verifier registry");
        require(_platformTreasury != address(0), "Invalid platform treasury");
        
        paymentToken = _paymentToken;
        dataBrokerRegistry = _dataBrokerRegistry;
        verifierRegistry = _verifierRegistry;
        platformTreasury = _platformTreasury;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TASK_MANAGER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }
    
    // ============ Task Creation Functions ============
    
    /**
     * @dev Create a new removal task
     */
    function createTask(
        TaskParams calldata params
    ) external whenNotPaused nonReentrant returns (uint256 taskId, address taskContract) {
        require(params.payout >= MIN_PAYOUT, "Payout below minimum");
        require(params.duration >= MIN_TASK_DURATION, "Duration too short");
        require(params.duration <= MAX_TASK_DURATION, "Duration too long");
        require(params.subjectCommit != bytes32(0), "Invalid subject commit");
        
        // Verify broker exists and is active
        DataBrokerRegistry registry = DataBrokerRegistry(dataBrokerRegistry);
        (uint256 weight, bool isActive) = registry.getBrokerWeightAndStatus(params.brokerId);
        require(isActive, "Broker is not active");
        
        // Calculate total cost (payout + platform fee)
        uint256 platformFee = (params.payout * PLATFORM_FEE_RATE) / 100;
        uint256 totalCost = params.payout + platformFee;
        
        // Transfer funds to this contract for escrow
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), totalCost);
        
        taskId = nextTaskId++;
        uint256 deadline = block.timestamp + params.duration;
        
        // Use broker weight for weighted payouts (already retrieved above)
        
        // Create new RemovalTask contract
        RemovalTask newTask = new RemovalTask(
            taskId,
            params.brokerId,
            params.subjectCommit,
            msg.sender,
            paymentToken,
            params.payout,
            weight,
            deadline,
            verifierRegistry
        );
        
        taskContract = address(newTask);
        tasks[taskId] = taskContract;
        userTasks[msg.sender].push(taskId);
        
        // Transfer escrowed payout to task contract
        IERC20(paymentToken).safeTransfer(taskContract, params.payout);
        
        // Keep platform fee in this contract
        platformFeesCollected += platformFee;
        
        totalTasksCreated++;
        
        // Auto-assign preferred worker if specified and eligible
        if (params.preferredWorker != address(0) && 
            workers[params.preferredWorker].isRegistered &&
            !workers[params.preferredWorker].isSlashed) {
            _assignWorkerToTask(taskId, params.preferredWorker);
        }
        
        emit TaskCreated(taskId, msg.sender, params.brokerId, taskContract, params.payout);
    }
    
    /**
     * @dev Batch create multiple tasks
     */
    function batchCreateTasks(
        TaskParams[] calldata tasksParams
    ) external whenNotPaused nonReentrant returns (uint256[] memory taskIds, address[] memory taskContracts) {
        require(tasksParams.length > 0, "No tasks provided");
        require(tasksParams.length <= 20, "Too many tasks in batch");
        
        taskIds = new uint256[](tasksParams.length);
        taskContracts = new address[](tasksParams.length);
        
        uint256 totalCost = 0;
        
        // Calculate total cost first
        for (uint256 i = 0; i < tasksParams.length; i++) {
            require(tasksParams[i].payout >= MIN_PAYOUT, "Payout below minimum");
            uint256 platformFee = (tasksParams[i].payout * PLATFORM_FEE_RATE) / 100;
            totalCost += tasksParams[i].payout + platformFee;
        }
        
        // Transfer total funds upfront
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), totalCost);
        
        // Create tasks
        for (uint256 i = 0; i < tasksParams.length; i++) {
            (uint256 taskId, address taskContract) = _createTaskInternal(tasksParams[i], msg.sender);
            taskIds[i] = taskId;
            taskContracts[i] = taskContract;
        }
    }
    
    // ============ Worker Management Functions ============
    
    /**
     * @dev Register as a worker
     */
    function registerWorker(
        uint256 stakeAmount,
        string calldata description
    ) external whenNotPaused {
        require(!workers[msg.sender].isRegistered, "Already registered");
        require(stakeAmount >= minWorkerStake, "Insufficient stake");
        require(bytes(description).length > 0, "Description required");
        
        // Transfer stake to this contract
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), stakeAmount);
        
        workers[msg.sender] = Worker({
            isRegistered: true,
            stake: stakeAmount,
            completedTasks: 0,
            successRate: 100, // Start with 100% success rate
            reputation: 100,   // Start with good reputation
            description: description,
            isSlashed: false
        });
        
        allWorkers.push(msg.sender);
        totalWorkers++;
        
        // Grant worker role
        _grantRole(WORKER_ROLE, msg.sender);
        
        emit WorkerRegistered(msg.sender, stakeAmount, description);
    }
    
    /**
     * @dev Assign worker to task
     */
    function assignWorkerToTask(
        uint256 taskId,
        address worker
    ) external onlyTaskManager validTaskId(taskId) {
        _assignWorkerToTask(taskId, worker);
    }
    
    /**
     * @dev Worker can self-assign to available tasks
     */
    function selfAssignToTask(uint256 taskId) external onlyRegisteredWorker validTaskId(taskId) {
        RemovalTask task = RemovalTask(tasks[taskId]);
        require(task.currentStatus() == RemovalTask.Status.Created, "Task not available");
        require(task.assignedWorker() == address(0), "Task already assigned");
        
        _assignWorkerToTask(taskId, msg.sender);
    }
    
    /**
     * @dev Slash worker for poor performance
     */
    function slashWorker(
        address worker,
        uint256 slashAmount,
        string calldata reason
    ) external onlyTaskManager {
        require(workers[worker].isRegistered, "Worker not registered");
        require(!workers[worker].isSlashed, "Worker already slashed");
        require(slashAmount <= workers[worker].stake, "Slash amount exceeds stake");
        
        workers[worker].stake -= slashAmount;
        workers[worker].isSlashed = true;
        workers[worker].reputation = 0;
        
        // Transfer slashed amount to platform treasury
        IERC20(paymentToken).safeTransfer(platformTreasury, slashAmount);
        
        // Revoke worker role
        _revokeRole(WORKER_ROLE, worker);
        
        emit WorkerSlashed(worker, slashAmount, reason);
    }
    
    // ============ Task Completion Functions ============
    
    /**
     * @dev Mark task as completed and distribute rewards
     */
    function completeTask(uint256 taskId) external validTaskId(taskId) {
        RemovalTask task = RemovalTask(tasks[taskId]);
        require(task.currentStatus() == RemovalTask.Status.Verified, "Task not verified");
        
        address worker = task.assignedWorker();
        uint256 payout = task.payout();
        
        // Update worker stats
        workers[worker].completedTasks++;
        _updateWorkerReputation(worker, true);
        
        // Update global stats
        totalTasksCompleted++;
        totalPayoutsDistributed += payout;
        
        // Record removal in broker registry
        DataBrokerRegistry(dataBrokerRegistry).recordRemovalCompleted(task.brokerId());
        
        emit TaskCompleted(taskId, worker, payout, 0);
    }
    
    // ============ Administrative Functions ============
    
    /**
     * @dev Update platform fee rate
     */
    function updatePlatformFeeRate(uint256 newRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newRate <= 10, "Fee rate too high"); // Max 10%
        uint256 oldRate = PLATFORM_FEE_RATE;
        // Note: In a real implementation, this would need to be a mutable state variable
        emit PlatformFeeUpdated(oldRate, newRate);
    }
    
    /**
     * @dev Update minimum worker stake
     */
    function updateMinWorkerStake(uint256 newStake) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldStake = minWorkerStake;
        minWorkerStake = newStake;
        emit MinWorkerStakeUpdated(oldStake, newStake);
    }
    
    /**
     * @dev Update platform treasury address
     */
    function updatePlatformTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasury != address(0), "Invalid treasury address");
        address oldTreasury = platformTreasury;
        platformTreasury = newTreasury;
        emit PlatformTreasuryUpdated(oldTreasury, newTreasury);
    }
    
    /**
     * @dev Withdraw collected platform fees
     */
    function withdrawPlatformFees() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = platformFeesCollected;
        platformFeesCollected = 0;
        IERC20(paymentToken).safeTransfer(platformTreasury, amount);
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
     * @dev Get tasks created by user
     */
    function getUserTasks(address user) external view returns (uint256[] memory) {
        return userTasks[user];
    }
    
    /**
     * @dev Get tasks assigned to worker
     */
    function getWorkerTasks(address worker) external view returns (uint256[] memory) {
        return workerTasks[worker];
    }
    
    /**
     * @dev Get all registered workers
     */
    function getAllWorkers() external view returns (address[] memory) {
        return allWorkers;
    }
    
    /**
     * @dev Get factory statistics
     */
    function getFactoryStats() external view returns (
        uint256 totalTasks,
        uint256 completedTasks,
        uint256 totalWorkers_,
        uint256 totalPayouts,
        uint256 platformFees
    ) {
        return (
            totalTasksCreated,
            totalTasksCompleted,
            totalWorkers,
            totalPayoutsDistributed,
            platformFeesCollected
        );
    }
    
    /**
     * @dev Get available tasks (created but not assigned)
     */
    function getAvailableTasks() external view returns (uint256[] memory availableTasks) {
        uint256[] memory tempTasks = new uint256[](totalTasksCreated);
        uint256 count = 0;
        
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i] != address(0)) {
                RemovalTask task = RemovalTask(tasks[i]);
                if (task.currentStatus() == RemovalTask.Status.Created && 
                    task.assignedWorker() == address(0)) {
                    tempTasks[count] = i;
                    count++;
                }
            }
        }
        
        // Resize array to actual count
        availableTasks = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            availableTasks[i] = tempTasks[i];
        }
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Internal function to create a task
     */
    function _createTaskInternal(
        TaskParams calldata params,
        address creator
    ) internal returns (uint256 taskId, address taskContract) {
        // Validation already done in calling function
        
        taskId = nextTaskId++;
        uint256 deadline = block.timestamp + params.duration;
        
        // Get broker weight
        DataBrokerRegistry registry = DataBrokerRegistry(dataBrokerRegistry);
        (uint256 weight,) = registry.getBrokerWeightAndStatus(params.brokerId);
        
        // Create new RemovalTask contract
        RemovalTask newTask = new RemovalTask(
            taskId,
            params.brokerId,
            params.subjectCommit,
            creator,
            paymentToken,
            params.payout,
            weight,
            deadline,
            verifierRegistry
        );
        
        taskContract = address(newTask);
        tasks[taskId] = taskContract;
        userTasks[creator].push(taskId);
        
        // Transfer escrowed payout to task contract
        IERC20(paymentToken).safeTransfer(taskContract, params.payout);
        
        // Update platform fees
        uint256 platformFee = (params.payout * PLATFORM_FEE_RATE) / 100;
        platformFeesCollected += platformFee;
        
        totalTasksCreated++;
        
        emit TaskCreated(taskId, creator, params.brokerId, taskContract, params.payout);
    }
    
    /**
     * @dev Internal function to assign worker to task
     */
    function _assignWorkerToTask(uint256 taskId, address worker) internal {
        require(workers[worker].isRegistered, "Worker not registered");
        require(!workers[worker].isSlashed, "Worker is slashed");
        
        RemovalTask task = RemovalTask(tasks[taskId]);
        require(task.currentStatus() == RemovalTask.Status.Created, "Task not available for assignment");
        require(task.assignedWorker() == address(0), "Task already assigned");
        
        // Assign worker to task
        task.assignWorker(worker);
        workerTasks[worker].push(taskId);
        
        emit WorkerAssignedToTask(taskId, worker, address(task));
    }
    
    /**
     * @dev Update worker reputation based on task outcome
     */
    function _updateWorkerReputation(address worker, bool success) internal {
        Worker storage workerData = workers[worker];
        
        uint256 totalTasks = workerData.completedTasks;
        uint256 successfulTasks = success ? 
            (workerData.successRate * (totalTasks - 1)) / 100 + 1 :
            (workerData.successRate * (totalTasks - 1)) / 100;
        
        workerData.successRate = (successfulTasks * 100) / totalTasks;
        
        // Reputation is based on success rate and number of completed tasks
        workerData.reputation = workerData.successRate;
        if (totalTasks >= 10) {
            workerData.reputation = workerData.reputation * 110 / 100; // 10% bonus for experience
        }
        if (workerData.reputation > 100) {
            workerData.reputation = 100;
        }
    }
}
