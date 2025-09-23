// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DataBrokerRegistryUltraSimple
 * @dev Ultra-simplified data broker registry for testing
 * @author Pierce
 */
contract DataBrokerRegistryUltraSimple is Ownable {
    // ============ Structs ============
    
    struct DataBroker {
        uint256 id;
        string name;
        string website;
        string removalLink;
        string contact;
        uint256 weight;
        bool isActive;
        uint256 totalRemovals;
        uint256 totalDisputes;
    }
    
    // ============ State Variables ============
    
    mapping(uint256 => DataBroker) public brokers;
    uint256 public nextBrokerId = 1;
    uint256 public totalActiveBrokers;
    
    // Weight constants
    uint256 public constant HIGH_IMPACT_WEIGHT = 300;
    uint256 public constant STANDARD_WEIGHT = 100;
    
    // ============ Events ============
    
    event BrokerAdded(uint256 indexed brokerId, string name, uint256 weight);
    event RemovalCompleted(uint256 indexed brokerId, uint256 totalRemovals);
    event DisputeRecorded(uint256 indexed brokerId, uint256 totalDisputes);
    
    // ============ Constructor ============
    
    constructor() Ownable(msg.sender) {}
    
    // ============ Functions ============
    
    function addBroker(
        string calldata name,
        string calldata website,
        string calldata removalLink,
        string calldata contact,
        uint256 weight
    ) external onlyOwner returns (uint256 brokerId) {
        brokerId = nextBrokerId++;
        
        brokers[brokerId] = DataBroker({
            id: brokerId,
            name: name,
            website: website,
            removalLink: removalLink,
            contact: contact,
            weight: weight,
            isActive: true,
            totalRemovals: 0,
            totalDisputes: 0
        });
        
        totalActiveBrokers++;
        emit BrokerAdded(brokerId, name, weight);
    }
    
    function getBrokerWeightAndStatus(uint256 brokerId) external view returns (
        uint256 weight,
        bool isActive
    ) {
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        DataBroker storage broker = brokers[brokerId];
        return (broker.weight, broker.isActive);
    }
    
    function recordRemovalCompleted(uint256 brokerId) external {
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        brokers[brokerId].totalRemovals++;
        emit RemovalCompleted(brokerId, brokers[brokerId].totalRemovals);
    }
    
    function recordDispute(uint256 brokerId) external {
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        brokers[brokerId].totalDisputes++;
        emit DisputeRecorded(brokerId, brokers[brokerId].totalDisputes);
    }
    
    function deactivateBroker(uint256 brokerId) external onlyOwner {
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        require(brokers[brokerId].isActive, "Already deactivated");
        brokers[brokerId].isActive = false;
        totalActiveBrokers--;
    }
    
    function getStats() external view returns (
        uint256 totalBrokers,
        uint256 activeBrokers
    ) {
        return (nextBrokerId - 1, totalActiveBrokers);
    }
}
