#!/bin/bash

# Deploy RemovalNinja to Base Sepolia Testnet
# This script deploys the contract using Foundry and updates frontend configuration

set -e

echo "🚀 Deploying RemovalNinja to Base Sepolia Testnet..."

# Check if .env file exists
if [ ! -f foundry/.env ]; then
    echo "❌ Error: foundry/.env file not found!"
    echo "Please copy foundry/env.example to foundry/.env and configure your settings."
    exit 1
fi

# Load environment variables
source foundry/.env

# Check required environment variables
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in foundry/.env"
    exit 1
fi

if [ -z "$BASE_SEPOLIA_RPC_URL" ]; then
    echo "❌ Error: BASE_SEPOLIA_RPC_URL not set in foundry/.env"
    exit 1
fi

echo "🔍 Checking deployer wallet..."
cd foundry

# Get deployer address and check balance
DEPLOYER_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
BALANCE=$(cast balance $DEPLOYER_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL)

echo "📋 Deployment Information:"
echo "   - Deployer: $DEPLOYER_ADDRESS"
echo "   - Balance: $BALANCE ETH"
echo "   - Network: Base Sepolia (Chain ID: 84532)"
echo "   - RPC: $BASE_SEPOLIA_RPC_URL"

# Check if balance is sufficient (at least 0.01 ETH)
BALANCE_WEI=$(echo $BALANCE | cut -d' ' -f1)
MIN_BALANCE="10000000000000000" # 0.01 ETH in wei

if [ "$(echo "$BALANCE_WEI < $MIN_BALANCE" | bc)" -eq 1 ]; then
    echo "⚠️  Warning: Low balance. You may need more ETH for deployment."
    echo "   Get Base Sepolia ETH from: https://faucet.quicknode.com/base/sepolia"
fi

echo ""
read -p "🤔 Continue with deployment? (y/N): " confirm

if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    echo "❌ Deployment cancelled."
    exit 0
fi

echo ""
echo "🔨 Compiling contracts..."
forge build

echo "📡 Deploying to Base Sepolia..."

# Deploy the contract
forge script script/DeployBase.s.sol:DeployBase \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY \
    -vvvv

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    
    # Extract contract address from deployment output
    if [ -f "deployment-base-sepolia.json" ]; then
        CONTRACT_ADDRESS=$(cat deployment-base-sepolia.json | grep -o '"contractAddress": "[^"]*"' | cut -d'"' -f4)
        echo "📋 Contract deployed to: $CONTRACT_ADDRESS"
        echo "🔍 View on BaseScan: https://sepolia.basescan.org/address/$CONTRACT_ADDRESS"
        
        echo ""
        echo "🔧 Next steps:"
        echo "1. Update client/src/config/contracts.ts with the new contract address"
        echo "2. Test the contract functions on BaseScan"
        echo "3. Update your frontend to use the deployed contract"
        echo "4. Test wallet connection with Base Sepolia network"
        
        echo ""
        echo "💡 Frontend configuration:"
        echo "   Update this line in client/src/config/contracts.ts:"
        echo "   address: \"$CONTRACT_ADDRESS\","
    else
        echo "⚠️  Deployment info file not found. Check logs above for contract address."
    fi
else
    echo "❌ Deployment failed! Check the error messages above."
    exit 1
fi

echo ""
echo "🎉 Deployment process complete! 🥷"
