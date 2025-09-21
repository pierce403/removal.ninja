# 🚀 Quick Start Guide

This guide will help you get removal.ninja running locally in development mode.

## Prerequisites

- Node.js 18+
- npm
- MetaMask browser extension (for blockchain interaction)

## Step 1: Install Dependencies

```bash
# Install all dependencies
npm run install:all
```

## Step 2: Start Development Server

```bash
# Start the backend server
npm run server:dev
```

The API will be available at http://localhost:5000

## Step 3: Start Frontend (New Terminal)

```bash
# Start the React frontend
npm run client:dev
```

The frontend will be available at http://localhost:3000

## Step 4: Blockchain Setup (Optional)

If you want to test the full blockchain functionality:

### Option A: Local Hardhat Network

```bash
# Terminal 1: Start local blockchain
cd contracts
npx hardhat node

# Terminal 2: Compile and deploy contracts
cd contracts
npx hardhat compile
npx hardhat run scripts/deploy.js --network localhost
```

### Option B: Test Without Blockchain

The application will work in "demo mode" without blockchain deployment:
- Browse data brokers (mock data)
- View UI components
- Test form submissions (logged to console)

## Features Available

### Without Blockchain
- ✅ Browse interface
- ✅ Form validations
- ✅ Navigation
- ✅ Responsive design

### With Blockchain
- ✅ Submit data brokers (earn 100 RN tokens)
- ✅ Register as processor (stake 1000+ RN tokens)
- ✅ Stake for removal list (minimum 10 RN tokens)
- ✅ Request removals from data brokers
- ✅ Process removal requests (earn 50 RN tokens)

## Connect MetaMask

1. Install MetaMask browser extension
2. Create or import a wallet
3. Connect to localhost network (if using local blockchain)
4. Click "Connect Wallet" in the app

## Troubleshooting

### "Contract not deployed" errors
- Make sure you've deployed the smart contract (Step 4)
- Check that MetaMask is connected to the correct network

### Port conflicts
- Backend uses port 5000
- Frontend uses port 3000
- Change ports in package.json if needed

### Compilation errors
- Ensure internet connection for downloading Solidity compiler
- Or work in demo mode without blockchain

## Next Steps

1. Browse to http://localhost:3000
2. Connect your MetaMask wallet
3. Explore the data brokers directory
4. Try submitting a new data broker
5. Register as a processor or stake for removal list

## Demo Flow

1. **Submit Data Broker**: Add a new data broker and earn 100 RN tokens
2. **Become Processor**: Stake 1000 RN tokens to process removal requests
3. **User Journey**: Stake 10 RN tokens to get on removal list and request removals
4. **Process Requests**: Earn 50 RN tokens for each completed removal

For full documentation, see [README.md](README.md).