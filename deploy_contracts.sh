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
    echo -e "  ${GREEN}--no-verify${NC}     Skip contract verification (verification is enabled by default)"
    echo -e "  ${GREEN}--dry-run${NC}       Show what would be deployed without executing"
    echo -e "  ${GREEN}--force${NC}         Force deployment even with low balance"
    echo -e "  ${GREEN}--help${NC}          Show this help message"
    echo ""
    echo -e "${CYAN}Contract Verification:${NC}"
    echo -e "  • ${GREEN}Enabled by default${NC} for all networks except localhost"
    echo -e "  • Uploads source code to block explorer (BaseScan/Etherscan)"
    echo -e "  • Allows users to read contract code directly on the explorer"
    echo -e "  • Use ${YELLOW}--no-verify${NC} to skip verification (not recommended)"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  $0 base-sepolia                    # Deploy with verification"
    echo -e "  $0 base-sepolia --dry-run          # Preview deployment"
    echo -e "  $0 localhost --dry-run             # Test locally (no verification)"
    echo -e "  $0 base-sepolia --no-verify        # Deploy without verification (not recommended)"
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
    
    # Check for modular contract files
    if [ ! -f "$FOUNDRY_DIR/src/RemovalNinja.sol" ]; then
        echo -e "${RED}❌ RemovalNinja.sol contract not found.${NC}"
        exit 1
    fi
    
    if [ ! -f "$FOUNDRY_DIR/src/DataBrokerRegistryUltraSimple.sol" ]; then
        echo -e "${RED}❌ DataBrokerRegistryUltraSimple.sol contract not found.${NC}"
        exit 1
    fi
    
    if [ ! -f "$FOUNDRY_DIR/src/RemovalTaskFactoryUltraSimple.sol" ]; then
        echo -e "${RED}❌ RemovalTaskFactoryUltraSimple.sol contract not found.${NC}"
        exit 1
    fi
    
    if [ ! -f "$FOUNDRY_DIR/script/DeployBaseSepolia.s.sol" ]; then
        echo -e "${RED}❌ DeployBaseSepolia.s.sol deployment script not found.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Foundry setup verified${NC}"
}

check_environment_variables() {
    local network=$1
    local verify_enabled=$2
    echo -e "${BLUE}🔐 Checking environment variables for $network...${NC}"
    
    local env_file="$FOUNDRY_DIR/.env"
    local env_example="$FOUNDRY_DIR/.env.example"
    local missing_vars=()
    local has_errors=false
    
    # Check if .env file exists
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}❌ Environment file not found: $env_file${NC}"
        echo -e "${YELLOW}💡 Creating .env file template...${NC}"
        
        # Create .env.example if it doesn't exist
        if [ ! -f "$env_example" ]; then
            cat > "$env_example" << 'EOF'
# RemovalNinja Environment Configuration
# Copy this file to .env and configure your settings

# Private key for deployment (without 0x prefix)
# Generate a new one: cast wallet new
# WARNING: Never commit your actual private key to git!
PRIVATE_KEY=your_private_key_here

# Base Sepolia RPC URL (public endpoint)
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org

# Base Sepolia Block Explorer API Key (for contract verification)
# Get from: https://basescan.org/apis
BASESCAN_API_KEY=your_basescan_api_key_here

# Optional: Custom RPC endpoints for better performance
# Get from Alchemy: https://alchemy.com/
# ALCHEMY_BASE_SEPOLIA_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Optional: Ethereum Sepolia RPC (for testing)
# SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID

# Optional: Etherscan API Key (for Ethereum verification)
# ETHERSCAN_API_KEY=your_etherscan_api_key_here
EOF
        fi
        
        # Copy template to .env
        cp "$env_example" "$env_file"
        
        echo -e "${GREEN}✅ Created $env_file from template${NC}"
        echo -e "${YELLOW}⚠️  Please edit $env_file and configure your settings${NC}"
        echo -e "${CYAN}📝 Required configurations:${NC}"
        echo -e "   1. Set PRIVATE_KEY (generate with: cast wallet new)"
        echo -e "   2. Set BASESCAN_API_KEY (get from: https://basescan.org/apis)"
        echo -e "   3. Optionally set custom RPC URLs for better performance"
        echo ""
        exit 1
    fi
    
    # Source the environment file
    source "$env_file"
    
    # Check network-specific variables
    case $network in
        "base-sepolia")
            # Required variables for Base Sepolia
            if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "your_private_key_here" ]; then
                missing_vars+=("PRIVATE_KEY")
                has_errors=true
            fi
            
            if [ -z "$BASE_SEPOLIA_RPC_URL" ]; then
                missing_vars+=("BASE_SEPOLIA_RPC_URL")
                has_errors=true
            fi
            
            # API key required only if verification is enabled
            if [ "$verify_enabled" = true ]; then
                if [ -z "$BASESCAN_API_KEY" ] || [ "$BASESCAN_API_KEY" = "your_basescan_api_key_here" ]; then
                    missing_vars+=("BASESCAN_API_KEY")
                    has_errors=true
                fi
            fi
            ;;
        "base")
            # Required variables for Base Mainnet
            if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "your_private_key_here" ]; then
                missing_vars+=("PRIVATE_KEY")
                has_errors=true
            fi
            
            if [ -z "$BASE_RPC_URL" ]; then
                missing_vars+=("BASE_RPC_URL")
                has_errors=true
            fi
            
            # API key required only if verification is enabled
            if [ "$verify_enabled" = true ]; then
                if [ -z "$BASESCAN_API_KEY" ] || [ "$BASESCAN_API_KEY" = "your_basescan_api_key_here" ]; then
                    missing_vars+=("BASESCAN_API_KEY")
                    has_errors=true
                fi
            fi
            ;;
        "sepolia")
            if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "your_private_key_here" ]; then
                missing_vars+=("PRIVATE_KEY")
                has_errors=true
            fi
            
            if [ -z "$SEPOLIA_RPC_URL" ]; then
                missing_vars+=("SEPOLIA_RPC_URL")
                has_errors=true
            fi
            
            # API key required only if verification is enabled
            if [ "$verify_enabled" = true ]; then
                if [ -z "$ETHERSCAN_API_KEY" ] || [ "$ETHERSCAN_API_KEY" = "your_etherscan_api_key_here" ]; then
                    missing_vars+=("ETHERSCAN_API_KEY")
                    has_errors=true
                fi
            fi
            ;;
        "localhost")
            # Only private key needed for localhost
            if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "your_private_key_here" ]; then
                echo -e "${YELLOW}💡 Using default Anvil private key for localhost deployment${NC}"
                export PRIVATE_KEY="ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
            fi
            ;;
    esac
    
    # Display errors if any
    if [ "$has_errors" = true ]; then
        echo -e "${RED}❌ Missing or invalid environment variables:${NC}"
        echo ""
        
        for var in "${missing_vars[@]}"; do
            case $var in
                "PRIVATE_KEY")
                    echo -e "${RED}❌ PRIVATE_KEY${NC}"
                    echo -e "${CYAN}   How to fix:${NC}"
                    echo -e "   1. Generate a new wallet: ${YELLOW}cast wallet new${NC}"
                    echo -e "   2. Copy the private key (without 0x prefix)"
                    echo -e "   3. Set PRIVATE_KEY=your_private_key in $env_file"
                    echo -e "   4. Fund the wallet address with test ETH"
                    echo ""
                    ;;
                "BASE_SEPOLIA_RPC_URL")
                    echo -e "${RED}❌ BASE_SEPOLIA_RPC_URL${NC}"
                    echo -e "${CYAN}   How to fix:${NC}"
                    echo -e "   1. Use public RPC: ${YELLOW}https://sepolia.base.org${NC}"
                    echo -e "   2. Or get dedicated RPC from Alchemy: ${YELLOW}https://alchemy.com/${NC}"
                    echo -e "   3. Set BASE_SEPOLIA_RPC_URL=your_rpc_url in $env_file"
                    echo ""
                    ;;
                "BASESCAN_API_KEY")
                    echo -e "${RED}❌ BASESCAN_API_KEY${NC}"
                    echo -e "${CYAN}   How to fix:${NC}"
                    echo -e "   1. Go to: ${YELLOW}https://basescan.org/apis${NC}"
                    echo -e "   2. Create a free account"
                    echo -e "   3. Generate an API key"
                    echo -e "   4. Set BASESCAN_API_KEY=your_api_key in $env_file"
                    echo -e "   ${YELLOW}Note: Required for contract verification (enabled by default)${NC}"
                    echo -e "   ${CYAN}Alternative: Use --no-verify to skip verification${NC}"
                    echo ""
                    ;;
                "SEPOLIA_RPC_URL")
                    echo -e "${RED}❌ SEPOLIA_RPC_URL${NC}"
                    echo -e "${CYAN}   How to fix:${NC}"
                    echo -e "   1. Get free RPC from Infura: ${YELLOW}https://infura.io/${NC}"
                    echo -e "   2. Or use Alchemy: ${YELLOW}https://alchemy.com/${NC}"
                    echo -e "   3. Set SEPOLIA_RPC_URL=your_rpc_url in $env_file"
                    echo ""
                    ;;
                "ETHERSCAN_API_KEY")
                    echo -e "${RED}❌ ETHERSCAN_API_KEY${NC}"
                    echo -e "${CYAN}   How to fix:${NC}"
                    echo -e "   1. Go to: ${YELLOW}https://etherscan.io/apis${NC}"
                    echo -e "   2. Create a free account"
                    echo -e "   3. Generate an API key"
                    echo -e "   4. Set ETHERSCAN_API_KEY=your_api_key in $env_file"
                    echo -e "   ${YELLOW}Note: Required for contract verification (enabled by default)${NC}"
                    echo -e "   ${CYAN}Alternative: Use --no-verify to skip verification${NC}"
                    echo ""
                    ;;
            esac
        done
        
        echo -e "${YELLOW}💡 After updating $env_file, run the script again.${NC}"
        echo -e "${CYAN}📖 For detailed setup instructions, see: README.md${NC}"
        exit 1
    fi
    
    # Validate private key format
    if [ "$network" != "localhost" ]; then
        PRIVATE_KEY=${PRIVATE_KEY#0x}  # Remove 0x prefix if present
        if [[ ! "$PRIVATE_KEY" =~ ^[0-9a-fA-F]{64}$ ]]; then
            echo -e "${RED}❌ Invalid PRIVATE_KEY format${NC}"
            echo -e "${CYAN}   Expected: 64-character hexadecimal string (without 0x prefix)${NC}"
            echo -e "${CYAN}   Generate new key: ${YELLOW}cast wallet new${NC}"
            exit 1
        fi
    fi
    
    # Get address from private key
    ADDRESS=$(cast wallet address --private-key "$PRIVATE_KEY")
    
    echo -e "${GREEN}✅ Environment variables validated${NC}"
    echo -e "${CYAN}📋 Deployment Address: ${GREEN}$ADDRESS${NC}"
}

generate_or_load_key() {
    echo -e "${BLUE}🔑 Using private key from environment...${NC}"
    
    # Private key should already be loaded from environment check
    if [ -z "$PRIVATE_KEY" ]; then
        echo -e "${RED}❌ Private key not found in environment${NC}"
        exit 1
    fi
    
    # Remove 0x prefix if present
    PRIVATE_KEY=${PRIVATE_KEY#0x}
    
    # Get the address
    ADDRESS=$(cast wallet address --private-key "$PRIVATE_KEY")
    
    echo -e "${GREEN}✅ Deployment key ready${NC}"
    echo -e "${CYAN}📋 Deployment Address: ${GREEN}$ADDRESS${NC}"
}

check_balance() {
    local network=$1
    local rpc_url=${NETWORKS[$network]}
    local min_balance=${MIN_BALANCES[$network]}
    
    # Use environment variable RPC URLs if available
    case $network in
        "base-sepolia")
            if [ -n "$BASE_SEPOLIA_RPC_URL" ]; then
                rpc_url="$BASE_SEPOLIA_RPC_URL"
            fi
            ;;
        "base")
            if [ -n "$BASE_RPC_URL" ]; then
                rpc_url="$BASE_RPC_URL"
            fi
            ;;
        "sepolia")
            if [ -n "$SEPOLIA_RPC_URL" ]; then
                rpc_url="$SEPOLIA_RPC_URL"
            fi
            ;;
    esac
    
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
    
    # Use environment variable RPC URLs if available
    case $network in
        "base-sepolia")
            if [ -n "$BASE_SEPOLIA_RPC_URL" ]; then
                rpc_url="$BASE_SEPOLIA_RPC_URL"
            fi
            ;;
        "base")
            if [ -n "$BASE_RPC_URL" ]; then
                rpc_url="$BASE_RPC_URL"
            fi
            ;;
        "sepolia")
            if [ -n "$SEPOLIA_RPC_URL" ]; then
                rpc_url="$SEPOLIA_RPC_URL"
            fi
            ;;
    esac
    
    echo -e "${BLUE}🚀 Deploying contracts to $network...${NC}"
    echo -e "${CYAN}📡 RPC URL: $rpc_url${NC}"
    echo -e "${CYAN}🔗 Chain ID: $chain_id${NC}"
    echo -e "${CYAN}🔍 Explorer: $explorer${NC}"
    
    cd "$FOUNDRY_DIR"
    
    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}🔍 DRY RUN MODE - No actual deployment${NC}"
        echo -e "${CYAN}Would deploy RemovalNinja modular system with:${NC}"
        echo -e "  Network: $network"
        echo -e "  RPC: $rpc_url"
        echo -e "  Deployer: $ADDRESS"
        echo -e "  Contracts: Token + Registry + TaskFactory"
        if [ "$verify_flag" = true ] && [ "$network" != "localhost" ]; then
            echo -e "  Verification: ${GREEN}Enabled${NC} (source code will be uploaded to block explorer)"
        else
            echo -e "  Verification: ${YELLOW}Disabled${NC}"
        fi
        return 0
    fi
    
    # Create deployment command for modular system
    local deploy_script="script/DeployBaseSepolia.s.sol:DeployBaseSepolia"
    
    # Use appropriate deployment script based on network
    case $network in
        "base-sepolia")
            deploy_script="script/DeployBaseSepolia.s.sol:DeployBaseSepolia"
            ;;
        "localhost")
            deploy_script="script/DeployUltraSimple.s.sol:DeployUltraSimple"
            ;;
        *)
            # For other networks, use the Base Sepolia script as template
            deploy_script="script/DeployBaseSepolia.s.sol:DeployBaseSepolia"
            ;;
    esac
    
    local deploy_cmd="forge script $deploy_script --rpc-url $rpc_url --private-key $PRIVATE_KEY --broadcast"
    
    if [ "$verify_flag" = true ] && [ "$network" != "localhost" ]; then
        if [ "$network" = "base-sepolia" ] || [ "$network" = "base" ]; then
            deploy_cmd="$deploy_cmd --verify --etherscan-api-key $BASESCAN_API_KEY"
        else
            deploy_cmd="$deploy_cmd --verify --etherscan-api-key $ETHERSCAN_API_KEY"
        fi
    fi
    
    echo -e "${BLUE}📡 Executing deployment...${NC}"
    
    # Execute deployment
    if eval "$deploy_cmd"; then
        echo -e "${GREEN}✅ Deployment successful!${NC}"
        
        # Update contracts.txt with deployment info
        echo "# RemovalNinja Modular Contract Deployments" > "$CONTRACTS_FILE"
        echo "# Generated on $(date)" >> "$CONTRACTS_FILE"
        echo "" >> "$CONTRACTS_FILE"
        
        # Try to extract contract addresses from deployment output
        local deployment_json=""
        if [ -f "deployment-base-sepolia.json" ]; then
            deployment_json="deployment-base-sepolia.json"
        elif [ -f "deployment-localhost.json" ]; then
            deployment_json="deployment-localhost.json" 
        fi
        
        if [ -n "$deployment_json" ] && [ -f "$deployment_json" ]; then
            echo -e "${GREEN}📋 Extracting contract addresses from $deployment_json...${NC}"
            
            # Parse contract addresses from JSON
            TOKEN_ADDRESS=$(jq -r '.contracts.RemovalNinja // empty' "$deployment_json" 2>/dev/null)
            REGISTRY_ADDRESS=$(jq -r '.contracts.DataBrokerRegistry // empty' "$deployment_json" 2>/dev/null)
            FACTORY_ADDRESS=$(jq -r '.contracts.TaskFactory // empty' "$deployment_json" 2>/dev/null)
            
            # Write to contracts.txt
            echo "[$network]" >> "$CONTRACTS_FILE"
            if [ -n "$TOKEN_ADDRESS" ] && [ "$TOKEN_ADDRESS" != "null" ]; then
                echo "RemovalNinja_Token = $TOKEN_ADDRESS" >> "$CONTRACTS_FILE"
            fi
            if [ -n "$REGISTRY_ADDRESS" ] && [ "$REGISTRY_ADDRESS" != "null" ]; then
                echo "DataBroker_Registry = $REGISTRY_ADDRESS" >> "$CONTRACTS_FILE"
            fi
            if [ -n "$FACTORY_ADDRESS" ] && [ "$FACTORY_ADDRESS" != "null" ]; then
                echo "Task_Factory = $FACTORY_ADDRESS" >> "$CONTRACTS_FILE"
            fi
            echo "Explorer_Base = $explorer/address/" >> "$CONTRACTS_FILE"
            echo "Deployer = $ADDRESS" >> "$CONTRACTS_FILE"
            echo "Timestamp = $(date -Iseconds)" >> "$CONTRACTS_FILE"
            echo "" >> "$CONTRACTS_FILE"
            
            # Display contract addresses
            echo -e "${GREEN}📋 Deployed Contract Addresses:${NC}"
            if [ -n "$TOKEN_ADDRESS" ] && [ "$TOKEN_ADDRESS" != "null" ]; then
                echo -e "${CYAN}   Token (RN):     $TOKEN_ADDRESS${NC}"
                echo -e "${CYAN}   Explorer:       $explorer/address/$TOKEN_ADDRESS${NC}"
            fi
            if [ -n "$REGISTRY_ADDRESS" ] && [ "$REGISTRY_ADDRESS" != "null" ]; then
                echo -e "${CYAN}   Registry:       $REGISTRY_ADDRESS${NC}"
                echo -e "${CYAN}   Explorer:       $explorer/address/$REGISTRY_ADDRESS${NC}"
            fi
            if [ -n "$FACTORY_ADDRESS" ] && [ "$FACTORY_ADDRESS" != "null" ]; then
                echo -e "${CYAN}   Factory:        $FACTORY_ADDRESS${NC}"
                echo -e "${CYAN}   Explorer:       $explorer/address/$FACTORY_ADDRESS${NC}"
            fi
        else
            # Try to get from broadcast logs
            local script_name="DeployBaseSepolia.s.sol"
            if [ "$network" = "localhost" ]; then
                script_name="DeployUltraSimple.s.sol"
            fi
            
            BROADCAST_DIR="broadcast/$script_name/$chain_id"
            if [ -d "$BROADCAST_DIR" ]; then
                LATEST_RUN=$(ls -t "$BROADCAST_DIR" | head -n1)
                if [ -f "$BROADCAST_DIR/$LATEST_RUN" ]; then
                    echo -e "${YELLOW}⚠️  Extracting from broadcast logs (JSON file not found)...${NC}"
                    
                    # Extract all CREATE transactions
                    ADDRESSES=$(jq -r '.transactions[] | select(.transactionType == "CREATE") | .contractAddress' "$BROADCAST_DIR/$LATEST_RUN" 2>/dev/null || echo "")
                    
                    if [ -n "$ADDRESSES" ]; then
                        echo "[$network]" >> "$CONTRACTS_FILE"
                        echo "# Contract addresses from broadcast logs" >> "$CONTRACTS_FILE"
                        local i=1
                        for addr in $ADDRESSES; do
                            echo "Contract_$i = $addr" >> "$CONTRACTS_FILE"
                            echo -e "${CYAN}   Contract $i:    $addr${NC}"
                            echo -e "${CYAN}   Explorer:       $explorer/address/$addr${NC}"
                            i=$((i + 1))
                        done
                        echo "Deployer = $ADDRESS" >> "$CONTRACTS_FILE"
                        echo "Timestamp = $(date -Iseconds)" >> "$CONTRACTS_FILE"
                        echo "" >> "$CONTRACTS_FILE"
                    fi
                fi
            fi
            
            if [ -z "$ADDRESSES" ]; then
                echo -e "${YELLOW}⚠️  Could not extract contract addresses from deployment logs${NC}"
                echo -e "${CYAN}💡 Check the console output above for contract addresses${NC}"
            fi
        fi
        
        # Update frontend configuration hint
        echo -e "${YELLOW}💡 Next steps:${NC}"
        echo -e "  1. Update client/src/config/contracts.ts with the new contract addresses"
        echo -e "  2. Switch ACTIVE_NETWORK to ${network^^} in contracts.ts"
        echo -e "  3. Test contract functions on the block explorer"
        echo -e "  4. Add network to MetaMask if needed"
        echo -e "  5. Get test tokens from faucet if required"
        echo -e "  6. Test wallet connection and contract interactions in your dApp"
        echo ""
        echo -e "${CYAN}📝 Frontend configuration example:${NC}"
        if [ -n "$TOKEN_ADDRESS" ] && [ "$TOKEN_ADDRESS" != "null" ]; then
            echo -e "  REMOVAL_NINJA_TOKEN: { address: \"$TOKEN_ADDRESS\" }"
        fi
        if [ -n "$REGISTRY_ADDRESS" ] && [ "$REGISTRY_ADDRESS" != "null" ]; then
            echo -e "  DATA_BROKER_REGISTRY: { address: \"$REGISTRY_ADDRESS\" }"
        fi
        if [ -n "$FACTORY_ADDRESS" ] && [ "$FACTORY_ADDRESS" != "null" ]; then
            echo -e "  TASK_FACTORY: { address: \"$FACTORY_ADDRESS\" }"
        fi
        
    else
        echo -e "${RED}❌ Deployment failed!${NC}"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
}

main() {
    # Parse arguments
    local network=""
    local verify_flag=true  # Enable verification by default
    local dry_run=false
    local force=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-verify)
                verify_flag=false
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
            # Legacy support for --verify (now default)
            --verify)
                verify_flag=true
                echo -e "${YELLOW}💡 Note: Verification is now enabled by default. Use --no-verify to disable.${NC}"
                shift
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
    if [ "$verify_flag" = true ] && [ "$network" != "localhost" ]; then
        echo -e "${CYAN}🔍 Contract Verification: ${GREEN}Enabled${NC} (source code will be uploaded to block explorer)"
    else
        echo -e "${CYAN}🔍 Contract Verification: ${YELLOW}Disabled${NC}"
    fi
    echo ""
    
    # Run checks
    check_dependencies
    check_foundry_setup
    check_environment_variables "$network" "$verify_flag"
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
    
    echo -e "${GREEN}🎉 RemovalNinja Modular System deployment completed successfully! 🥷${NC}"
    echo -e "${GREEN}✅ Deployed: Token + Registry + TaskFactory${NC}"
    echo -e "${CYAN}📚 Check contracts.txt for complete deployment info${NC}"
}

# Run main function with all arguments
main "$@"
