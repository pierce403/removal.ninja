// Contract configuration for RemovalNinja modular protocol

// Thirdweb configuration
export const THIRDWEB_CLIENT_ID = "f527a70b19f540f6574f9071aab31da1";

// Contract addresses for different networks
export const CONTRACTS = {
  LOCALHOST: {
    REMOVAL_NINJA_TOKEN: {
      address: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
      abi: [], // Will be populated with contract ABI
    },
    DATA_BROKER_REGISTRY: {
      address: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", 
      abi: [], // Will be populated with contract ABI
    },
    TASK_FACTORY: {
      address: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
      abi: [], // Will be populated with contract ABI
    },
    SIMPLE_DEX: {
      address: "0x0000000000000000000000000000000000000000", // Not deployed on localhost yet
      abi: [], // Will be populated with contract ABI
    },
  },
    BASE_SEPOLIA: {
      REMOVAL_NINJA_TOKEN: {
        address: "0xA7b02F76D863b9467eCd80Eab3b9fd6aCe18200A", // Deployed Sept 23, 2025
        abi: [],
      },
      DATA_BROKER_REGISTRY: {
        address: "0xC3760343D798f7A3DA9FCa33DBD725f7b3246760", // Deployed Sept 23, 2025
        abi: [],
      },
      TASK_FACTORY: {
        address: "0x6e7eF8A7B0219C0acE923dc9a0f76bBa65273Ef7", // Deployed Sept 23, 2025
        abi: [],
      },
      SIMPLE_DEX: {
        address: "0x8936a4c0257C302d05cddf4ECeA7cC347AC63ccd", // Deployed Sept 23, 2025
        abi: [],
      },
    },
} as const;

// Network configuration
export const SUPPORTED_NETWORKS = {
  LOCALHOST: {
    chainId: 31337,
    name: "Localhost",
    rpcUrl: "http://127.0.0.1:8545",
    blockExplorer: "http://localhost:8545",
    nativeCurrency: {
      name: "Ethereum",
      symbol: "ETH", 
      decimals: 18,
    },
  },
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

// Current active network (switch to BASE_SEPOLIA for production testing)
export const ACTIVE_NETWORK = SUPPORTED_NETWORKS.BASE_SEPOLIA;

// Get contracts for current network
const getCurrentNetworkContracts = () => {
  // Use type assertion to handle compile-time chain ID comparison
  const activeChainId = ACTIVE_NETWORK.chainId as number;
  const localhostChainId = SUPPORTED_NETWORKS.LOCALHOST.chainId;
  const isLocalhost = activeChainId === localhostChainId;
  return isLocalhost ? CONTRACTS.LOCALHOST : CONTRACTS.BASE_SEPOLIA;
};

// Contract addresses for current network
export const CONTRACT_ADDRESSES = {
  REMOVAL_NINJA_TOKEN: getCurrentNetworkContracts().REMOVAL_NINJA_TOKEN.address,
  DATA_BROKER_REGISTRY: getCurrentNetworkContracts().DATA_BROKER_REGISTRY.address,
  TASK_FACTORY: getCurrentNetworkContracts().TASK_FACTORY.address,
  SIMPLE_DEX: getCurrentNetworkContracts().SIMPLE_DEX.address,
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
export const getContractAddress = (contractName: keyof typeof CONTRACT_ADDRESSES): string => {
  const address = CONTRACT_ADDRESSES[contractName];
  
  if (address.toLowerCase() === "0x0000000000000000000000000000000000000000") {
    console.warn(`⚠️  ${contractName} address not configured. Please deploy and update config/contracts.ts`);
  }
  
  return address;
};

// Helper functions for each contract
export const getTokenAddress = () => getContractAddress('REMOVAL_NINJA_TOKEN');
export const getRegistryAddress = () => getContractAddress('DATA_BROKER_REGISTRY');
export const getFactoryAddress = () => getContractAddress('TASK_FACTORY');
export const getDexAddress = () => getContractAddress('SIMPLE_DEX');

// Helper function to validate network
export const isValidNetwork = (chainId: number): boolean => {
  return chainId === ACTIVE_NETWORK.chainId;
};

// Network switch helpers
export const addNetworkToWallet = async (networkKey: keyof typeof SUPPORTED_NETWORKS) => {
  const network = SUPPORTED_NETWORKS[networkKey];
  
  if (typeof window.ethereum !== 'undefined') {
    try {
      await window.ethereum.request({
        method: 'wallet_addEthereumChain',
        params: [
          {
            chainId: `0x${network.chainId.toString(16)}`,
            chainName: network.name,
            rpcUrls: [network.rpcUrl],
            nativeCurrency: network.nativeCurrency,
            blockExplorerUrls: [network.blockExplorer],
          },
        ],
      });
    } catch (error) {
      console.error(`Failed to add ${network.name} network:`, error);
    }
  }
};

// Convenience functions
export const addBaseSepoliaNetwork = () => addNetworkToWallet('BASE_SEPOLIA');
export const addLocalhostNetwork = () => addNetworkToWallet('LOCALHOST');

// Check if we're in development mode
export const isDevelopment = () => {
  const activeChainId = ACTIVE_NETWORK.chainId as number;
  const localhostChainId = SUPPORTED_NETWORKS.LOCALHOST.chainId;
  return activeChainId === localhostChainId;
};
