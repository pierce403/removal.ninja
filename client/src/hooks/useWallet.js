import React, { createContext, useContext, useState, useEffect } from 'react';
import { ethers } from 'ethers';
import toast from 'react-hot-toast';

const WalletContext = createContext();

export const useWallet = () => {
  const context = useContext(WalletContext);
  if (!context) {
    throw new Error('useWallet must be used within a WalletProvider');
  }
  return context;
};

export const WalletProvider = ({ children }) => {
  const [account, setAccount] = useState(null);
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contract, setContract] = useState(null);
  const [loading, setLoading] = useState(false);
  const [balance, setBalance] = useState('0');

  // Contract ABI and address will be set after deployment
  const contractABI = [
    // Add essential function signatures here
    "function balanceOf(address) view returns (uint256)",
    "function submitDataBroker(string,string,string)",
    "function registerAsProcessor(uint256,string)",
    "function stakeForRemovalList(uint256,address[])",
    "function requestRemoval(uint256)",
    "function processRemoval(uint256)",
    "function getActiveBrokers() view returns (uint256[])",
    "function dataBrokers(uint256) view returns (tuple(uint256,string,string,string,address,bool,uint256))",
    "function processors(address) view returns (tuple(address,uint256,bool,uint256,uint256,string))",
    "function users(address) view returns (tuple(address,uint256,bool))",
    "function getUserSelectedProcessors(address) view returns (address[])"
  ];

  const connectWallet = async () => {
    try {
      setLoading(true);
      
      if (!window.ethereum) {
        toast.error('MetaMask not found. Please install MetaMask.');
        return;
      }

      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      });

      if (accounts.length === 0) {
        toast.error('No accounts found');
        return;
      }

      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const account = accounts[0];

      setProvider(provider);
      setSigner(signer);
      setAccount(account);

      // Try to get contract address from server
      try {
        const response = await fetch('/api/blockchain/contract-info');
        const data = await response.json();
        
        if (data.contractAddress) {
          const contract = new ethers.Contract(data.contractAddress, contractABI, signer);
          setContract(contract);
          
          // Get token balance
          const balance = await contract.balanceOf(account);
          setBalance(ethers.formatEther(balance));
        }
      } catch (error) {
        console.warn('Contract not deployed yet:', error);
      }

      toast.success('Wallet connected successfully!');
    } catch (error) {
      console.error('Error connecting wallet:', error);
      toast.error('Failed to connect wallet');
    } finally {
      setLoading(false);
    }
  };

  const disconnectWallet = () => {
    setAccount(null);
    setProvider(null);
    setSigner(null);
    setContract(null);
    setBalance('0');
    toast.success('Wallet disconnected');
  };

  const updateBalance = async () => {
    if (contract && account) {
      try {
        const balance = await contract.balanceOf(account);
        setBalance(ethers.formatEther(balance));
      } catch (error) {
        console.error('Error updating balance:', error);
      }
    }
  };

  // Listen for account changes
  useEffect(() => {
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', (accounts) => {
        if (accounts.length === 0) {
          disconnectWallet();
        } else {
          setAccount(accounts[0]);
        }
      });

      window.ethereum.on('chainChanged', () => {
        window.location.reload();
      });
    }

    return () => {
      if (window.ethereum) {
        window.ethereum.removeAllListeners();
      }
    };
  }, []);

  const value = {
    account,
    provider,
    signer,
    contract,
    loading,
    balance,
    connectWallet,
    disconnectWallet,
    updateBalance
  };

  return (
    <WalletContext.Provider value={value}>
      {children}
    </WalletContext.Provider>
  );
};