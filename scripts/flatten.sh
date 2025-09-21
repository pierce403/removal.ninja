#!/bin/bash

# Contract Flattening Script for Remix Deployment
# This script flattens the RemovalNinja contract for easy deployment in Remix IDE

set -e

echo "🔧 Starting contract flattening process..."

# Create flattened directory if it doesn't exist
mkdir -p foundry/flattened

# Change to foundry directory
cd foundry

echo "📝 Flattening RemovalNinja contract..."

# Flatten the contract using forge flatten
forge flatten src/RemovalNinja.sol > flattened/RemovalNinja_Flattened.sol

echo "✅ Contract flattened successfully!"

# Get file size
FILE_SIZE=$(wc -c < flattened/RemovalNinja_Flattened.sol)
LINE_COUNT=$(wc -l < flattened/RemovalNinja_Flattened.sol)

echo "📊 Flattened contract stats:"
echo "   - File size: $FILE_SIZE bytes"
echo "   - Line count: $LINE_COUNT lines"
echo "   - Output: foundry/flattened/RemovalNinja_Flattened.sol"

echo ""
echo "🚀 Next steps for Remix deployment:"
echo "1. Open Remix IDE: https://remix.ethereum.org"
echo "2. Create new file: RemovalNinja_Flattened.sol"
echo "3. Copy content from: foundry/flattened/RemovalNinja_Flattened.sol"
echo "4. Compile with Solidity 0.8.19+"
echo "5. Deploy to Base Sepolia testnet"
echo "6. Constructor parameters: none required"
echo "7. After deployment, verify on BaseScan"

echo ""
echo "⚙️  Recommended Remix settings:"
echo "   - Compiler: 0.8.19 or higher"
echo "   - Optimization: Enabled (200 runs)"
echo "   - EVM Version: london"

echo ""
echo "🌐 Base Sepolia network configuration:"
echo "   - Network Name: Base Sepolia"
echo "   - RPC URL: https://sepolia.base.org"
echo "   - Chain ID: 84532"
echo "   - Currency Symbol: ETH"
echo "   - Block Explorer: https://sepolia.basescan.org"

echo ""
echo "✨ Flattening complete! Happy deploying! 🥷"
