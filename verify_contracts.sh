#!/bin/bash

# RemovalNinja Contract Verification Script
# Verifies all deployed contracts on Base Sepolia

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Contract addresses from Base Sepolia deployment
TOKEN_ADDRESS="0xC3760343D798f7A3DA9FCa33DBD725f7b3246760"
REGISTRY_ADDRESS="0xA7b02F76D863b9467eCd80Eab3b9fd6aCe18200A"
FACTORY_ADDRESS="0x6e7eF8A7B0219C0acE923dc9a0f76bBa65273Ef7"

# Network configuration
NETWORK="base-sepolia"
FOUNDRY_DIR="foundry"

print_header() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🥷 RemovalNinja Contract Verification 🥷                  ║"
    echo "║                        Base Sepolia Contract Verification                     ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_dependencies() {
    echo -e "${BLUE}🔍 Checking dependencies...${NC}"
    
    # Check if we're in the right directory
    if [ ! -d "$FOUNDRY_DIR" ]; then
        echo -e "${RED}❌ Foundry directory not found. Please run from project root.${NC}"
        exit 1
    fi
    
    # Check if forge is installed
    if ! command -v forge &> /dev/null; then
        echo -e "${RED}❌ Forge not found. Please install Foundry.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Dependencies check passed${NC}"
}

check_environment() {
    echo -e "${BLUE}🔐 Checking environment variables...${NC}"
    
    local env_file="$FOUNDRY_DIR/.env"
    
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}❌ Environment file not found: $env_file${NC}"
        exit 1
    fi
    
    # Source the environment file
    source "$env_file"
    
    if [ -z "$BASESCAN_API_KEY" ] || [ "$BASESCAN_API_KEY" = "your_basescan_api_key_here" ]; then
        echo -e "${RED}❌ BASESCAN_API_KEY not configured${NC}"
        echo -e "${CYAN}   How to fix:${NC}"
        echo -e "   1. Go to: ${YELLOW}https://basescan.org/apis${NC}"
        echo -e "   2. Create a free account"
        echo -e "   3. Generate an API key"
        echo -e "   4. Set BASESCAN_API_KEY=your_api_key in $env_file"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Environment variables validated${NC}"
}

verify_contract() {
    local contract_name=$1
    local address=$2
    local source_path=$3
    local constructor_args=$4
    
    echo -e "${BLUE}🔍 Verifying $contract_name at $address...${NC}"
    
    local cmd="forge verify-contract $address $source_path --chain $NETWORK --etherscan-api-key $BASESCAN_API_KEY"
    
    if [ -n "$constructor_args" ]; then
        cmd="$cmd --constructor-args $constructor_args"
    fi
    
    echo -e "${CYAN}   Command: $cmd${NC}"
    
    cd "$FOUNDRY_DIR"
    
    if eval "$cmd"; then
        echo -e "${GREEN}✅ $contract_name verified successfully${NC}"
        echo -e "${CYAN}🔗 View on BaseScan: https://sepolia.basescan.org/address/$address${NC}"
        return 0
    else
        echo -e "${RED}❌ $contract_name verification failed${NC}"
        return 1
    fi
    
    cd ..
}

verify_all_contracts() {
    echo -e "${BLUE}🚀 Starting contract verification...${NC}"
    echo -e "${CYAN}📡 Network: $NETWORK${NC}"
    echo -e "${CYAN}🔍 Explorer: https://sepolia.basescan.org${NC}"
    echo ""
    
    local success_count=0
    local total_count=3
    
    # 1. Verify RemovalNinja Token
    echo -e "${YELLOW}[1/3] RemovalNinja Token${NC}"
    if verify_contract "RemovalNinja Token" "$TOKEN_ADDRESS" "src/RemovalNinja.sol:RemovalNinja"; then
        ((success_count++))
    fi
    echo ""
    
    # 2. Verify DataBrokerRegistry
    echo -e "${YELLOW}[2/3] DataBrokerRegistry${NC}"
    if verify_contract "DataBrokerRegistry" "$REGISTRY_ADDRESS" "src/DataBrokerRegistryUltraSimple.sol:DataBrokerRegistryUltraSimple"; then
        ((success_count++))
    fi
    echo ""
    
    # 3. Verify TaskFactory (with constructor args)
    echo -e "${YELLOW}[3/3] TaskFactory${NC}"
    echo -e "${CYAN}   Generating constructor args...${NC}"
    local constructor_args=$(cast abi-encode "constructor(address,address)" "$TOKEN_ADDRESS" "$REGISTRY_ADDRESS")
    echo -e "${CYAN}   Constructor args: $constructor_args${NC}"
    
    if verify_contract "TaskFactory" "$FACTORY_ADDRESS" "src/RemovalTaskFactoryUltraSimple.sol:RemovalTaskFactoryUltraSimple" "$constructor_args"; then
        ((success_count++))
    fi
    echo ""
    
    # Summary
    echo -e "${BLUE}📊 Verification Summary${NC}"
    echo -e "${CYAN}   Successful: $success_count/$total_count${NC}"
    
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}🎉 All contracts verified successfully!${NC}"
        echo ""
        echo -e "${CYAN}🔗 Block Explorer Links:${NC}"
        echo -e "   Token: https://sepolia.basescan.org/address/$TOKEN_ADDRESS"
        echo -e "   Registry: https://sepolia.basescan.org/address/$REGISTRY_ADDRESS"
        echo -e "   Factory: https://sepolia.basescan.org/address/$FACTORY_ADDRESS"
        return 0
    else
        echo -e "${YELLOW}⚠️  Some contracts failed verification. You can retry later.${NC}"
        echo -e "${CYAN}💡 Tip: BaseScan may need more time to index the contracts.${NC}"
        return 1
    fi
}

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --retry        Retry verification (same as running without options)"
    echo ""
    echo "Examples:"
    echo "  $0              # Verify all contracts"
    echo "  $0 --retry      # Retry verification"
    echo ""
    echo "Contract Addresses:"
    echo "  Token:    $TOKEN_ADDRESS"
    echo "  Registry: $REGISTRY_ADDRESS" 
    echo "  Factory:  $FACTORY_ADDRESS"
}

main() {
    # Parse command line arguments
    case "${1:-}" in
        -h|--help)
            print_usage
            exit 0
            ;;
        --retry|"")
            # Default action - verify contracts
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
    
    print_header
    check_dependencies
    check_environment
    verify_all_contracts
    
    local exit_code=$?
    echo ""
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}🥷 Contract verification completed successfully!${NC}"
    else
        echo -e "${YELLOW}🔄 You can retry verification later with: ./verify_contracts.sh${NC}"
        echo -e "${CYAN}💡 Common issues:${NC}"
        echo -e "   - BaseScan needs more time to index contracts (wait 15-30 minutes)"
        echo -e "   - Network connectivity issues"
        echo -e "   - API rate limits"
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@"
