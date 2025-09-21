import React, { useState } from 'react';
import { useAddress } from '@thirdweb-dev/react';
import XmtpMessageSection from '../components/XmtpMessageSection';

interface Processor {
  address: string;
  name: string;
  description: string;
  active: boolean;
  reputation: number;
  completedRemovals: number;
}

interface UserStakeInfo {
  isStaked: boolean;
  stakeAmount: string;
  selectedProcessors: string[];
  removalsRequested: number;
  removalsCompleted: number;
}

// Mock data for development
const mockProcessors: Processor[] = [
  {
    address: '0x1234567890123456789012345678901234567890',
    name: 'PrivacyPro Services',
    description: 'Professional data removal service with 99% success rate',
    active: true,
    reputation: 98,
    completedRemovals: 1250
  },
  {
    address: '0x2345678901234567890123456789012345678901',
    name: 'FastRemoval Inc',
    description: 'Quick turnaround removal processing within 48 hours',
    active: true,
    reputation: 95,
    completedRemovals: 876
  },
  {
    address: '0x3456789012345678901234567890123456789012',
    name: 'SecureData Removals',
    description: 'Security-focused removal service with encrypted processing',
    active: true,
    reputation: 97,
    completedRemovals: 1543
  }
];

const UserDashboard: React.FC = () => {
  const address = useAddress();
  const [staking, setStaking] = useState(false);
  const [stakeAmount, setStakeAmount] = useState('10');
  const [selectedProcessors, setSelectedProcessors] = useState<string[]>([]);
  const [userInfo] = useState<UserStakeInfo>({
    isStaked: false,
    stakeAmount: '0',
    selectedProcessors: [],
    removalsRequested: 0,
    removalsCompleted: 0
  });

  const formatAddress = (address: string): string => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  const handleProcessorSelection = (processorAddress: string) => {
    setSelectedProcessors(prev => {
      if (prev.includes(processorAddress)) {
        return prev.filter(addr => addr !== processorAddress);
      } else {
        return [...prev, processorAddress];
      }
    });
  };

  const handleStakeForRemoval = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!address) {
      alert('Please connect your wallet first');
      return;
    }

    if (selectedProcessors.length === 0) {
      alert('Please select at least one processor');
      return;
    }

    if (parseFloat(stakeAmount) < 10) {
      alert('Minimum stake amount is 10 RN tokens');
      return;
    }

    setStaking(true);
    try {
      // TODO: Integrate with smart contract
      console.log('Staking for removal:', {
        amount: stakeAmount,
        processors: selectedProcessors
      });
      alert(`Would stake ${stakeAmount} RN tokens and select ${selectedProcessors.length} processors for data removal`);
    } catch (error) {
      console.error('Error staking:', error);
      alert('Error staking tokens');
    } finally {
      setStaking(false);
    }
  };

  if (!address) {
    return (
      <div className="card text-center">
        <h1 className="text-2xl font-bold mb-4">User Dashboard</h1>
        <p className="text-gray-600 mb-6">
          Connect your wallet to access your privacy dashboard and manage data removal requests.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">User Dashboard</h1>
        <p className="text-gray-600 mt-2">
          Manage your data removal requests and processor preferences
        </p>
      </div>

      {/* User Status */}
      <div className="grid grid-2 gap-6">
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Your Status</h2>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-600">Wallet Address:</span>
              <span className="font-mono">{formatAddress(address)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Staking Status:</span>
              <span className={`status-badge ${userInfo.isStaked ? 'status-active' : 'status-pending'}`}>
                {userInfo.isStaked ? 'Staked' : 'Not Staked'}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Stake Amount:</span>
              <span className="font-semibold">{userInfo.stakeAmount} RN</span>
            </div>
          </div>
        </div>

        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Removal Stats</h2>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-600">Requests Submitted:</span>
              <span className="font-semibold">{userInfo.removalsRequested}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Completed Removals:</span>
              <span className="font-semibold text-green-600">{userInfo.removalsCompleted}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Success Rate:</span>
              <span className="font-semibold">
                {userInfo.removalsRequested > 0 
                  ? `${Math.round((userInfo.removalsCompleted / userInfo.removalsRequested) * 100)}%`
                  : 'N/A'
                }
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Stake for Removal */}
      {!userInfo.isStaked && (
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Stake for Data Removal</h2>
          <p className="text-gray-600 mb-6">
            Stake RN tokens to join the removal list and select trusted processors
            to handle your sensitive information.
          </p>

          <form onSubmit={handleStakeForRemoval} className="space-y-6">
            <div className="form-group">
              <label className="form-label">Stake Amount (minimum 10 RN)</label>
              <input
                type="number"
                value={stakeAmount}
                onChange={(e) => setStakeAmount(e.target.value)}
                className="form-input"
                min="10"
                step="1"
                required
              />
              <p className="text-sm text-gray-500 mt-1">
                Higher stake amounts may receive priority processing
              </p>
            </div>

            <div className="form-group">
              <label className="form-label">Select Trusted Processors</label>
              <p className="text-sm text-gray-600 mb-4">
                Choose processors you trust with your personal information. 
                You can select multiple processors for redundancy.
              </p>
              
              <div className="space-y-3">
                {mockProcessors.map((processor) => (
                  <div 
                    key={processor.address}
                    className={`border rounded-lg p-4 cursor-pointer transition-colors ${
                      selectedProcessors.includes(processor.address)
                        ? 'border-ninja-500 bg-ninja-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                    onClick={() => handleProcessorSelection(processor.address)}
                  >
                    <div className="flex items-start gap-3">
                      <input
                        type="checkbox"
                        checked={selectedProcessors.includes(processor.address)}
                        onChange={() => handleProcessorSelection(processor.address)}
                        className="mt-1"
                      />
                      <div className="flex-1">
                        <div className="flex justify-between items-start mb-2">
                          <h3 className="font-semibold">{processor.name}</h3>
                          <div className="flex gap-2">
                            <span className="status-badge status-active">
                              {processor.reputation}% reputation
                            </span>
                          </div>
                        </div>
                        <p className="text-gray-600 text-sm mb-2">{processor.description}</p>
                        <div className="flex justify-between text-sm text-gray-500">
                          <span>{formatAddress(processor.address)}</span>
                          <span>{processor.completedRemovals} completed removals</span>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <button
              type="submit"
              disabled={staking || selectedProcessors.length === 0}
              className="btn w-full flex items-center justify-center gap-2"
            >
              {staking && <div className="loading"></div>}
              Stake {stakeAmount} RN Tokens
            </button>
          </form>
        </div>
      )}

      <XmtpMessageSection
        availableProcessors={mockProcessors}
        selectedProcessors={selectedProcessors}
      />

      {/* Current Processor Selection */}
      {userInfo.isStaked && (
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Your Selected Processors</h2>
          <p className="text-gray-600 mb-4">
            These processors handle your data removal requests
          </p>
          
          <div className="text-center py-8 text-gray-500">
            <p>No processors selected yet. Complete staking to see your processors here.</p>
          </div>
        </div>
      )}

      {/* Help Section */}
      <div className="card">
        <h2 className="text-xl font-semibold mb-4">How It Works</h2>
        <div className="space-y-4 text-sm text-gray-600">
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">1.</span>
            <span>Stake RN tokens to join the removal list (minimum 10 RN)</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">2.</span>
            <span>Select trusted processors you're comfortable sharing your information with</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">3.</span>
            <span>Processors handle removal requests from data brokers on your behalf</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">4.</span>
            <span>Track progress and verify completions through zkEmail proofs</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserDashboard;
