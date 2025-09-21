// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title RemovalNinja
 * @dev Decentralized data broker removal protocol with token incentives
 * @author Pierce
 */
contract RemovalNinja is ERC20, Ownable, ReentrancyGuard, Pausable {
    // ============ Constants ============
    
    uint256 public constant BROKER_SUBMISSION_REWARD = 100 * 10**18; // 100 RN tokens
    uint256 public constant REMOVAL_PROCESSING_REWARD = 50 * 10**18; // 50 RN tokens
    uint256 public constant MIN_USER_STAKE = 10 * 10**18; // 10 RN tokens
    uint256 public constant MIN_PROCESSOR_STAKE = 1000 * 10**18; // 1,000 RN tokens
    uint256 public constant SLASH_PERCENTAGE = 10; // 10% slashing for poor performance
    uint256 public constant MAX_SELECTED_PROCESSORS = 5; // Max processors a user can select
    
    // ============ Structs ============
    
    struct DataBroker {
        uint256 id;
        string name;
        string website;
        string removalInstructions;
        address submitter;
        bool isVerified;
        uint256 submissionTime;
        uint256 totalRemovals;
    }
    
    struct Processor {
        address addr;
        bool isProcessor;
        uint256 stake;
        string description;
        uint256 completedRemovals;
        uint256 reputation; // Score out of 100
        uint256 registrationTime;
        bool isSlashed;
    }
    
    struct User {
        bool isStakingForRemoval;
        uint256 stakeAmount;
        uint256 stakeTime;
        address[] selectedProcessors;
    }
    
    struct RemovalRequest {
        uint256 id;
        address user;
        uint256 brokerId;
        address processor;
        bool isCompleted;
        bool isVerified;
        uint256 requestTime;
        uint256 completionTime;
        string zkProof; // Future: zkEmail proof hash
    }
    
    // ============ State Variables ============
    
    mapping(uint256 => DataBroker) public dataBrokers;
    mapping(address => Processor) public processors;
    mapping(address => User) public users;
    mapping(uint256 => RemovalRequest) public removalRequests;
    mapping(address => uint256) public userStakeAmount;
    mapping(address => address[]) public userSelectedProcessors;
    
    uint256 public nextBrokerId = 1;
    uint256 public nextRemovalId = 1;
    address[] public allProcessors;
    uint256[] public allBrokerIds;
    
    // ============ Events ============
    
    event DataBrokerSubmitted(
        uint256 indexed brokerId,
        string name,
        address indexed submitter
    );
    
    event ProcessorRegistered(
        address indexed processor,
        uint256 stake,
        string description
    );
    
    event UserStakedForRemoval(
        address indexed user,
        uint256 amount,
        address[] selectedProcessors
    );
    
    event RemovalRequested(
        uint256 indexed removalId,
        address indexed user,
        uint256 indexed brokerId,
        address processor
    );
    
    event RemovalCompleted(
        uint256 indexed removalId,
        address indexed processor,
        string zkProof
    );
    
    event ProcessorSlashed(
        address indexed processor,
        uint256 slashedAmount,
        string reason
    );
    
    event BrokerVerified(
        uint256 indexed brokerId,
        address indexed verifier
    );
    
    // ============ Modifiers ============
    
    modifier onlyProcessor() {
        require(processors[msg.sender].isProcessor, "Not a registered processor");
        require(!processors[msg.sender].isSlashed, "Processor is slashed");
        _;
    }
    
    modifier onlyActiveUser() {
        require(users[msg.sender].isStakingForRemoval, "User not staking for removal");
        _;
    }
    
    modifier validBrokerId(uint256 brokerId) {
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        _;
    }
    
    modifier validRemovalId(uint256 removalId) {
        require(removalId > 0 && removalId < nextRemovalId, "Invalid removal ID");
        _;
    }
    
    // ============ Constructor ============
    
    constructor() ERC20("RemovalNinja", "RN") Ownable(msg.sender) {
        // Mint initial supply to owner for distribution
        _mint(msg.sender, 1000000 * 10**18); // 1M RN tokens
    }
    
    // ============ Data Broker Functions ============
    
    /**
     * @dev Submit a new data broker to the registry
     * @param name The name of the data broker
     * @param website The website URL of the data broker
     * @param removalInstructions Instructions for data removal
     */
    function submitDataBroker(
        string calldata name,
        string calldata website,
        string calldata removalInstructions
    ) external whenNotPaused {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(website).length > 0, "Website cannot be empty");
        
        uint256 brokerId = nextBrokerId++;
        
        dataBrokers[brokerId] = DataBroker({
            id: brokerId,
            name: name,
            website: website,
            removalInstructions: removalInstructions,
            submitter: msg.sender,
            isVerified: false,
            submissionTime: block.timestamp,
            totalRemovals: 0
        });
        
        allBrokerIds.push(brokerId);
        
        // Reward the submitter
        _mint(msg.sender, BROKER_SUBMISSION_REWARD);
        
        emit DataBrokerSubmitted(brokerId, name, msg.sender);
    }
    
    /**
     * @dev Verify a data broker (owner only)
     * @param brokerId The ID of the broker to verify
     */
    function verifyDataBroker(uint256 brokerId) external onlyOwner validBrokerId(brokerId) {
        dataBrokers[brokerId].isVerified = true;
        emit BrokerVerified(brokerId, msg.sender);
    }
    
    /**
     * @dev Get all data brokers
     */
    function getAllDataBrokers() external view returns (DataBroker[] memory) {
        DataBroker[] memory brokers = new DataBroker[](allBrokerIds.length);
        for (uint256 i = 0; i < allBrokerIds.length; i++) {
            brokers[i] = dataBrokers[allBrokerIds[i]];
        }
        return brokers;
    }
    
    // ============ Processor Functions ============
    
    /**
     * @dev Register as a removal processor
     * @param stakeAmount Amount of RN tokens to stake
     * @param description Description of processor services
     */
    function registerProcessor(
        uint256 stakeAmount,
        string calldata description
    ) external whenNotPaused {
        require(!processors[msg.sender].isProcessor, "Already registered as processor");
        require(stakeAmount >= MIN_PROCESSOR_STAKE, "Insufficient stake amount");
        require(balanceOf(msg.sender) >= stakeAmount, "Insufficient balance");
        
        // Transfer stake to contract
        _transfer(msg.sender, address(this), stakeAmount);
        
        processors[msg.sender] = Processor({
            addr: msg.sender,
            isProcessor: true,
            stake: stakeAmount,
            description: description,
            completedRemovals: 0,
            reputation: 100, // Start with perfect reputation
            registrationTime: block.timestamp,
            isSlashed: false
        });
        
        allProcessors.push(msg.sender);
        
        emit ProcessorRegistered(msg.sender, stakeAmount, description);
    }
    
    /**
     * @dev Get all registered processors
     */
    function getAllProcessors() external view returns (Processor[] memory) {
        Processor[] memory processorList = new Processor[](allProcessors.length);
        for (uint256 i = 0; i < allProcessors.length; i++) {
            processorList[i] = processors[allProcessors[i]];
        }
        return processorList;
    }
    
    /**
     * @dev Slash a processor for poor performance (owner only)
     * @param processorAddr Address of the processor to slash
     * @param reason Reason for slashing
     */
    function slashProcessor(
        address processorAddr,
        string calldata reason
    ) external onlyOwner {
        require(processors[processorAddr].isProcessor, "Not a processor");
        require(!processors[processorAddr].isSlashed, "Already slashed");
        
        uint256 slashAmount = (processors[processorAddr].stake * SLASH_PERCENTAGE) / 100;
        processors[processorAddr].stake -= slashAmount;
        processors[processorAddr].isSlashed = true;
        processors[processorAddr].reputation = 0;
        
        // Burn the slashed tokens
        _burn(address(this), slashAmount);
        
        emit ProcessorSlashed(processorAddr, slashAmount, reason);
    }
    
    // ============ User Functions ============
    
    /**
     * @dev Stake tokens for removal services and select processors
     * @param stakeAmount Amount of RN tokens to stake
     * @param selectedProcessors Array of processor addresses to trust
     */
    function stakeForRemoval(
        uint256 stakeAmount,
        address[] calldata selectedProcessors
    ) external whenNotPaused {
        require(!users[msg.sender].isStakingForRemoval, "Already staking for removal");
        require(stakeAmount >= MIN_USER_STAKE, "Insufficient stake amount");
        require(selectedProcessors.length > 0, "Must select at least one processor");
        require(selectedProcessors.length <= MAX_SELECTED_PROCESSORS, "Too many processors selected");
        require(balanceOf(msg.sender) >= stakeAmount, "Insufficient balance");
        
        // Validate all selected processors
        for (uint256 i = 0; i < selectedProcessors.length; i++) {
            require(processors[selectedProcessors[i]].isProcessor, "Invalid processor");
            require(!processors[selectedProcessors[i]].isSlashed, "Processor is slashed");
        }
        
        // Transfer stake to contract
        _transfer(msg.sender, address(this), stakeAmount);
        
        users[msg.sender] = User({
            isStakingForRemoval: true,
            stakeAmount: stakeAmount,
            stakeTime: block.timestamp,
            selectedProcessors: selectedProcessors
        });
        
        userStakeAmount[msg.sender] = stakeAmount;
        userSelectedProcessors[msg.sender] = selectedProcessors;
        
        emit UserStakedForRemoval(msg.sender, stakeAmount, selectedProcessors);
    }
    
    /**
     * @dev Request removal from a specific data broker
     * @param brokerId The ID of the broker to request removal from
     */
    function requestRemoval(uint256 brokerId) external onlyActiveUser validBrokerId(brokerId) {
        address[] memory selectedProcessors = users[msg.sender].selectedProcessors;
        require(selectedProcessors.length > 0, "No processors selected");
        
        // Simple processor selection (first available)
        // In production, this could be more sophisticated
        address selectedProcessor = selectedProcessors[0];
        require(processors[selectedProcessor].isProcessor, "Selected processor not available");
        require(!processors[selectedProcessor].isSlashed, "Selected processor is slashed");
        
        uint256 removalId = nextRemovalId++;
        
        removalRequests[removalId] = RemovalRequest({
            id: removalId,
            user: msg.sender,
            brokerId: brokerId,
            processor: selectedProcessor,
            isCompleted: false,
            isVerified: false,
            requestTime: block.timestamp,
            completionTime: 0,
            zkProof: ""
        });
        
        emit RemovalRequested(removalId, msg.sender, brokerId, selectedProcessor);
    }
    
    /**
     * @dev Complete a removal request (processor only)
     * @param removalId The ID of the removal request
     * @param zkProof The zkEmail proof hash (future implementation)
     */
    function completeRemoval(
        uint256 removalId,
        string calldata zkProof
    ) external onlyProcessor validRemovalId(removalId) {
        RemovalRequest storage request = removalRequests[removalId];
        require(request.processor == msg.sender, "Not assigned processor");
        require(!request.isCompleted, "Already completed");
        
        request.isCompleted = true;
        request.completionTime = block.timestamp;
        request.zkProof = zkProof;
        
        // Update processor stats
        processors[msg.sender].completedRemovals++;
        
        // Update broker stats
        dataBrokers[request.brokerId].totalRemovals++;
        
        // Reward the processor
        _mint(msg.sender, REMOVAL_PROCESSING_REWARD);
        
        emit RemovalCompleted(removalId, msg.sender, zkProof);
    }
    
    /**
     * @dev Get user's selected processors
     * @param user Address of the user
     */
    function getUserSelectedProcessors(address user) external view returns (address[] memory) {
        return userSelectedProcessors[user];
    }
    
    // ============ Admin Functions ============
    
    /**
     * @dev Pause the contract (emergency only)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Emergency withdrawal function (owner only)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        if (balance > 0) {
            _transfer(address(this), owner(), balance);
        }
    }
    
    // ============ View Functions ============
    
    /**
     * @dev Get contract statistics
     */
    function getStats() external view returns (
        uint256 totalBrokers,
        uint256 totalProcessors,
        uint256 totalRemovals,
        uint256 contractBalance
    ) {
        totalBrokers = allBrokerIds.length;
        totalProcessors = allProcessors.length;
        totalRemovals = nextRemovalId - 1;
        contractBalance = balanceOf(address(this));
    }
    
    /**
     * @dev Check if an address is a registered processor
     * @param addr Address to check
     */
    function isProcessor(address addr) external view returns (bool) {
        return processors[addr].isProcessor && !processors[addr].isSlashed;
    }
    
    /**
     * @dev Get processor reputation
     * @param processorAddr Address of the processor
     */
    function getProcessorReputation(address processorAddr) external view returns (uint256) {
        require(processors[processorAddr].isProcessor, "Not a processor");
        return processors[processorAddr].reputation;
    }
}
