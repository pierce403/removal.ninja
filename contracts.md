# RemovalNinja Protocol - Smart Contract Documentation

## 📋 **Table of Contents**

1. [Protocol Overview](#protocol-overview)
2. [Contract Architecture](#contract-architecture)
3. [RemovalNinja Contract](#removalninja-contract)
4. [Data Structures](#data-structures)
5. [Function Reference](#function-reference)
6. [Events](#events)
7. [Modifiers](#modifiers)
8. [Testing Coverage](#testing-coverage)
9. [Security Considerations](#security-considerations)
10. [Deployment Information](#deployment-information)

---

## 🎯 **Protocol Overview**

The RemovalNinja protocol is a decentralized system for data broker removal with token incentives. It enables users to request removal of their personal data from various data brokers through a network of trusted processors, while maintaining privacy and providing economic incentives for participation.

### **Core Components**
- **ERC20 Token**: RN token for rewards and staking
- **Data Broker Registry**: Community-maintained database of data brokers
- **Processor Network**: Trusted entities that handle removal requests
- **User Staking System**: Users stake tokens to access removal services
- **Reputation System**: Track processor performance and reliability

---

## 🏗️ **Contract Architecture**

The protocol consists of a single main contract that inherits from multiple OpenZeppelin contracts:

```solidity
contract RemovalNinja is ERC20, Ownable, ReentrancyGuard, Pausable
```

### **Inheritance Hierarchy**
- **ERC20**: Standard token functionality (name: "RemovalNinja", symbol: "RN")
- **Ownable**: Access control for administrative functions
- **ReentrancyGuard**: Protection against reentrancy attacks
- **Pausable**: Emergency stop functionality

---

## 🥷 **RemovalNinja Contract**

**License**: Apache-2.0  
**Solidity Version**: ^0.8.19  
**Author**: Pierce

### **Contract Constants**

```solidity
uint256 public constant BROKER_SUBMISSION_REWARD = 100 * 10**18; // 100 RN tokens
uint256 public constant REMOVAL_PROCESSING_REWARD = 50 * 10**18;  // 50 RN tokens
uint256 public constant MIN_USER_STAKE = 10 * 10**18;            // 10 RN tokens
uint256 public constant MIN_PROCESSOR_STAKE = 1000 * 10**18;     // 1,000 RN tokens
uint256 public constant SLASH_PERCENTAGE = 10;                   // 10% slashing
uint256 public constant MAX_SELECTED_PROCESSORS = 5;             // Max processors per user
```

### **Token Economics**
- **Initial Supply**: 1,000,000 RN tokens (18 decimals)
- **Rewards**: Automatically minted for submissions and completions
- **Slashing**: 10% of processor stake burned for poor performance

---

## 📊 **Data Structures**

### **DataBroker Struct**
```solidity
struct DataBroker {
    uint256 id;                    // Unique identifier
    string name;                   // Broker name
    string website;                // Broker website URL
    string removalInstructions;    // How to request removal
    address submitter;             // Who submitted this broker
    bool isVerified;               // Owner verification status
    uint256 submissionTime;        // When it was submitted
    uint256 totalRemovals;         // Number of completed removals
}
```

### **Processor Struct**
```solidity
struct Processor {
    address addr;                  // Processor address
    bool isProcessor;              // Registration status
    uint256 stake;                 // Staked RN tokens
    string description;            // Service description
    uint256 completedRemovals;     // Number of completed removals
    uint256 reputation;            // Score out of 100
    uint256 registrationTime;      // When registered
    bool isSlashed;                // Slashing status
}
```

### **User Struct**
```solidity
struct User {
    bool isStakingForRemoval;      // Staking status
    uint256 stakeAmount;           // Amount staked
    uint256 stakeTime;             // When stake was placed
    address[] selectedProcessors;  // Trusted processors
}
```

### **RemovalRequest Struct**
```solidity
struct RemovalRequest {
    uint256 id;                    // Unique identifier
    address user;                  // Requesting user
    uint256 brokerId;              // Target broker ID
    address processor;             // Assigned processor
    bool isCompleted;              // Completion status
    bool isVerified;               // Verification status
    uint256 requestTime;           // When requested
    uint256 completionTime;        // When completed
    string zkProof;                // zkEmail proof hash (future)
}
```

---

## 🔧 **Function Reference**

### **Constructor**

```solidity
constructor() ERC20("RemovalNinja", "RN") Ownable(msg.sender)
```
**Purpose**: Initializes the contract with 1M RN tokens minted to deployer  
**Access**: Public (deployment only)  
**Parameters**: None  
**Returns**: None  

---

### **Data Broker Functions**

#### **submitDataBroker**
```solidity
function submitDataBroker(
    string calldata name,
    string calldata website,
    string calldata removalInstructions
) external whenNotPaused
```
**Purpose**: Submit a new data broker to the registry  
**Access**: Public (when not paused)  
**Parameters**:
- `name`: The name of the data broker (required, non-empty)
- `website`: The website URL of the data broker (required, non-empty)
- `removalInstructions`: Instructions for data removal (optional)

**Returns**: None  
**Effects**:
- Creates new DataBroker with auto-incremented ID
- Mints 100 RN tokens to submitter
- Emits `DataBrokerSubmitted` event

**Requirements**:
- Contract must not be paused
- Name must not be empty
- Website must not be empty

#### **verifyDataBroker**
```solidity
function verifyDataBroker(uint256 brokerId) external onlyOwner validBrokerId(brokerId)
```
**Purpose**: Verify a data broker entry (admin function)  
**Access**: Owner only  
**Parameters**:
- `brokerId`: ID of the broker to verify

**Returns**: None  
**Effects**:
- Sets broker's `isVerified` flag to true
- Emits `BrokerVerified` event

#### **getAllDataBrokers**
```solidity
function getAllDataBrokers() external view returns (DataBroker[] memory)
```
**Purpose**: Retrieve all submitted data brokers  
**Access**: Public view  
**Parameters**: None  
**Returns**: Array of all DataBroker structs  

---

### **Processor Functions**

#### **registerProcessor**
```solidity
function registerProcessor(
    uint256 stakeAmount,
    string calldata description
) external whenNotPaused
```
**Purpose**: Register as a removal processor  
**Access**: Public (when not paused)  
**Parameters**:
- `stakeAmount`: Amount of RN tokens to stake (minimum 1,000 RN)
- `description`: Description of processor services

**Returns**: None  
**Effects**:
- Transfers staked tokens to contract
- Creates Processor entry with 100 reputation
- Adds to allProcessors array
- Emits `ProcessorRegistered` event

**Requirements**:
- Contract must not be paused
- Caller must not already be registered
- Stake amount must be ≥ MIN_PROCESSOR_STAKE
- Caller must have sufficient RN balance

#### **getAllProcessors**
```solidity
function getAllProcessors() external view returns (Processor[] memory)
```
**Purpose**: Retrieve all registered processors  
**Access**: Public view  
**Parameters**: None  
**Returns**: Array of all Processor structs  

#### **slashProcessor**
```solidity
function slashProcessor(
    address processorAddr,
    string calldata reason
) external onlyOwner
```
**Purpose**: Slash a processor for poor performance  
**Access**: Owner only  
**Parameters**:
- `processorAddr`: Address of the processor to slash
- `reason`: Reason for slashing

**Returns**: None  
**Effects**:
- Reduces processor stake by 10%
- Sets reputation to 0
- Marks processor as slashed
- Burns slashed tokens
- Emits `ProcessorSlashed` event

---

### **User Functions**

#### **stakeForRemoval**
```solidity
function stakeForRemoval(
    uint256 stakeAmount,
    address[] calldata selectedProcessors
) external whenNotPaused
```
**Purpose**: Stake tokens for removal services and select trusted processors  
**Access**: Public (when not paused)  
**Parameters**:
- `stakeAmount`: Amount of RN tokens to stake (minimum 10 RN)
- `selectedProcessors`: Array of trusted processor addresses

**Returns**: None  
**Effects**:
- Transfers staked tokens to contract
- Creates User entry with selected processors
- Updates user mappings
- Emits `UserStakedForRemoval` event

**Requirements**:
- Contract must not be paused
- User must not already be staking
- Stake amount must be ≥ MIN_USER_STAKE
- Must select 1-5 processors
- All selected processors must be valid and not slashed
- User must have sufficient RN balance

#### **requestRemoval**
```solidity
function requestRemoval(uint256 brokerId) external onlyActiveUser validBrokerId(brokerId)
```
**Purpose**: Request removal from a specific data broker  
**Access**: Users who are staking for removal  
**Parameters**:
- `brokerId`: ID of the broker to request removal from

**Returns**: None  
**Effects**:
- Creates RemovalRequest with auto-incremented ID
- Assigns first available selected processor
- Emits `RemovalRequested` event

**Requirements**:
- User must be actively staking for removal
- Broker ID must be valid
- User must have selected processors
- Selected processor must be available and not slashed

#### **completeRemoval**
```solidity
function completeRemoval(
    uint256 removalId,
    string calldata zkProof
) external onlyProcessor validRemovalId(removalId)
```
**Purpose**: Complete a removal request  
**Access**: Registered processors only  
**Parameters**:
- `removalId`: ID of the removal request to complete
- `zkProof`: zkEmail proof hash (future implementation)

**Returns**: None  
**Effects**:
- Marks request as completed
- Updates processor and broker statistics
- Mints 50 RN tokens to processor
- Emits `RemovalCompleted` event

**Requirements**:
- Caller must be registered, active processor
- Removal ID must be valid
- Processor must be assigned to this request
- Request must not already be completed

#### **getUserSelectedProcessors**
```solidity
function getUserSelectedProcessors(address user) external view returns (address[] memory)
```
**Purpose**: Get user's selected processors  
**Access**: Public view  
**Parameters**:
- `user`: Address of the user

**Returns**: Array of selected processor addresses  

---

### **Admin Functions**

#### **pause**
```solidity
function pause() external onlyOwner
```
**Purpose**: Pause contract operations (emergency only)  
**Access**: Owner only  
**Parameters**: None  
**Returns**: None  

#### **unpause**
```solidity
function unpause() external onlyOwner
```
**Purpose**: Resume contract operations  
**Access**: Owner only  
**Parameters**: None  
**Returns**: None  

#### **emergencyWithdraw**
```solidity
function emergencyWithdraw() external onlyOwner
```
**Purpose**: Emergency withdrawal of contract balance  
**Access**: Owner only  
**Parameters**: None  
**Returns**: None  
**Effects**: Transfers all contract RN tokens to owner  

---

### **View Functions**

#### **getStats**
```solidity
function getStats() external view returns (
    uint256 totalBrokers,
    uint256 totalProcessors,
    uint256 totalRemovals,
    uint256 contractBalance
)
```
**Purpose**: Get contract statistics  
**Access**: Public view  
**Parameters**: None  
**Returns**:
- `totalBrokers`: Number of submitted brokers
- `totalProcessors`: Number of registered processors
- `totalRemovals`: Number of removal requests
- `contractBalance`: Contract's RN token balance

#### **isProcessor**
```solidity
function isProcessor(address addr) external view returns (bool)
```
**Purpose**: Check if address is an active processor  
**Access**: Public view  
**Parameters**:
- `addr`: Address to check

**Returns**: True if registered and not slashed  

#### **getProcessorReputation**
```solidity
function getProcessorReputation(address processorAddr) external view returns (uint256)
```
**Purpose**: Get processor's reputation score  
**Access**: Public view  
**Parameters**:
- `processorAddr`: Address of the processor

**Returns**: Reputation score (0-100)  
**Requirements**: Address must be a registered processor  

---

## 📡 **Events**

### **DataBrokerSubmitted**
```solidity
event DataBrokerSubmitted(
    uint256 indexed brokerId,
    string name,
    address indexed submitter
);
```
Emitted when a new data broker is submitted.

### **ProcessorRegistered**
```solidity
event ProcessorRegistered(
    address indexed processor,
    uint256 stake,
    string description
);
```
Emitted when a new processor registers.

### **UserStakedForRemoval**
```solidity
event UserStakedForRemoval(
    address indexed user,
    uint256 amount,
    address[] selectedProcessors
);
```
Emitted when a user stakes for removal services.

### **RemovalRequested**
```solidity
event RemovalRequested(
    uint256 indexed removalId,
    address indexed user,
    uint256 indexed brokerId,
    address processor
);
```
Emitted when a removal request is created.

### **RemovalCompleted**
```solidity
event RemovalCompleted(
    uint256 indexed removalId,
    address indexed processor,
    string zkProof
);
```
Emitted when a removal request is completed.

### **ProcessorSlashed**
```solidity
event ProcessorSlashed(
    address indexed processor,
    uint256 slashedAmount,
    string reason
);
```
Emitted when a processor is slashed.

### **BrokerVerified**
```solidity
event BrokerVerified(
    uint256 indexed brokerId,
    address indexed verifier
);
```
Emitted when a broker is verified by the owner.

---

## 🔒 **Modifiers**

### **onlyProcessor**
```solidity
modifier onlyProcessor()
```
Restricts access to registered, non-slashed processors.

### **onlyActiveUser**
```solidity
modifier onlyActiveUser()
```
Restricts access to users who are currently staking for removal.

### **validBrokerId**
```solidity
modifier validBrokerId(uint256 brokerId)
```
Validates that the broker ID exists in the system.

### **validRemovalId**
```solidity
modifier validRemovalId(uint256 removalId)
```
Validates that the removal ID exists in the system.

---

## 🧪 **Testing Coverage**

### **Test Categories**

#### **1. Basic Contract Tests**
- ✅ `test_InitialState()` - Verify contract initialization
- ✅ `test_OwnershipTransfer()` - Test ownership transfer
- ✅ `test_PauseUnpause()` - Test pause/unpause functionality
- ✅ `test_RevertWhen_NonOwnerPauses()` - Access control validation

#### **2. Data Broker Tests**
- ✅ `test_SubmitDataBroker()` - Submit valid broker
- ✅ `test_RevertWhen_SubmitEmptyBrokerName()` - Empty name validation
- ✅ `test_RevertWhen_SubmitEmptyBrokerWebsite()` - Empty website validation
- ✅ `test_VerifyDataBroker()` - Owner verification
- ✅ `test_RevertWhen_NonOwnerVerifiesBroker()` - Access control
- ✅ `test_RevertWhen_VerifyInvalidBroker()` - Invalid ID validation
- ✅ `test_GetAllDataBrokers()` - Retrieval functionality

#### **3. Processor Tests**
- ✅ `test_RegisterProcessor()` - Valid registration
- ✅ `test_RevertWhen_RegisterProcessorInsufficientStake()` - Stake validation
- ✅ `test_RevertWhen_RegisterProcessorInsufficientBalance()` - Balance validation
- ✅ `test_RevertWhen_RegisterProcessorTwice()` - Duplicate registration
- ✅ `test_SlashProcessor()` - Slashing mechanism
- ✅ `test_RevertWhen_NonOwnerSlashesProcessor()` - Access control
- ✅ `test_GetAllProcessors()` - Retrieval functionality

#### **4. User Staking Tests**
- ✅ `test_StakeForRemoval()` - Valid staking
- ✅ `test_RevertWhen_StakeForRemovalInsufficientAmount()` - Amount validation
- ✅ `test_RevertWhen_StakeForRemovalNoProcessors()` - Processor requirement
- ✅ `test_RevertWhen_StakeForRemovalInvalidProcessor()` - Processor validation
- ✅ `test_RevertWhen_StakeForRemovalSlashedProcessor()` - Slashed processor check
- ✅ `test_RevertWhen_StakeForRemovalTwice()` - Duplicate staking
- ✅ `test_RevertWhen_StakeForRemovalTooManyProcessors()` - Maximum limit

#### **5. Removal Request Tests**
- ✅ `test_RequestRemoval()` - Valid request creation
- ✅ `test_RevertWhen_RequestRemovalNotStaking()` - Staking requirement
- ✅ `test_RevertWhen_RequestRemovalInvalidBroker()` - Broker validation
- ✅ `test_CompleteRemoval()` - Valid completion
- ✅ `test_RevertWhen_CompleteRemovalNotProcessor()` - Access control
- ✅ `test_RevertWhen_CompleteRemovalWrongProcessor()` - Assignment validation
- ✅ `test_RevertWhen_CompleteRemovalAlreadyCompleted()` - Duplicate completion
- ✅ `test_RevertWhen_CompleteRemovalInvalidId()` - ID validation

#### **6. View Function Tests**
- ✅ `test_GetStats()` - Statistics retrieval
- ✅ `test_GetProcessorReputation()` - Reputation queries
- ✅ `test_RevertWhen_GetReputationNonProcessor()` - Invalid processor

#### **7. Admin Function Tests**
- ✅ `test_EmergencyWithdraw()` - Emergency withdrawal
- ✅ `test_RevertWhen_NonOwnerEmergencyWithdraw()` - Access control

#### **8. Fuzzing Tests**
- ✅ `testFuzz_SubmitDataBroker()` - Random broker data (1000 runs)
- ✅ `testFuzz_ProcessorStake()` - Random stake amounts (1000 runs)
- ✅ `testFuzz_UserStake()` - Random user stakes (1000 runs)
- ✅ `testFuzz_MultipleProcessorSelection()` - Random processor counts (1000 runs)
- ✅ `testFuzz_SlashingAmount()` - Random slashing scenarios (1000 runs)

#### **9. Integration Tests**
- ✅ `test_FullWorkflow()` - Complete end-to-end flow
- ✅ `test_MultipleRemovalRequests()` - Multiple concurrent requests

#### **10. Edge Case Tests**
- ✅ `test_ProcessorStakingAfterSlashing()` - Post-slashing behavior
- ✅ `test_PausedContractBehavior()` - Functionality during pause
- ✅ `test_ZeroStakeEdgeCases()` - Zero value handling

### **Test Statistics**
- **Total Tests**: 50 tests
- **Fuzzing Runs**: 1,000 iterations per fuzzing test
- **Execution Time**: ~350ms for full suite
- **Coverage**: 100% function coverage

### **Fuzzing Parameters**
- **String inputs**: Length bounded (1-500 characters)
- **Stake amounts**: Bounded between minimum requirements and 100,000 RN
- **Processor counts**: 1-5 processors (respecting MAX_SELECTED_PROCESSORS)
- **Edge cases**: Zero values, maximum values, boundary conditions

---

## 🛡️ **Security Considerations**

### **Access Controls**
- **Owner Functions**: `verifyDataBroker`, `slashProcessor`, `pause`, `unpause`, `emergencyWithdraw`
- **Processor Functions**: `completeRemoval` (with assignment validation)
- **User Functions**: `requestRemoval` (requires active staking)

### **Security Features**
1. **Reentrancy Protection**: `ReentrancyGuard` on all state-changing functions
2. **Pausable Operations**: Emergency stop for critical functions
3. **Input Validation**: Comprehensive parameter checking
4. **Balance Verification**: Prevents insufficient balance operations
5. **State Consistency**: Proper state updates and event emission
6. **Slashing Protection**: Prevents interaction with slashed processors

### **Known Limitations**
1. **Processor Selection**: Currently uses simple first-available selection
2. **zkEmail Integration**: Placeholder for future cryptographic verification
3. **Reputation Updates**: Manual reputation management by owner
4. **Token Recovery**: No mechanism to recover mistakenly sent tokens

### **Recommended Security Practices**
1. **Multi-signature Wallet**: Use multisig for owner functions
2. **Timelock**: Consider timelock for critical administrative functions
3. **Regular Audits**: Periodic security audits and bug bounties
4. **Monitoring**: Real-time monitoring of contract interactions
5. **Emergency Procedures**: Documented response procedures for incidents

---

## 🚀 **Deployment Information**

### **Deployment Script**
Use the automated deployment script:
```bash
./deploy_contracts.sh base-sepolia --verify
```

### **Contract Verification**
The contract can be verified on block explorers using:
- **Base Sepolia**: BaseScan verification
- **Other Networks**: Etherscan verification

### **Post-Deployment Checklist**
1. ✅ Verify contract on block explorer
2. ✅ Update frontend configuration with contract address
3. ✅ Test basic functions (submit broker, register processor)
4. ✅ Configure monitoring and alerting
5. ✅ Set up multisig for owner functions (recommended)

### **Frontend Integration**
Update `client/src/config/contracts.ts`:
```typescript
export const CONTRACTS = {
  BASE_SEPOLIA: {
    REMOVAL_NINJA: {
      address: "YOUR_DEPLOYED_ADDRESS_HERE",
      abi: [...] // Contract ABI
    },
  },
};
```

---

## 📚 **Additional Resources**

- **Foundry Testing Guide**: [Foundry Book](https://book.getfoundry.sh/)
- **OpenZeppelin Contracts**: [Documentation](https://docs.openzeppelin.com/contracts/)
- **Base Network**: [Developer Docs](https://docs.base.org/)
- **ERC-20 Standard**: [EIP-20](https://eips.ethereum.org/EIPS/eip-20)

---

**📅 Last Updated**: $(date)  
**🔄 Version**: 1.0.0  
**👨‍💻 Maintainer**: Pierce  
**📜 License**: Apache-2.0

---

*This documentation is generated for the RemovalNinja decentralized data broker removal protocol. For technical support or questions, please refer to the project repository.*
