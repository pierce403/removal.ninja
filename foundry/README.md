# RemovalNinja Contract Testing & Deployment

This directory contains the Foundry-based testing and deployment infrastructure for the RemovalNinja protocol.

## 🏗️ **Project Structure**

```
foundry/
├── src/
│   └── RemovalNinja.sol          # Main protocol contract
├── test/
│   └── RemovalNinja.t.sol        # Comprehensive test suite with fuzzing
├── script/
│   ├── DeployBase.s.sol          # Base Sepolia deployment script
│   └── FlattenContract.s.sol     # Contract flattening helper
├── flattened/
│   └── RemovalNinja_Flattened.sol # Flattened contract for Remix
├── foundry.toml                   # Foundry configuration
└── env.example                    # Environment variables template
```

## 🧪 **Testing**

### **Comprehensive Test Suite**
- **48 test functions** covering all contract functionality
- **Unit tests** for individual functions
- **Integration tests** for complete workflows
- **Fuzzing tests** for edge case discovery
- **Security tests** for access controls and slashing
- **Edge case testing** for boundary conditions

### **Running Tests**

```bash
# Run all tests
forge test

# Run tests with verbose output
forge test -vvv

# Run specific test
forge test --match-test test_SubmitDataBroker

# Run fuzzing tests with more iterations
forge test --match-test testFuzz --ffi

# Run tests with gas reports
forge test --gas-report

# Test coverage
forge coverage
```

### **Test Categories**

1. **Basic Contract Tests**
   - Initial state validation
   - Ownership and access controls
   - Pause/unpause functionality

2. **Data Broker Tests**
   - Broker submission and verification
   - Reward distribution
   - Input validation

3. **Processor Tests**
   - Registration and staking
   - Slashing mechanisms
   - Reputation system

4. **User Staking Tests**
   - Stake requirements and validation
   - Processor selection
   - Balance management

5. **Removal Request Tests**
   - Request creation and completion
   - Processor assignment
   - zkProof handling

6. **Fuzzing Tests**
   - Random input validation
   - Boundary testing
   - Large-scale scenario testing

## 🚀 **Deployment**

### **Base Sepolia Testnet**

#### **Prerequisites**
1. Copy environment configuration:
   ```bash
   cp env.example .env
   ```

2. Configure your `.env` file:
   - `PRIVATE_KEY`: Your deployment wallet private key (without 0x)
   - `BASE_SEPOLIA_RPC_URL`: Base Sepolia RPC URL
   - `BASESCAN_API_KEY`: BaseScan API key for verification

3. Fund your wallet with Base Sepolia ETH:
   - [QuickNode Faucet](https://faucet.quicknode.com/base/sepolia)
   - [Coinbase Faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet)

#### **Deployment Options**

**Option 1: Automated Script (Recommended)**
```bash
# From project root
./scripts/deploy-base.sh
```

**Option 2: Manual Forge Deployment**
```bash
cd foundry

# Deploy with verification
forge script script/DeployBase.s.sol:DeployBase \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY
```

**Option 3: Remix IDE Deployment**
```bash
# Generate flattened contract
./scripts/flatten.sh

# Then use foundry/flattened/RemovalNinja_Flattened.sol in Remix
```

### **Post-Deployment**

1. **Update Frontend Configuration**
   ```typescript
   // client/src/config/contracts.ts
   export const CONTRACTS = {
     BASE_SEPOLIA: {
       REMOVAL_NINJA: {
         address: "YOUR_DEPLOYED_ADDRESS_HERE",
         // ...
       },
     },
   };
   ```

2. **Verify Contract on BaseScan**
   ```bash
   forge verify-contract <CONTRACT_ADDRESS> \
     src/RemovalNinja.sol:RemovalNinja \
     --chain base-sepolia \
     --etherscan-api-key $BASESCAN_API_KEY
   ```

3. **Test Contract Functions**
   - Visit contract on [BaseScan](https://sepolia.basescan.org)
   - Test read functions
   - Execute write functions (connect wallet)

## 🔧 **Development Tools**

### **Contract Flattening**
```bash
# Generate flattened contract for Remix
./scripts/flatten.sh
```

### **Gas Optimization**
```bash
# Analyze gas usage
forge test --gas-report

# Profile specific functions
forge test --match-test test_SubmitDataBroker --gas-report
```

### **Code Coverage**
```bash
# Generate coverage report
forge coverage

# Generate HTML coverage report
forge coverage --report lcov
genhtml lcov.info -o coverage/
```

### **Static Analysis**
```bash
# Run built-in linting
forge lint

# Check for common issues
slither . --exclude-dependencies
```

## 📊 **Contract Features**

### **Core Functionality**
- **ERC20 Token**: RN token with 18 decimals
- **Data Broker Registry**: Community-submitted broker database
- **Processor Network**: Trusted entities for removal processing
- **User Staking**: Stake tokens to access removal services
- **Removal Requests**: End-to-end removal workflow
- **Reputation System**: Track processor performance
- **Slashing Mechanism**: Penalize poor performance

### **Security Features**
- **Access Controls**: Owner-only functions for critical operations
- **Reentrancy Guard**: Protection against reentrancy attacks
- **Pausable**: Emergency stop functionality
- **Input Validation**: Comprehensive parameter checking
- **Balance Verification**: Prevent insufficient balance operations

### **Token Economics**
- **Broker Submission**: 100 RN tokens reward
- **Removal Processing**: 50 RN tokens reward
- **User Staking**: Minimum 10 RN tokens
- **Processor Staking**: Minimum 1,000 RN tokens
- **Slashing Rate**: 10% of stake for poor performance

## 🌐 **Network Configuration**

### **Base Sepolia Testnet**
- **Chain ID**: 84532
- **RPC URL**: https://sepolia.base.org
- **Explorer**: https://sepolia.basescan.org
- **Faucet**: https://faucet.quicknode.com/base/sepolia

### **Adding to MetaMask**
```javascript
{
  chainId: "0x14a34", // 84532 in hex
  chainName: "Base Sepolia",
  rpcUrls: ["https://sepolia.base.org"],
  nativeCurrency: {
    name: "Ethereum",
    symbol: "ETH",
    decimals: 18
  },
  blockExplorerUrls: ["https://sepolia.basescan.org"]
}
```

## 🔍 **Troubleshooting**

### **Common Issues**

1. **"Insufficient balance" during deployment**
   - Get Base Sepolia ETH from faucet
   - Check wallet balance: `cast balance <address> --rpc-url $BASE_SEPOLIA_RPC_URL`

2. **"Invalid private key" error**
   - Ensure private key is without 0x prefix
   - Generate new key: `cast wallet new`

3. **Contract verification fails**
   - Check BaseScan API key is valid
   - Ensure constructor parameters match deployment
   - Try manual verification on BaseScan

4. **Tests failing locally**
   - Update dependencies: `forge update`
   - Clear cache: `forge clean && forge build`
   - Check Solidity version compatibility

### **Getting Help**

- **Foundry Documentation**: https://book.getfoundry.sh/
- **Base Documentation**: https://docs.base.org/
- **RemovalNinja Issues**: Create issue in repository

## 📈 **Performance Benchmarks**

**Test Suite Performance:**
- **50 total tests** (48 RemovalNinja + 2 Counter)
- **1000 fuzzing runs** per fuzzing test
- **Average test time**: ~350ms for full suite
- **Gas usage**: Detailed reports available via `forge test --gas-report`

**Contract Size:**
- **Flattened size**: ~45KB
- **Compilation time**: ~1.5s
- **Deployment gas**: ~4.5M gas

---

**🥷 Happy testing and deploying!**