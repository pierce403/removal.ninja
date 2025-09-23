// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DataBrokerRegistry
 * @dev Governance-managed registry for data broker metadata with weighted priority system
 * @notice Stores broker information with NO PII - only public business information
 * @author Pierce
 */
contract DataBrokerRegistry is AccessControl, Pausable, ReentrancyGuard {
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
        string[] tags;                  // Categorization tags
        uint256 weight;                 // Priority weight (100 = 1x, 200 = 2x, etc.)
        bool isActive;                  // Whether broker is currently active
        uint256 addedTimestamp;         // When broker was added
        address addedBy;                // Who added this broker
        uint256 totalRemovals;          // Total successful removals
        uint256 totalDisputes;          // Total disputed removals
    }
    
    /**
     * @dev Batch broker data for efficient loading
     */
    struct BatchBrokerData {
        string name;
        string website;
        string removalLink;
        string privacyPolicy;
        string contact;
        string requirements;
        string notes;
        string[] tags;
        uint256 weight;
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
    
    event BatchBrokersAdded(
        uint256 indexed startId,
        uint256 indexed endId,
        uint256 count,
        address indexed addedBy
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
        string[] calldata tags,
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
     * @dev Batch add brokers for efficient initial loading
     */
    function batchAddBrokers(
        BatchBrokerData[] calldata brokersData
    ) external onlyBrokerManager whenNotPaused returns (uint256 startId, uint256 endId) {
        require(brokersData.length > 0, "No brokers provided");
        require(brokersData.length <= 50, "Too many brokers in batch"); // Gas limit protection
        
        startId = nextBrokerId;
        
        for (uint256 i = 0; i < brokersData.length; i++) {
            BatchBrokerData calldata data = brokersData[i];
            
            require(bytes(data.name).length > 0, "Name cannot be empty");
            require(bytes(data.website).length > 0, "Website cannot be empty");
            require(nameToId[data.name] == 0, "Broker name already exists");
            require(data.weight >= STANDARD_WEIGHT, "Weight must be at least standard weight");
            
            string memory domain = _extractDomain(data.website);
            require(!registeredDomains[domain], "Domain already registered");
            
            uint256 brokerId = nextBrokerId++;
            
            brokers[brokerId] = DataBroker({
                id: brokerId,
                name: data.name,
                website: data.website,
                removalLink: data.removalLink,
                privacyPolicy: data.privacyPolicy,
                contact: data.contact,
                requirements: data.requirements,
                notes: data.notes,
                tags: data.tags,
                weight: data.weight,
                isActive: true,
                addedTimestamp: block.timestamp,
                addedBy: msg.sender,
                totalRemovals: 0,
                totalDisputes: 0
            });
            
            nameToId[data.name] = brokerId;
            registeredDomains[domain] = true;
            activeBrokerIds.push(brokerId);
            totalActiveBrokers++;
            
            if (data.weight >= HIGH_IMPACT_WEIGHT) {
                isHighImpactBroker[brokerId] = true;
                highImpactBrokerIds.push(brokerId);
            }
        }
        
        endId = nextBrokerId - 1;
        
        emit BatchBrokersAdded(startId, endId, brokersData.length, msg.sender);
    }
    
    /**
     * @dev Load the "starter set" of high-impact brokers from Intel Techniques workbook
     */
    function loadStarterSet() external onlyBrokerManager whenNotPaused {
        require(nextBrokerId == 1, "Starter set can only be loaded on empty registry");
        
        BatchBrokerData[] memory starterBrokers = new BatchBrokerData[](9);
        
        // High-impact brokers from "MOST BANG FOR YOUR BUCK" list
        starterBrokers[0] = BatchBrokerData({
            name: "Spokeo",
            website: "https://www.spokeo.com",
            removalLink: "https://www.spokeo.com/optout",
            privacyPolicy: "https://www.spokeo.com/privacy-policy",
            contact: "privacy@spokeo.com",
            requirements: "Full name, age, current address",
            notes: "High-impact removal. Process takes 72 hours. May require phone verification.",
            tags: _createStringArray3("high-impact", "people-search", "public-records"),
            weight: HIGH_IMPACT_WEIGHT
        });
        
        starterBrokers[1] = BatchBrokerData({
            name: "Radaris",
            website: "https://radaris.com",
            removalLink: "https://radaris.com/page/how-to-remove",
            privacyPolicy: "https://radaris.com/page/privacy",
            contact: "support@radaris.com",
            requirements: "Full name, current address, phone number",
            notes: "High-impact removal. May require multiple attempts. Check for reappearance.",
            tags: _createStringArray3("high-impact", "people-search", "public-records"),
            weight: HIGH_IMPACT_WEIGHT
        });
        
        starterBrokers[2] = BatchBrokerData({
            name: "Whitepages",
            website: "https://www.whitepages.com",
            removalLink: "https://www.whitepages.com/suppression-requests",
            privacyPolicy: "https://www.whitepages.com/privacy",
            contact: "privacy@whitepages.com",
            requirements: "URL of listing, phone number verification",
            notes: "High-impact removal. Must verify phone number via SMS.",
            tags: _createStringArray3("high-impact", "people-search", "phone-directory"),
            weight: HIGH_IMPACT_WEIGHT
        });
        
        starterBrokers[3] = BatchBrokerData({
            name: "Intelius",
            website: "https://www.intelius.com",
            removalLink: "https://www.intelius.com/opt-out",
            privacyPolicy: "https://www.intelius.com/privacy",
            contact: "privacy@intelius.com",
            requirements: "Full name, age, current and previous addresses",
            notes: "High-impact removal. Owns multiple subsidiary sites.",
            tags: _createStringArray3("high-impact", "people-search", "background-checks"),
            weight: HIGH_IMPACT_WEIGHT
        });
        
        starterBrokers[4] = BatchBrokerData({
            name: "BeenVerified",
            website: "https://www.beenverified.com",
            removalLink: "https://www.beenverified.com/app/optout/search",
            privacyPolicy: "https://www.beenverified.com/privacy",
            contact: "privacy@beenverified.com",
            requirements: "URL of report, email verification",
            notes: "High-impact removal. Must locate specific report URL first.",
            tags: _createStringArray3("high-impact", "people-search", "background-checks"),
            weight: HIGH_IMPACT_WEIGHT
        });
        
        starterBrokers[5] = BatchBrokerData({
            name: "Acxiom",
            website: "https://www.acxiom.com",
            removalLink: "https://isapps.acxiom.com/optout/optout.aspx",
            privacyPolicy: "https://www.acxiom.com/privacy-policy",
            contact: "privacy@acxiom.com",
            requirements: "Full name, current address, previous addresses",
            notes: "High-impact removal. Major data aggregator. Critical for privacy.",
            tags: _createStringArray3("high-impact", "data-aggregator", "marketing"),
            weight: HIGH_IMPACT_WEIGHT
        });
        
        starterBrokers[6] = BatchBrokerData({
            name: "InfoTracer",
            website: "https://www.infotracer.com",
            removalLink: "https://www.infotracer.com/optout",
            privacyPolicy: "https://www.infotracer.com/privacy",
            contact: "privacy@infotracer.com",
            requirements: "Full name, date of birth, current address",
            notes: "High-impact removal. May require ID verification.",
            tags: _createStringArray3("high-impact", "people-search", "public-records"),
            weight: HIGH_IMPACT_WEIGHT
        });
        
        starterBrokers[7] = BatchBrokerData({
            name: "LexisNexis",
            website: "https://www.lexisnexis.com",
            removalLink: "https://optout.lexisnexis.com",
            privacyPolicy: "https://www.lexisnexis.com/privacy-policy",
            contact: "privacy@lexisnexis.com",
            requirements: "Full name, SSN (last 4 digits), current address",
            notes: "High-impact removal. Major data aggregator. May require documentation.",
            tags: _createStringArray4("high-impact", "data-aggregator", "legal", "credit"),
            weight: HIGH_IMPACT_WEIGHT
        });
        
        starterBrokers[8] = BatchBrokerData({
            name: "TruePeopleSearch",
            website: "https://www.truepeoplesearch.com",
            removalLink: "https://www.truepeoplesearch.com/removal",
            privacyPolicy: "https://www.truepeoplesearch.com/privacy",
            contact: "remove@truepeoplesearch.com",
            requirements: "URL of listing, email verification",
            notes: "High-impact removal. Must locate specific listing URL.",
            tags: _createStringArray3("high-impact", "people-search", "free-service"),
            weight: HIGH_IMPACT_WEIGHT
        });
        
        // Use internal function to add brokers
        _batchAddBrokersInternal(starterBrokers);
        
        emit BatchBrokersAdded(1, 9, 9, msg.sender);
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
        string[] calldata tags,
        uint256 weight
    ) external onlyBrokerManager validBrokerId(brokerId) brokerExists(brokerId) {
        require(weight >= STANDARD_WEIGHT, "Weight must be at least standard weight");
        
        _updateBrokerFields(brokerId, website, removalLink, privacyPolicy, contact, requirements, notes, tags, weight);
        _updateHighImpactStatus(brokerId, weight);
        
        emit BrokerUpdated(brokerId, brokers[brokerId].name, msg.sender);
    }
    
    /**
     * @dev Deactivate a broker (soft delete)
     */
    function deactivateBroker(uint256 brokerId) 
        external 
        onlyBrokerManager 
        validBrokerId(brokerId) 
        brokerExists(brokerId) 
    {
        require(brokers[brokerId].isActive, "Broker already deactivated");
        
        brokers[brokerId].isActive = false;
        totalActiveBrokers--;
        _removeFromActiveBrokersList(brokerId);
        
        emit BrokerDeactivated(brokerId, brokers[brokerId].name, msg.sender);
    }
    
    /**
     * @dev Reactivate a broker
     */
    function reactivateBroker(uint256 brokerId) 
        external 
        onlyBrokerManager 
        validBrokerId(brokerId) 
        brokerExists(brokerId) 
    {
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
    function recordRemovalCompleted(uint256 brokerId) 
        external 
        validBrokerId(brokerId) 
        brokerExists(brokerId) 
    {
        // TODO: Add access control for authorized RemovalTask contracts
        brokers[brokerId].totalRemovals++;
        emit RemovalCompleted(brokerId, brokers[brokerId].totalRemovals);
    }
    
    /**
     * @dev Record a dispute (called by DisputeResolution contracts)
     */
    function recordDispute(uint256 brokerId) 
        external 
        validBrokerId(brokerId) 
        brokerExists(brokerId) 
    {
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
     * @dev Get brokers by tag
     */
    function getBrokersByTag(string calldata tag) external view returns (uint256[] memory) {
        uint256[] memory matchingBrokers = new uint256[](totalActiveBrokers);
        uint256 count = 0;
        
        for (uint256 i = 0; i < activeBrokerIds.length; i++) {
            uint256 brokerId = activeBrokerIds[i];
            if (brokers[brokerId].isActive && _hasTag(brokerId, tag)) {
                matchingBrokers[count] = brokerId;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingBrokers[i];
        }
        
        return result;
    }
    
    /**
     * @dev Get broker weight and active status (for RemovalTaskFactory)
     */
    function getBrokerWeightAndStatus(uint256 brokerId) external view validBrokerId(brokerId) brokerExists(brokerId) returns (
        uint256 weight,
        bool isActive
    ) {
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
     * @dev Internal function for batch adding brokers
     */
    function _batchAddBrokersInternal(BatchBrokerData[] memory brokersData) internal {
        for (uint256 i = 0; i < brokersData.length; i++) {
            BatchBrokerData memory data = brokersData[i];
            
            uint256 brokerId = nextBrokerId++;
            
            brokers[brokerId] = DataBroker({
                id: brokerId,
                name: data.name,
                website: data.website,
                removalLink: data.removalLink,
                privacyPolicy: data.privacyPolicy,
                contact: data.contact,
                requirements: data.requirements,
                notes: data.notes,
                tags: data.tags,
                weight: data.weight,
                isActive: true,
                addedTimestamp: block.timestamp,
                addedBy: msg.sender,
                totalRemovals: 0,
                totalDisputes: 0
            });
            
            nameToId[data.name] = brokerId;
            registeredDomains[_extractDomain(data.website)] = true;
            activeBrokerIds.push(brokerId);
            totalActiveBrokers++;
            
            if (data.weight >= HIGH_IMPACT_WEIGHT) {
                isHighImpactBroker[brokerId] = true;
                highImpactBrokerIds.push(brokerId);
            }
        }
    }
    
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
     * @dev Check if broker has specific tag
     */
    function _hasTag(uint256 brokerId, string calldata tag) internal view returns (bool) {
        string[] memory brokerTags = brokers[brokerId].tags;
        for (uint256 i = 0; i < brokerTags.length; i++) {
            if (keccak256(bytes(brokerTags[i])) == keccak256(bytes(tag))) {
                return true;
            }
        }
        return false;
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
    
    /**
     * @dev Internal function to update broker fields
     */
    function _updateBrokerFields(
        uint256 brokerId,
        string calldata website,
        string calldata removalLink,
        string calldata privacyPolicy,
        string calldata contact,
        string calldata requirements,
        string calldata notes,
        string[] calldata tags,
        uint256 weight
    ) internal {
        DataBroker storage broker = brokers[brokerId];
        broker.website = website;
        broker.removalLink = removalLink;
        broker.privacyPolicy = privacyPolicy;
        broker.contact = contact;
        broker.requirements = requirements;
        broker.notes = notes;
        broker.tags = tags;
        broker.weight = weight;
    }
    
    /**
     * @dev Internal function to update high-impact status
     */
    function _updateHighImpactStatus(uint256 brokerId, uint256 weight) internal {
        bool wasHighImpact = isHighImpactBroker[brokerId];
        bool isNowHighImpact = weight >= HIGH_IMPACT_WEIGHT;
        
        if (!wasHighImpact && isNowHighImpact) {
            isHighImpactBroker[brokerId] = true;
            highImpactBrokerIds.push(brokerId);
        } else if (wasHighImpact && !isNowHighImpact) {
            isHighImpactBroker[brokerId] = false;
            _removeFromHighImpactList(brokerId);
        }
    }
    
    /**
     * @dev Helper function to create string array with 3 elements
     */
    function _createStringArray3(
        string memory a,
        string memory b,
        string memory c
    ) internal pure returns (string[] memory result) {
        result = new string[](3);
        result[0] = a;
        result[1] = b;
        result[2] = c;
    }
    
    /**
     * @dev Helper function to create string array with 4 elements
     */
    function _createStringArray4(
        string memory a,
        string memory b,
        string memory c,
        string memory d
    ) internal pure returns (string[] memory result) {
        result = new string[](4);
        result[0] = a;
        result[1] = b;
        result[2] = c;
        result[3] = d;
    }
}
