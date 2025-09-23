// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DataBrokerRegistrySimple
 * @dev Simplified governance-managed registry for data broker metadata with weighted priority system
 * @notice Stores broker information with NO PII - only public business information
 * @author Pierce
 */
contract DataBrokerRegistrySimple is AccessControl, Pausable, ReentrancyGuard {
    // ============ Constants ============
    
    bytes32 public constant BROKER_MANAGER_ROLE = keccak256("BROKER_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    // Weight multipliers for high-impact brokers (based on Intel Techniques "MOST BANG FOR YOUR BUCK")
    uint256 public constant HIGH_IMPACT_WEIGHT = 300; // 3x multiplier
    uint256 public constant MEDIUM_IMPACT_WEIGHT = 200; // 2x multiplier  
    uint256 public constant STANDARD_WEIGHT = 100; // 1x multiplier
    
    // ============ Structs ============
    
    /**
     * @dev Data broker information - contains only public business metadata
     */
    struct DataBroker {
        uint256 id;
        string name;                    // Business name
        string website;                 // Primary website URL
        string removalLink;             // Direct link to opt-out page
        string privacyPolicy;           // Link to privacy policy
        string contact;                 // Public contact info (email/phone)
        string requirements;            // What info is needed for removal
        string notes;                   // Additional removal notes/tips
        string tags;                    // Categorization tags (simplified as single string)
        uint256 weight;                 // Priority weight (100 = 1x, 200 = 2x, etc.)
        bool isActive;                  // Whether broker is currently active
        uint256 addedTimestamp;         // When broker was added
        address addedBy;                // Who added this broker
        uint256 totalRemovals;          // Total successful removals
        uint256 totalDisputes;          // Total disputed removals
    }
    
    // ============ State Variables ============
    
    mapping(uint256 => DataBroker) public brokers;
    mapping(string => uint256) public nameToId; // name -> broker ID for lookups
    mapping(string => bool) public registeredDomains; // domain -> exists (prevent duplicates)
    
    uint256 public nextBrokerId = 1;
    uint256[] public activeBrokerIds;
    uint256 public totalActiveBrokers;
    
    // High-impact broker tracking
    mapping(uint256 => bool) public isHighImpactBroker;
    uint256[] public highImpactBrokerIds;
    
    // ============ Events ============
    
    event BrokerAdded(
        uint256 indexed brokerId,
        string indexed name,
        address indexed addedBy,
        uint256 weight
    );
    
    event BrokerUpdated(
        uint256 indexed brokerId,
        string indexed name,
        address indexed updatedBy
    );
    
    event BrokerDeactivated(
        uint256 indexed brokerId,
        string indexed name,
        address indexed deactivatedBy
    );
    
    event BrokerReactivated(
        uint256 indexed brokerId,
        string indexed name,
        address indexed reactivatedBy
    );
    
    event RemovalCompleted(
        uint256 indexed brokerId,
        uint256 totalRemovals
    );
    
    event DisputeRecorded(
        uint256 indexed brokerId,
        uint256 totalDisputes
    );
    
    // ============ Modifiers ============
    
    modifier validBrokerId(uint256 brokerId) {
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        _;
    }
    
    modifier brokerExists(uint256 brokerId) {
        require(brokers[brokerId].id != 0, "Broker does not exist");
        _;
    }
    
    modifier onlyBrokerManager() {
        require(hasRole(BROKER_MANAGER_ROLE, msg.sender), "Caller is not a broker manager");
        _;
    }
    
    // ============ Constructor ============
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BROKER_MANAGER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }
    
    // ============ Broker Management Functions ============
    
    /**
     * @dev Add a single data broker to the registry
     */
    function addBroker(
        string calldata name,
        string calldata website,
        string calldata removalLink,
        string calldata privacyPolicy,
        string calldata contact,
        string calldata requirements,
        string calldata notes,
        string calldata tags,
        uint256 weight
    ) external onlyBrokerManager whenNotPaused returns (uint256 brokerId) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(website).length > 0, "Website cannot be empty");
        require(nameToId[name] == 0, "Broker name already exists");
        require(weight >= STANDARD_WEIGHT, "Weight must be at least standard weight");
        
        // Extract domain from website for duplicate checking
        string memory domain = _extractDomain(website);
        require(!registeredDomains[domain], "Domain already registered");
        
        brokerId = nextBrokerId++;
        
        brokers[brokerId] = DataBroker({
            id: brokerId,
            name: name,
            website: website,
            removalLink: removalLink,
            privacyPolicy: privacyPolicy,
            contact: contact,
            requirements: requirements,
            notes: notes,
            tags: tags,
            weight: weight,
            isActive: true,
            addedTimestamp: block.timestamp,
            addedBy: msg.sender,
            totalRemovals: 0,
            totalDisputes: 0
        });
        
        nameToId[name] = brokerId;
        registeredDomains[domain] = true;
        activeBrokerIds.push(brokerId);
        totalActiveBrokers++;
        
        // Track high-impact brokers
        if (weight >= HIGH_IMPACT_WEIGHT) {
            isHighImpactBroker[brokerId] = true;
            highImpactBrokerIds.push(brokerId);
        }
        
        emit BrokerAdded(brokerId, name, msg.sender, weight);
    }
    
    /**
     * @dev Update broker information
     */
    function updateBroker(
        uint256 brokerId,
        string calldata website,
        string calldata removalLink,
        string calldata privacyPolicy,
        string calldata contact,
        string calldata requirements,
        string calldata notes,
        string calldata tags,
        uint256 weight
    ) external {
        require(hasRole(BROKER_MANAGER_ROLE, msg.sender), "Caller is not a broker manager");
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        require(brokers[brokerId].id != 0, "Broker does not exist");
        require(weight >= STANDARD_WEIGHT, "Weight must be at least standard weight");
        
        DataBroker storage broker = brokers[brokerId];
        broker.website = website;
        broker.removalLink = removalLink;
        broker.privacyPolicy = privacyPolicy;
        broker.contact = contact;
        broker.requirements = requirements;
        broker.notes = notes;
        broker.tags = tags;
        broker.weight = weight;
        
        // Update high-impact status
        bool wasHighImpact = isHighImpactBroker[brokerId];
        bool isNowHighImpact = weight >= HIGH_IMPACT_WEIGHT;
        
        if (!wasHighImpact && isNowHighImpact) {
            isHighImpactBroker[brokerId] = true;
            highImpactBrokerIds.push(brokerId);
        } else if (wasHighImpact && !isNowHighImpact) {
            isHighImpactBroker[brokerId] = false;
            _removeFromHighImpactList(brokerId);
        }
        
        emit BrokerUpdated(brokerId, broker.name, msg.sender);
    }
    
    /**
     * @dev Deactivate a broker (soft delete)
     */
    function deactivateBroker(uint256 brokerId) external {
        require(hasRole(BROKER_MANAGER_ROLE, msg.sender), "Caller is not a broker manager");
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        require(brokers[brokerId].id != 0, "Broker does not exist");
        require(brokers[brokerId].isActive, "Broker already deactivated");
        
        brokers[brokerId].isActive = false;
        totalActiveBrokers--;
        _removeFromActiveBrokersList(brokerId);
        
        emit BrokerDeactivated(brokerId, brokers[brokerId].name, msg.sender);
    }
    
    /**
     * @dev Reactivate a broker
     */
    function reactivateBroker(uint256 brokerId) external {
        require(hasRole(BROKER_MANAGER_ROLE, msg.sender), "Caller is not a broker manager");
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        require(brokers[brokerId].id != 0, "Broker does not exist");
        require(!brokers[brokerId].isActive, "Broker already active");
        
        brokers[brokerId].isActive = true;
        totalActiveBrokers++;
        activeBrokerIds.push(brokerId);
        
        emit BrokerReactivated(brokerId, brokers[brokerId].name, msg.sender);
    }
    
    // ============ Statistics Functions ============
    
    /**
     * @dev Record a successful removal (called by RemovalTask contracts)
     */
    function recordRemovalCompleted(uint256 brokerId) external {
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        require(brokers[brokerId].id != 0, "Broker does not exist");
        // TODO: Add access control for authorized RemovalTask contracts
        brokers[brokerId].totalRemovals++;
        emit RemovalCompleted(brokerId, brokers[brokerId].totalRemovals);
    }
    
    /**
     * @dev Record a dispute (called by DisputeResolution contracts)
     */
    function recordDispute(uint256 brokerId) external {
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        require(brokers[brokerId].id != 0, "Broker does not exist");
        // TODO: Add access control for authorized DisputeResolution contracts
        brokers[brokerId].totalDisputes++;
        emit DisputeRecorded(brokerId, brokers[brokerId].totalDisputes);
    }
    
    // ============ View Functions ============
    
    /**
     * @dev Get all active brokers
     */
    function getActiveBrokers() external view returns (DataBroker[] memory) {
        DataBroker[] memory activeBrokers = new DataBroker[](totalActiveBrokers);
        uint256 index = 0;
        
        for (uint256 i = 0; i < activeBrokerIds.length; i++) {
            uint256 brokerId = activeBrokerIds[i];
            if (brokers[brokerId].isActive) {
                activeBrokers[index] = brokers[brokerId];
                index++;
            }
        }
        
        return activeBrokers;
    }
    
    /**
     * @dev Get high-impact brokers
     */
    function getHighImpactBrokers() external view returns (DataBroker[] memory) {
        DataBroker[] memory highImpactBrokers = new DataBroker[](highImpactBrokerIds.length);
        
        for (uint256 i = 0; i < highImpactBrokerIds.length; i++) {
            uint256 brokerId = highImpactBrokerIds[i];
            if (brokers[brokerId].isActive && isHighImpactBroker[brokerId]) {
                highImpactBrokers[i] = brokers[brokerId];
            }
        }
        
        return highImpactBrokers;
    }
    
    /**
     * @dev Get broker weight and active status (for RemovalTaskFactory)
     */
    function getBrokerWeightAndStatus(uint256 brokerId) external view returns (
        uint256 weight,
        bool isActive
    ) {
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        require(brokers[brokerId].id != 0, "Broker does not exist");
        DataBroker storage broker = brokers[brokerId];
        return (broker.weight, broker.isActive);
    }
    
    /**
     * @dev Get broker statistics
     */
    function getRegistryStats() external view returns (
        uint256 totalBrokers,
        uint256 activeBrokers,
        uint256 highImpactBrokers,
        uint256 totalRemovalsCompleted,
        uint256 totalDisputes
    ) {
        totalBrokers = nextBrokerId - 1;
        activeBrokers = totalActiveBrokers;
        highImpactBrokers = highImpactBrokerIds.length;
        
        for (uint256 i = 1; i < nextBrokerId; i++) {
            totalRemovalsCompleted += brokers[i].totalRemovals;
            totalDisputes += brokers[i].totalDisputes;
        }
    }
    
    // ============ Admin Functions ============
    
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
    
    // ============ Internal Functions ============
    
    /**
     * @dev Extract domain from URL for duplicate checking
     */
    function _extractDomain(string memory url) internal pure returns (string memory) {
        bytes memory urlBytes = bytes(url);
        uint256 start = 0;
        uint256 end = urlBytes.length;
        
        // Find start after protocol (http:// or https://)
        for (uint256 i = 0; i < urlBytes.length - 2; i++) {
            if (urlBytes[i] == '/' && urlBytes[i + 1] == '/') {
                start = i + 2;
                break;
            }
        }
        
        // Find end at first slash after domain
        for (uint256 i = start; i < urlBytes.length; i++) {
            if (urlBytes[i] == '/') {
                end = i;
                break;
            }
        }
        
        // Extract domain substring
        bytes memory domain = new bytes(end - start);
        for (uint256 i = 0; i < end - start; i++) {
            domain[i] = urlBytes[start + i];
        }
        
        return string(domain);
    }
    
    /**
     * @dev Remove broker from active brokers list
     */
    function _removeFromActiveBrokersList(uint256 brokerId) internal {
        for (uint256 i = 0; i < activeBrokerIds.length; i++) {
            if (activeBrokerIds[i] == brokerId) {
                activeBrokerIds[i] = activeBrokerIds[activeBrokerIds.length - 1];
                activeBrokerIds.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Remove broker from high-impact list
     */
    function _removeFromHighImpactList(uint256 brokerId) internal {
        for (uint256 i = 0; i < highImpactBrokerIds.length; i++) {
            if (highImpactBrokerIds[i] == brokerId) {
                highImpactBrokerIds[i] = highImpactBrokerIds[highImpactBrokerIds.length - 1];
                highImpactBrokerIds.pop();
                break;
            }
        }
    }
}
