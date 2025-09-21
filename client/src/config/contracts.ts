// Contract configuration for RemovalNinja protocol

// Base Sepolia Testnet Configuration
export const CONTRACTS = {
  BASE_SEPOLIA: {
    REMOVAL_NINJA: {
      // This will be updated after deployment to Base Sepolia
      address: "0x0000000000000000000000000000000000000000", // Replace with actual deployed address
      abi: [], // Will be populated with contract ABI
    },
  },
} as const;

// Network configuration
export const SUPPORTED_NETWORKS = {
  BASE_SEPOLIA: {
    chainId: 84532,
    name: "Base Sepolia",
    rpcUrl: "https://sepolia.base.org",
    blockExplorer: "https://sepolia.basescan.org",
    nativeCurrency: {
      name: "Ethereum",
      symbol: "ETH",
      decimals: 18,
    },
  },
} as const;

// Current active network
export const ACTIVE_NETWORK = SUPPORTED_NETWORKS.BASE_SEPOLIA;

// Contract addresses for current network
export const CONTRACT_ADDRESSES = {
  REMOVAL_NINJA: CONTRACTS.BASE_SEPOLIA.REMOVAL_NINJA.address,
} as const;

// Common contract constants
export const CONTRACT_CONSTANTS = {
  BROKER_SUBMISSION_REWARD: "100", // 100 RN tokens
  REMOVAL_PROCESSING_REWARD: "50", // 50 RN tokens
  MIN_USER_STAKE: "10", // 10 RN tokens
  MIN_PROCESSOR_STAKE: "1000", // 1,000 RN tokens
  SLASH_PERCENTAGE: 10, // 10% slashing
  MAX_SELECTED_PROCESSORS: 5, // Max processors a user can select
} as const;

// Environment-specific configuration
export const getContractAddress = (): string => {
  const address = CONTRACT_ADDRESSES.REMOVAL_NINJA;
  
  if (address === "0x0000000000000000000000000000000000000000") {
    console.warn("⚠️  Contract address not configured. Please deploy to Base Sepolia and update config/contracts.ts");
  }
  
  return address;
};

// Helper function to validate network
export const isValidNetwork = (chainId: number): boolean => {
  return chainId === ACTIVE_NETWORK.chainId;
};

// Network switch helper
export const addBaseSepoliaNetwork = async () => {
  if (typeof window.ethereum !== 'undefined') {
    try {
      await window.ethereum.request({
        method: 'wallet_addEthereumChain',
        params: [
          {
            chainId: `0x${ACTIVE_NETWORK.chainId.toString(16)}`,
            chainName: ACTIVE_NETWORK.name,
            rpcUrls: [ACTIVE_NETWORK.rpcUrl],
            nativeCurrency: ACTIVE_NETWORK.nativeCurrency,
            blockExplorerUrls: [ACTIVE_NETWORK.blockExplorer],
          },
        ],
      });
    } catch (error) {
      console.error('Failed to add Base Sepolia network:', error);
    }
  }
};
