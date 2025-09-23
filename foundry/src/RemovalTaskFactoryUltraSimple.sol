// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "./RemovalTaskSimple.sol"; // Commented out for now
import "./DataBrokerRegistryUltraSimple.sol";

/**
 * @title RemovalTaskFactoryUltraSimple
 * @dev Ultra-simplified factory for creating removal tasks
 * @author Pierce
 */
contract RemovalTaskFactoryUltraSimple is Ownable {
    using SafeERC20 for IERC20;
    
    // ============ Constants ============
    
    uint256 public constant MIN_PAYOUT = 10 * 10**18;  // 10 RN tokens
    
    // ============ State Variables ============
    
    address public immutable paymentToken;
    address public immutable dataBrokerRegistry;
    
    uint256 public nextTaskId = 1;
    mapping(uint256 => address) public tasks;
    mapping(address => uint256[]) public userTasks;
    
    uint256 public totalTasksCreated;
    
    // ============ Events ============
    
    event TaskCreated(
        uint256 indexed taskId,
        address indexed creator,
        uint256 indexed brokerId,
        address taskContract,
        uint256 payout
    );
    
    // ============ Constructor ============
    
    constructor(
        address _paymentToken,
        address _dataBrokerRegistry
    ) Ownable(msg.sender) {
        paymentToken = _paymentToken;
        dataBrokerRegistry = _dataBrokerRegistry;
    }
    
    // ============ Functions ============
    
    function createTask(
        uint256 brokerId,
        bytes32 subjectCommit,
        uint256 payout,
        uint256 duration
    ) external returns (uint256 taskId, address taskContract) {
        require(payout >= MIN_PAYOUT, "Payout too low");
        require(duration >= 7 days, "Duration too short");
        require(duration <= 90 days, "Duration too long");
        
        // Verify broker exists and is active
        DataBrokerRegistryUltraSimple registry = DataBrokerRegistryUltraSimple(dataBrokerRegistry);
        (uint256 weight, bool isActive) = registry.getBrokerWeightAndStatus(brokerId);
        require(isActive, "Broker not active");
        
        // Transfer payout to this contract
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), payout);
        
        taskId = nextTaskId++;
        uint256 deadline = block.timestamp + duration;
        
        // Create new task (simplified for now)
        // RemovalTaskSimple newTask = new RemovalTaskSimple(
        //     taskId,
        //     brokerId,
        //     subjectCommit,
        //     msg.sender,
        //     paymentToken,
        //     payout,
        //     weight,
        //     deadline
        // );
        
        taskContract = address(0); // Placeholder for now
        tasks[taskId] = taskContract;
        userTasks[msg.sender].push(taskId);
        
        // Transfer payout to task contract (commented out for now)
        // IERC20(paymentToken).safeTransfer(taskContract, payout);
        
        totalTasksCreated++;
        
        emit TaskCreated(taskId, msg.sender, brokerId, taskContract, payout);
    }
    
    function getUserTasks(address user) external view returns (uint256[] memory) {
        return userTasks[user];
    }
    
    function getStats() external view returns (uint256 totalTasks) {
        return totalTasksCreated;
    }
}
