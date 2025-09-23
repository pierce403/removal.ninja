import React, { useState } from 'react';
import { 
  useAddress, 
  useContract, 
  useContractRead, 
  useContractWrite 
} from '@thirdweb-dev/react';
import { getTokenAddress, getDexAddress } from '../config/contracts';

// Simple ABI for the token contract
const TOKEN_ABI = [
  "function name() view returns (string)",
  "function symbol() view returns (string)", 
  "function decimals() view returns (uint8)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address) view returns (uint256)",
  "function transfer(address to, uint256 amount) returns (bool)",
  "function approve(address spender, uint256 amount) returns (bool)",
  "function allowance(address owner, address spender) view returns (uint256)"
];

// SimpleDEX ABI for buying tokens
const DEX_ABI = [
  "function buyTokens() payable",
  "function getTokenPrice() view returns (uint256)",
  "function getAmountOut(uint256 amountIn, bool buyingTokens) view returns (uint256)",
  "function tokenReserves() view returns (uint256)",
  "function ethReserves() view returns (uint256)"
];

const TokenPage: React.FC = () => {
  const address = useAddress();
  const [buyAmount, setBuyAmount] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);

  // Token contract
  const { contract: tokenContract } = useContract(getTokenAddress(), TOKEN_ABI);
  
  // DEX contract
  const { contract: dexContract } = useContract(getDexAddress(), DEX_ABI);

  // Read token information
  const { data: tokenName } = useContractRead(tokenContract, "name");
  const { data: tokenSymbol } = useContractRead(tokenContract, "symbol");
  const { data: tokenDecimals } = useContractRead(tokenContract, "decimals");
  const { data: totalSupply } = useContractRead(tokenContract, "totalSupply");
  const { data: userBalance } = useContractRead(tokenContract, "balanceOf", [address]);

  // Read DEX information
  const { data: tokenPrice } = useContractRead(dexContract, "getTokenPrice");
  const { data: tokenReserves } = useContractRead(dexContract, "tokenReserves");
  const { data: ethReserves } = useContractRead(dexContract, "ethReserves");
  
  // Buy tokens from DEX
  const { mutateAsync: buyTokens, isLoading: isBuying } = useContractWrite(dexContract, "buyTokens");

  // Format token amounts
  const formatTokenAmount = (amount: any) => {
    if (!amount || !tokenDecimals) return '0';
    const divisor = Math.pow(10, tokenDecimals);
    return (Number(amount) / divisor).toLocaleString(undefined, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 6
    });
  };

  // Calculate expected token output
  const calculateTokenOutput = (ethInput: string): string => {
    if (!ethInput || !tokenReserves || !ethReserves || !tokenDecimals) return '0';
    
    try {
      const ethAmount = parseFloat(ethInput);
      const ethWei = BigInt(Math.floor(ethAmount * 1e18));
      const tokenRes = BigInt(tokenReserves.toString());
      const ethRes = BigInt(ethReserves.toString());
      
      // Constant product formula: (ethInput * tokenReserves) / (ethReserves + ethInput)
      const tokenOutput = (ethWei * tokenRes) / (ethRes + ethWei);
      const tokenAmount = Number(tokenOutput) / Math.pow(10, tokenDecimals);
      
      return tokenAmount.toLocaleString(undefined, {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2
      });
    } catch (error) {
      return '0';
    }
  };

  const handleBuyToken = async () => {
    if (!buyAmount || !address || !dexContract) return;
    
    setLoading(true);
    try {
      const ethAmount = parseFloat(buyAmount);
      if (ethAmount <= 0) {
        alert('Please enter a valid ETH amount');
        return;
      }

      // Call the buyTokens function with ETH value
      await buyTokens({
        overrides: {
          value: Math.floor(ethAmount * 1e18).toString()
        }
      });
      
      alert('Tokens purchased successfully!');
      setBuyAmount('');
    } catch (error) {
      console.error('Error buying tokens:', error);
      alert('Error buying tokens. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            🥷 {tokenName || 'RemovalNinja'} Token
          </h1>
          <p className="text-lg text-gray-600">
            The utility token powering decentralized data removal
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Token Information */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <h2 className="text-xl font-semibold text-gray-900 mb-6">Token Information</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Basic Info */}
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-500">Name</label>
                    <p className="text-lg font-semibold text-gray-900">{tokenName || 'Loading...'}</p>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-500">Symbol</label>
                    <p className="text-lg font-semibold text-gray-900">{tokenSymbol || 'Loading...'}</p>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-500">Decimals</label>
                    <p className="text-lg font-semibold text-gray-900">{tokenDecimals?.toString() || 'Loading...'}</p>
                  </div>
                </div>

                {/* Supply Info */}
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-500">Total Supply</label>
                    <p className="text-lg font-semibold text-gray-900">
                      {formatTokenAmount(totalSupply)} {tokenSymbol}
                    </p>
                  </div>
                  
                  {address && (
                    <div>
                      <label className="block text-sm font-medium text-gray-500">Your Balance</label>
                      <p className="text-lg font-semibold text-green-600">
                        {formatTokenAmount(userBalance)} {tokenSymbol}
                      </p>
                    </div>
                  )}
                </div>
              </div>

              {/* Contract Address */}
              <div className="mt-6 pt-6 border-t border-gray-200">
                <label className="block text-sm font-medium text-gray-500 mb-2">Contract Address</label>
                <div className="flex items-center space-x-2">
                  <code className="bg-gray-100 px-3 py-2 rounded-md text-sm font-mono text-gray-800 flex-1">
                    {getTokenAddress()}
                  </code>
                  <a
                    href={`https://sepolia.basescan.org/address/${getTokenAddress()}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center px-3 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                  >
                    View on BaseScan
                  </a>
                </div>
              </div>
            </div>

            {/* Token Utility */}
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mt-6">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Token Utility</h2>
              <div className="space-y-4">
                <div className="flex items-start space-x-3">
                  <div className="flex-shrink-0 w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                  <div>
                    <h3 className="font-medium text-gray-900">Removal Task Payments</h3>
                    <p className="text-gray-600">Pay workers and verifiers for completing data removal requests</p>
                  </div>
                </div>
                
                <div className="flex items-start space-x-3">
                  <div className="flex-shrink-0 w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                  <div>
                    <h3 className="font-medium text-gray-900">Staking Rewards</h3>
                    <p className="text-gray-600">Stake tokens to become a trusted data removal processor</p>
                  </div>
                </div>
                
                <div className="flex items-start space-x-3">
                  <div className="flex-shrink-0 w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                  <div>
                    <h3 className="font-medium text-gray-900">Governance</h3>
                    <p className="text-gray-600">Participate in protocol governance and broker verification</p>
                  </div>
                </div>
                
                <div className="flex items-start space-x-3">
                  <div className="flex-shrink-0 w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                  <div>
                    <h3 className="font-medium text-gray-900">Data Broker Submissions</h3>
                    <p className="text-gray-600">Earn rewards for submitting verified data broker information</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Buy Token */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 sticky top-8">
              <h2 className="text-xl font-semibold text-gray-900 mb-6">Buy RN Tokens</h2>
              
              {!address ? (
                <div className="text-center">
                  <p className="text-gray-600 mb-4">Connect your wallet to buy tokens</p>
                  <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <p className="text-sm text-blue-800">
                      Connect with MetaMask to access token purchase functionality
                    </p>
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Amount (ETH)
                    </label>
                    <input
                      type="number"
                      step="0.001"
                      min="0"
                      placeholder="0.1"
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      value={buyAmount}
                      onChange={(e) => setBuyAmount(e.target.value)}
                    />
                  </div>
                  
                  <div className="bg-gray-50 rounded-lg p-4">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">You pay:</span>
                      <span className="font-medium">{buyAmount || '0'} ETH</span>
                    </div>
                    <div className="flex justify-between text-sm mt-1">
                      <span className="text-gray-600">You receive:</span>
                      <span className="font-medium text-green-600">
                        ~{calculateTokenOutput(buyAmount)} {tokenSymbol || 'RN'}
                      </span>
                    </div>
                    {tokenPrice && (
                      <div className="flex justify-between text-xs mt-2 pt-2 border-t border-gray-200">
                        <span className="text-gray-500">Current price:</span>
                        <span className="text-gray-700">
                          {(Number(tokenPrice) / 1e18).toFixed(8)} ETH per {tokenSymbol}
                        </span>
                      </div>
                    )}
                  </div>
                  
                  <button
                    onClick={handleBuyToken}
                    disabled={!buyAmount || loading || isBuying || !tokenReserves}
                    className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {loading || isBuying ? 'Processing...' : 'Buy RN Tokens'}
                  </button>
                  
                  {tokenReserves && ethReserves ? (
                    <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                      <p className="text-sm text-green-800">
                        <strong>✅ Live Trading:</strong> Liquidity pool is active with{' '}
                        {formatTokenAmount(tokenReserves)} RN and{' '}
                        {(Number(ethReserves) / 1e18).toFixed(2)} ETH
                      </p>
                    </div>
                  ) : (
                    <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                      <p className="text-sm text-yellow-800">
                        <strong>Note:</strong> Loading liquidity pool information...
                      </p>
                    </div>
                  )}
                </div>
              )}

              {/* Quick Stats */}
              <div className="mt-6 pt-6 border-t border-gray-200">
                <h3 className="text-sm font-medium text-gray-900 mb-3">Quick Stats</h3>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Network:</span>
                    <span className="font-medium">Base Sepolia</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Standard:</span>
                    <span className="font-medium">ERC-20</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Liquidity:</span>
                    <span className={`font-medium ${tokenReserves ? 'text-green-600' : 'text-orange-600'}`}>
                      {tokenReserves ? 'Active' : 'Loading...'}
                    </span>
                  </div>
                  {tokenReserves && (
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">DEX Address:</span>
                      <a
                        href={`https://sepolia.basescan.org/address/${getDexAddress()}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="font-medium text-blue-600 hover:text-blue-800 text-xs"
                      >
                        {getDexAddress().slice(0, 6)}...{getDexAddress().slice(-4)}
                      </a>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TokenPage;
