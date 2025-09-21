// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RemovalNinja is ERC20, Ownable, ReentrancyGuard, Pausable {
    // Token economics
    uint256 public constant BROKER_SUBMISSION_REWARD = 100 * 10**18; // 100 tokens
    uint256 public constant REMOVAL_PROCESSING_REWARD = 50 * 10**18; // 50 tokens
    uint256 public constant MIN_PROCESSOR_STAKE = 1000 * 10**18; // 1000 tokens
    uint256 public constant MIN_USER_STAKE = 10 * 10**18; // 10 tokens
    
    // Structs
    struct DataBroker {
        uint256 id;
        string name;
        string website;
        string removalInstructions;
        address submitter;
        bool verified;
        uint256 timestamp;
    }
    
    struct RemovalRequest {
        uint256 id;
        uint256 brokerId;
        address user;
        address processor;
        bool completed;
        bool paid;
        uint256 timestamp;
    }
    
    struct Processor {
        address addr;
        uint256 stakedAmount;
        bool active;
        uint256 completedRequests;
        uint256 slashedAmount;
        string description;
    }
    
    struct User {
        address addr;
        uint256 stakedAmount;
        bool onRemovalList;
        address[] selectedProcessors;
    }
    
    // State variables
    mapping(uint256 => DataBroker) public dataBrokers;
    mapping(uint256 => RemovalRequest) public removalRequests;
    mapping(address => Processor) public processors;
    mapping(address => User) public users;
    mapping(address => bool) public isProcessor;
    
    uint256 public nextBrokerId = 1;
    uint256 public nextRequestId = 1;
    uint256[] public activeBrokerIds;
    
    // Events
    event BrokerSubmitted(uint256 indexed brokerId, address indexed submitter, string name);
    event BrokerVerified(uint256 indexed brokerId, address indexed verifier);
    event RemovalRequested(uint256 indexed requestId, uint256 indexed brokerId, address indexed user);
    event RemovalCompleted(uint256 indexed requestId, address indexed processor);
    event ProcessorRegistered(address indexed processor, uint256 stakedAmount);
    event ProcessorSlashed(address indexed processor, uint256 amount, string reason);
    event UserStaked(address indexed user, uint256 amount);
    event UserAddedToRemovalList(address indexed user);
    
    constructor() ERC20("RemovalNinja", "RN") {
        _mint(msg.sender, 1000000 * 10**18); // Initial supply of 1M tokens
    }
    
    // Data Broker Management
    function submitDataBroker(
        string memory name,
        string memory website,
        string memory removalInstructions
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
            verified: false,
            timestamp: block.timestamp
        });
        
        activeBrokerIds.push(brokerId);
        
        // Reward the submitter
        _mint(msg.sender, BROKER_SUBMISSION_REWARD);
        
        emit BrokerSubmitted(brokerId, msg.sender, name);
    }
    
    function verifyDataBroker(uint256 brokerId) external onlyOwner {
        require(dataBrokers[brokerId].id != 0, "Broker does not exist");
        require(!dataBrokers[brokerId].verified, "Broker already verified");
        
        dataBrokers[brokerId].verified = true;
        emit BrokerVerified(brokerId, msg.sender);
    }
    
    // Processor Management
    function registerAsProcessor(uint256 stakeAmount, string memory description) external whenNotPaused {
        require(stakeAmount >= MIN_PROCESSOR_STAKE, "Insufficient stake amount");
        require(!isProcessor[msg.sender], "Already registered as processor");
        require(balanceOf(msg.sender) >= stakeAmount, "Insufficient token balance");
        
        _transfer(msg.sender, address(this), stakeAmount);
        
        processors[msg.sender] = Processor({
            addr: msg.sender,
            stakedAmount: stakeAmount,
            active: true,
            completedRequests: 0,
            slashedAmount: 0,
            description: description
        });
        
        isProcessor[msg.sender] = true;
        
        emit ProcessorRegistered(msg.sender, stakeAmount);
    }
    
    function slashProcessor(address processor, uint256 amount, string memory reason) external onlyOwner {
        require(isProcessor[processor], "Not a registered processor");
        require(processors[processor].stakedAmount >= amount, "Insufficient stake to slash");
        
        processors[processor].stakedAmount -= amount;
        processors[processor].slashedAmount += amount;
        
        if (processors[processor].stakedAmount < MIN_PROCESSOR_STAKE) {
            processors[processor].active = false;
        }
        
        // Burned tokens go to treasury (this contract)
        emit ProcessorSlashed(processor, amount, reason);
    }
    
    // User Management
    function stakeForRemovalList(uint256 stakeAmount, address[] memory selectedProcessors) external whenNotPaused {
        require(stakeAmount >= MIN_USER_STAKE, "Insufficient stake amount");
        require(balanceOf(msg.sender) >= stakeAmount, "Insufficient token balance");
        require(selectedProcessors.length > 0, "Must select at least one processor");
        
        // Validate all selected processors are active
        for (uint i = 0; i < selectedProcessors.length; i++) {
            require(isProcessor[selectedProcessors[i]], "Invalid processor selected");
            require(processors[selectedProcessors[i]].active, "Processor not active");
        }
        
        _transfer(msg.sender, address(this), stakeAmount);
        
        users[msg.sender] = User({
            addr: msg.sender,
            stakedAmount: stakeAmount,
            onRemovalList: true,
            selectedProcessors: selectedProcessors
        });
        
        emit UserStaked(msg.sender, stakeAmount);
        emit UserAddedToRemovalList(msg.sender);
    }
    
    // Removal Request Management
    function requestRemoval(uint256 brokerId) external whenNotPaused {
        require(dataBrokers[brokerId].verified, "Broker not verified");
        require(users[msg.sender].onRemovalList, "User not on removal list");
        
        uint256 requestId = nextRequestId++;
        
        removalRequests[requestId] = RemovalRequest({
            id: requestId,
            brokerId: brokerId,
            user: msg.sender,
            processor: address(0),
            completed: false,
            paid: false,
            timestamp: block.timestamp
        });
        
        emit RemovalRequested(requestId, brokerId, msg.sender);
    }
    
    function processRemoval(uint256 requestId) external whenNotPaused {
        require(isProcessor[msg.sender], "Not a registered processor");
        require(processors[msg.sender].active, "Processor not active");
        require(removalRequests[requestId].id != 0, "Request does not exist");
        require(!removalRequests[requestId].completed, "Request already completed");
        
        RemovalRequest storage request = removalRequests[requestId];
        User storage user = users[request.user];
        
        // Check if processor is selected by the user
        bool processorSelected = false;
        for (uint i = 0; i < user.selectedProcessors.length; i++) {
            if (user.selectedProcessors[i] == msg.sender) {
                processorSelected = true;
                break;
            }
        }
        require(processorSelected, "Processor not selected by user");
        
        request.processor = msg.sender;
        request.completed = true;
        request.paid = true;
        
        processors[msg.sender].completedRequests++;
        
        // Reward the processor
        _mint(msg.sender, REMOVAL_PROCESSING_REWARD);
        
        emit RemovalCompleted(requestId, msg.sender);
    }
    
    // View functions
    function getActiveBrokers() external view returns (uint256[] memory) {
        return activeBrokerIds;
    }
    
    function getUserSelectedProcessors(address user) external view returns (address[] memory) {
        return users[user].selectedProcessors;
    }
    
    function isUserOnRemovalList(address user) external view returns (bool) {
        return users[user].onRemovalList;
    }
    
    // Admin functions
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function withdrawSlashedTokens(uint256 amount) external onlyOwner {
        _transfer(address(this), owner(), amount);
    }
}