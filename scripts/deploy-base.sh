#!/bin/bash

# Deploy RemovalNinja Modular System to Base Sepolia Testnet
# This script deploys the complete modular system using Foundry

set -e

echo "🚀 Deploying RemovalNinja Modular System to Base Sepolia Testnet..."

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
echo "   - Contracts: Token + Registry + TaskFactory (3 contracts)"

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

# Deploy the modular contract system
forge script script/DeployBaseSepolia.s.sol:DeployBaseSepolia \
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
    
    # Extract contract addresses from deployment output
    if [ -f "deployment-base-sepolia.json" ]; then
        echo "📋 Deployment Summary:"
        
        # Parse the JSON for all contract addresses
        TOKEN_ADDRESS=$(cat deployment-base-sepolia.json | grep -A1 '"RemovalNinja"' | tail -n1 | cut -d'"' -f4)
        REGISTRY_ADDRESS=$(cat deployment-base-sepolia.json | grep -A1 '"DataBrokerRegistry"' | tail -n1 | cut -d'"' -f4)
        FACTORY_ADDRESS=$(cat deployment-base-sepolia.json | grep -A1 '"TaskFactory"' | tail -n1 | cut -d'"' -f4)
        
        echo "   Token (RN):     $TOKEN_ADDRESS"
        echo "   Registry:       $REGISTRY_ADDRESS"
        echo "   Task Factory:   $FACTORY_ADDRESS"
        echo ""
        echo "🔍 View on BaseScan:"
        echo "   Token:     https://sepolia.basescan.org/address/$TOKEN_ADDRESS"
        echo "   Registry:  https://sepolia.basescan.org/address/$REGISTRY_ADDRESS"
        echo "   Factory:   https://sepolia.basescan.org/address/$FACTORY_ADDRESS"
        
        echo ""
        echo "🔧 Next steps:"
        echo "1. Update client/src/config/contracts.ts with the new contract addresses"
        echo "2. Switch ACTIVE_NETWORK to BASE_SEPOLIA in contracts.ts"
        echo "3. Test the contract functions on BaseScan"
        echo "4. Add Base Sepolia network to MetaMask if needed"
        echo "5. Get some test ETH from Base Sepolia faucet"
        
        echo ""
        echo "💡 Frontend configuration updates needed:"
        echo "   In client/src/config/contracts.ts, update BASE_SEPOLIA section:"
        echo "   REMOVAL_NINJA_TOKEN: { address: \"$TOKEN_ADDRESS\" }"
        echo "   DATA_BROKER_REGISTRY: { address: \"$REGISTRY_ADDRESS\" }"
        echo "   TASK_FACTORY: { address: \"$FACTORY_ADDRESS\" }"
        echo ""
        echo "   And change: export const ACTIVE_NETWORK = SUPPORTED_NETWORKS.BASE_SEPOLIA;"
    else
        echo "⚠️  Deployment info file not found. Check logs above for contract addresses."
    fi
else
    echo "❌ Deployment failed! Check the error messages above."
    exit 1
fi

echo ""
echo "🎉 RemovalNinja Modular System deployment complete! 🥷"
echo "📚 3 initial brokers added: Spokeo, Radaris, Whitepages"
echo "💰 100,000 RN tokens minted to deployer for testing"
