#!/bin/bash

# RemovalNinja Contract Deployment Script
# Automated deployment with key management and balance verification

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_KEY_FILE="$SCRIPT_DIR/deploy.key"
CONTRACTS_FILE="$SCRIPT_DIR/contracts.txt"
FOUNDRY_DIR="$SCRIPT_DIR/foundry"

# Network configurations
declare -A NETWORKS
NETWORKS[base-sepolia]="https://sepolia.base.org"
NETWORKS[base]="https://mainnet.base.org"
NETWORKS[localhost]="http://127.0.0.1:8545"
NETWORKS[sepolia]="https://sepolia.infura.io/v3/YOUR_PROJECT_ID"
NETWORKS[mainnet]="https://mainnet.infura.io/v3/YOUR_PROJECT_ID"

declare -A CHAIN_IDS
CHAIN_IDS[base-sepolia]=84532
CHAIN_IDS[base]=8453
CHAIN_IDS[localhost]=31337
CHAIN_IDS[sepolia]=11155111
CHAIN_IDS[mainnet]=1

declare -A EXPLORERS
EXPLORERS[base-sepolia]="https://sepolia.basescan.org"
EXPLORERS[base]="https://basescan.org"
EXPLORERS[localhost]="http://localhost:8545"
EXPLORERS[sepolia]="https://sepolia.etherscan.io"
EXPLORERS[mainnet]="https://etherscan.io"

declare -A FAUCETS
FAUCETS[base-sepolia]="https://faucet.quicknode.com/base/sepolia"
FAUCETS[sepolia]="https://faucet.quicknode.com/ethereum/sepolia"
FAUCETS[localhost]="Local node - no faucet needed"

# Minimum balance requirements (in ETH)
declare -A MIN_BALANCES
MIN_BALANCES[base-sepolia]="0.01"
MIN_BALANCES[base]="0.1"
MIN_BALANCES[localhost]="1.0"
MIN_BALANCES[sepolia]="0.01"
MIN_BALANCES[mainnet]="0.5"

print_header() {
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🥷 RemovalNinja Contract Deployment 🥷                    ║"
    echo "║                     Foundry-based Multi-Network Deployer                     ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    echo -e "${CYAN}Usage:${NC} $0 [NETWORK] [OPTIONS]"
    echo ""
    echo -e "${CYAN}Available Networks:${NC}"
    for network in "${!NETWORKS[@]}"; do
        echo -e "  ${GREEN}$network${NC} - ${NETWORKS[$network]}"
    done
    echo ""
    echo -e "${CYAN}Options:${NC}"
    echo -e "  ${GREEN}--verify${NC}        Verify contracts on block explorer"
    echo -e "  ${GREEN}--dry-run${NC}       Show what would be deployed without executing"
    echo -e "  ${GREEN}--force${NC}         Force deployment even with low balance"
    echo -e "  ${GREEN}--help${NC}          Show this help message"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  $0 base-sepolia --verify"
    echo -e "  $0 localhost --dry-run"
    echo -e "  $0 base --verify --force"
}

check_dependencies() {
    echo -e "${BLUE}🔍 Checking dependencies...${NC}"
    
    # Check if foundry is installed
    if ! command -v forge &> /dev/null; then
        echo -e "${RED}❌ Foundry not found. Please install it first:${NC}"
        echo -e "${YELLOW}curl -L https://foundry.paradigm.xyz | bash${NC}"
        echo -e "${YELLOW}foundryup${NC}"
        exit 1
    fi
    
    # Check if cast is available
    if ! command -v cast &> /dev/null; then
        echo -e "${RED}❌ Cast not found. Please install Foundry tools.${NC}"
        exit 1
    fi
    
    # Check if bc is available for balance calculations
    if ! command -v bc &> /dev/null; then
        echo -e "${YELLOW}⚠️  bc not found. Installing for balance calculations...${NC}"
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y bc
        elif command -v brew &> /dev/null; then
            brew install bc
        else
            echo -e "${RED}❌ Please install bc manually for balance calculations${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✅ Dependencies check passed${NC}"
}

check_foundry_setup() {
    echo -e "${BLUE}🔧 Checking Foundry setup...${NC}"
    
    if [ ! -d "$FOUNDRY_DIR" ]; then
        echo -e "${RED}❌ Foundry directory not found at $FOUNDRY_DIR${NC}"
        exit 1
    fi
    
    if [ ! -f "$FOUNDRY_DIR/foundry.toml" ]; then
        echo -e "${RED}❌ foundry.toml not found. Please ensure Foundry is properly initialized.${NC}"
        exit 1
    fi
    
    if [ ! -f "$FOUNDRY_DIR/src/RemovalNinja.sol" ]; then
        echo -e "${RED}❌ RemovalNinja.sol contract not found.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Foundry setup verified${NC}"
}

generate_or_load_key() {
    if [ ! -f "$DEPLOY_KEY_FILE" ]; then
        echo -e "${YELLOW}🔑 No deployment key found. Generating new key...${NC}"
        
        # Generate a new private key using cast
        PRIVATE_KEY=$(cast wallet new | grep "Private key:" | cut -d' ' -f3)
        
        if [ -z "$PRIVATE_KEY" ]; then
            echo -e "${RED}❌ Failed to generate private key${NC}"
            exit 1
        fi
        
        # Remove 0x prefix if present
        PRIVATE_KEY=${PRIVATE_KEY#0x}
        
        echo "$PRIVATE_KEY" > "$DEPLOY_KEY_FILE"
        chmod 600 "$DEPLOY_KEY_FILE"
        
        # Get the address
        ADDRESS=$(cast wallet address --private-key "$PRIVATE_KEY")
        
        echo -e "${GREEN}✅ New deployment key generated${NC}"
        echo -e "${CYAN}📋 Deployment Address: ${GREEN}$ADDRESS${NC}"
        echo -e "${YELLOW}⚠️  Please save this address and fund it before deployment!${NC}"
        echo -e "${YELLOW}⚠️  Private key saved to: $DEPLOY_KEY_FILE${NC}"
        
        return 0
    else
        echo -e "${BLUE}🔑 Loading existing deployment key...${NC}"
        PRIVATE_KEY=$(cat "$DEPLOY_KEY_FILE")
        
        if [ -z "$PRIVATE_KEY" ]; then
            echo -e "${RED}❌ Empty private key file${NC}"
            exit 1
        fi
        
        # Remove 0x prefix if present
        PRIVATE_KEY=${PRIVATE_KEY#0x}
        
        # Validate the private key format
        if [[ ! "$PRIVATE_KEY" =~ ^[0-9a-fA-F]{64}$ ]]; then
            echo -e "${RED}❌ Invalid private key format${NC}"
            exit 1
        fi
        
        ADDRESS=$(cast wallet address --private-key "$PRIVATE_KEY")
        echo -e "${GREEN}✅ Deployment key loaded${NC}"
        echo -e "${CYAN}📋 Deployment Address: ${GREEN}$ADDRESS${NC}"
    fi
}

check_balance() {
    local network=$1
    local rpc_url=${NETWORKS[$network]}
    local min_balance=${MIN_BALANCES[$network]}
    
    echo -e "${BLUE}💰 Checking balance on $network...${NC}"
    
    # Get balance in wei
    BALANCE_WEI=$(cast balance "$ADDRESS" --rpc-url "$rpc_url" 2>/dev/null || echo "0")
    
    if [ "$BALANCE_WEI" = "0" ]; then
        echo -e "${RED}❌ Failed to fetch balance or balance is 0${NC}"
        echo -e "${YELLOW}💡 Please fund your address: $ADDRESS${NC}"
        
        if [ "$network" != "localhost" ] && [ -n "${FAUCETS[$network]}" ]; then
            echo -e "${CYAN}🚿 Faucet available: ${FAUCETS[$network]}${NC}"
        fi
        
        return 1
    fi
    
    # Convert to ETH
    BALANCE_ETH=$(cast from-wei "$BALANCE_WEI" eth)
    
    echo -e "${CYAN}💰 Current Balance: ${GREEN}$BALANCE_ETH ETH${NC}"
    echo -e "${CYAN}💰 Required Balance: ${YELLOW}$min_balance ETH${NC}"
    
    # Compare balances using bc
    if (( $(echo "$BALANCE_ETH < $min_balance" | bc -l) )); then
        echo -e "${RED}❌ Insufficient balance for deployment${NC}"
        echo -e "${YELLOW}💡 Please add more funds to: $ADDRESS${NC}"
        
        if [ "$network" != "localhost" ] && [ -n "${FAUCETS[$network]}" ]; then
            echo -e "${CYAN}🚿 Faucet: ${FAUCETS[$network]}${NC}"
        fi
        
        return 1
    fi
    
    echo -e "${GREEN}✅ Sufficient balance for deployment${NC}"
    return 0
}

compile_contracts() {
    echo -e "${BLUE}🔨 Compiling contracts...${NC}"
    
    cd "$FOUNDRY_DIR"
    
    if ! forge build; then
        echo -e "${RED}❌ Contract compilation failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Contracts compiled successfully${NC}"
    cd "$SCRIPT_DIR"
}

deploy_contracts() {
    local network=$1
    local verify_flag=$2
    local dry_run=$3
    
    local rpc_url=${NETWORKS[$network]}
    local chain_id=${CHAIN_IDS[$network]}
    local explorer=${EXPLORERS[$network]}
    
    echo -e "${BLUE}🚀 Deploying contracts to $network...${NC}"
    echo -e "${CYAN}📡 RPC URL: $rpc_url${NC}"
    echo -e "${CYAN}🔗 Chain ID: $chain_id${NC}"
    echo -e "${CYAN}🔍 Explorer: $explorer${NC}"
    
    cd "$FOUNDRY_DIR"
    
    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}🔍 DRY RUN MODE - No actual deployment${NC}"
        echo -e "${CYAN}Would deploy RemovalNinja contract with:${NC}"
        echo -e "  Network: $network"
        echo -e "  RPC: $rpc_url"
        echo -e "  Deployer: $ADDRESS"
        echo -e "  Verify: $verify_flag"
        return 0
    fi
    
    # Create deployment command
    local deploy_cmd="forge script script/DeployBase.s.sol:DeployBase --rpc-url $rpc_url --private-key $PRIVATE_KEY --broadcast"
    
    if [ "$verify_flag" = true ] && [ "$network" != "localhost" ]; then
        if [ "$network" = "base-sepolia" ] || [ "$network" = "base" ]; then
            deploy_cmd="$deploy_cmd --verify --etherscan-api-key \$BASESCAN_API_KEY"
        else
            deploy_cmd="$deploy_cmd --verify --etherscan-api-key \$ETHERSCAN_API_KEY"
        fi
    fi
    
    echo -e "${BLUE}📡 Executing deployment...${NC}"
    
    # Execute deployment
    if eval "$deploy_cmd"; then
        echo -e "${GREEN}✅ Deployment successful!${NC}"
        
        # Update contracts.txt with deployment info
        echo "# RemovalNinja Contract Deployments" > "$CONTRACTS_FILE"
        echo "# Generated on $(date)" >> "$CONTRACTS_FILE"
        echo "" >> "$CONTRACTS_FILE"
        
        # Try to extract contract address from deployment output
        if [ -f "deployment-base-sepolia.json" ]; then
            CONTRACT_ADDRESS=$(cat deployment-base-sepolia.json | grep -o '"contractAddress": "[^"]*"' | cut -d'"' -f4)
        else
            # Try to get from broadcast logs
            BROADCAST_DIR="broadcast/DeployBase.s.sol/$chain_id"
            if [ -d "$BROADCAST_DIR" ]; then
                LATEST_RUN=$(ls -t "$BROADCAST_DIR" | head -n1)
                if [ -f "$BROADCAST_DIR/$LATEST_RUN" ]; then
                    CONTRACT_ADDRESS=$(jq -r '.transactions[] | select(.transactionType == "CREATE") | .contractAddress' "$BROADCAST_DIR/$LATEST_RUN" 2>/dev/null || echo "")
                fi
            fi
        fi
        
        if [ -n "$CONTRACT_ADDRESS" ] && [ "$CONTRACT_ADDRESS" != "null" ]; then
            echo "[$network]" >> "$CONTRACTS_FILE"
            echo "RemovalNinja = $CONTRACT_ADDRESS" >> "$CONTRACTS_FILE"
            echo "Explorer = $explorer/address/$CONTRACT_ADDRESS" >> "$CONTRACTS_FILE"
            echo "Deployer = $ADDRESS" >> "$CONTRACTS_FILE"
            echo "Timestamp = $(date -Iseconds)" >> "$CONTRACTS_FILE"
            echo "" >> "$CONTRACTS_FILE"
            
            echo -e "${GREEN}📋 Contract Address: $CONTRACT_ADDRESS${NC}"
            echo -e "${CYAN}🔍 View on Explorer: $explorer/address/$CONTRACT_ADDRESS${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not extract contract address from deployment logs${NC}"
        fi
        
        # Update frontend configuration hint
        echo -e "${YELLOW}💡 Next steps:${NC}"
        echo -e "  1. Update client/src/config/contracts.ts with the new address"
        echo -e "  2. Test contract functions on the block explorer"
        echo -e "  3. Verify wallet connection in your dApp"
        
    else
        echo -e "${RED}❌ Deployment failed!${NC}"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
}

main() {
    # Parse arguments
    local network=""
    local verify_flag=false
    local dry_run=false
    local force=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verify)
                verify_flag=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --help)
                print_header
                print_usage
                exit 0
                ;;
            -*)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                print_usage
                exit 1
                ;;
            *)
                if [ -z "$network" ]; then
                    network=$1
                else
                    echo -e "${RED}❌ Multiple networks specified${NC}"
                    print_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Show header
    print_header
    
    # Validate network
    if [ -z "$network" ]; then
        echo -e "${RED}❌ No network specified${NC}"
        print_usage
        exit 1
    fi
    
    if [ -z "${NETWORKS[$network]}" ]; then
        echo -e "${RED}❌ Unknown network: $network${NC}"
        print_usage
        exit 1
    fi
    
    echo -e "${CYAN}🌐 Target Network: ${GREEN}$network${NC}"
    echo ""
    
    # Run checks
    check_dependencies
    check_foundry_setup
    generate_or_load_key
    
    # Check balance unless forced or dry run
    if [ "$dry_run" = false ] && [ "$force" = false ]; then
        if ! check_balance "$network"; then
            echo -e "${RED}❌ Deployment cancelled due to insufficient balance${NC}"
            echo -e "${YELLOW}💡 Use --force to deploy anyway (not recommended)${NC}"
            exit 1
        fi
    elif [ "$force" = true ]; then
        echo -e "${YELLOW}⚠️  Force flag enabled - skipping balance check${NC}"
    fi
    
    # Compile contracts
    if [ "$dry_run" = false ]; then
        compile_contracts
    fi
    
    # Deploy contracts
    deploy_contracts "$network" "$verify_flag" "$dry_run"
    
    echo -e "${GREEN}🎉 Deployment process completed successfully! 🥷${NC}"
}

# Run main function with all arguments
main "$@"
