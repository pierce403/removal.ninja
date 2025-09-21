import React, { useState } from 'react';
import { useAddress } from '@thirdweb-dev/react';

interface ProcessorInfo {
  isRegistered: boolean;
  stakeAmount: string;
  description: string;
  activeRequests: number;
  completedRequests: number;
  reputation: number;
  earnedTokens: string;
}

interface RemovalRequest {
  id: string;
  userAddress: string;
  brokerName: string;
  status: 'pending' | 'in-progress' | 'completed' | 'failed';
  submittedAt: string;
  reward: string;
}

// Mock data for development
const mockRequests: RemovalRequest[] = [
  {
    id: '1',
    userAddress: '0x1234567890123456789012345678901234567890',
    brokerName: 'Acxiom',
    status: 'pending',
    submittedAt: '2024-01-20',
    reward: '50'
  },
  {
    id: '2',
    userAddress: '0x2345678901234567890123456789012345678901',
    brokerName: 'LexisNexis',
    status: 'in-progress',
    submittedAt: '2024-01-19',
    reward: '50'
  }
];

const ProcessorDashboard: React.FC = () => {
  const address = useAddress();
  const [registering, setRegistering] = useState(false);
  const [processorInfo] = useState<ProcessorInfo>({
    isRegistered: false,
    stakeAmount: '0',
    description: '',
    activeRequests: 0,
    completedRequests: 0,
    reputation: 0,
    earnedTokens: '0'
  });
  const [formData, setFormData] = useState({
    stakeAmount: '1000',
    description: ''
  });

  const formatAddress = (address: string): string => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!address) {
      alert('Please connect your wallet first');
      return;
    }

    if (parseFloat(formData.stakeAmount) < 1000) {
      alert('Minimum stake amount is 1000 RN tokens');
      return;
    }

    setRegistering(true);
    try {
      // TODO: Integrate with smart contract
      console.log('Registering as processor:', formData);
      alert(`Would register as processor with ${formData.stakeAmount} RN tokens stake`);
    } catch (error) {
      console.error('Error registering as processor:', error);
      alert('Failed to register as processor');
    } finally {
      setRegistering(false);
    }
  };

  const handleRequestAction = (requestId: string, action: string) => {
    // TODO: Implement request handling
    console.log(`${action} request ${requestId}`);
    alert(`Would ${action} removal request ${requestId}`);
  };

  if (!address) {
    return (
      <div className="card text-center">
        <h1 className="text-2xl font-bold mb-4">Processor Dashboard</h1>
        <p className="text-gray-600">
          Connect your wallet to access the processor dashboard and manage removal requests.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Processor Dashboard</h1>
        <p className="text-gray-600 mt-2">
          Manage your processor status and handle data removal requests
        </p>
      </div>

      {/* Processor Status */}
      {processorInfo.isRegistered ? (
        <div className="grid grid-2 gap-6">
          <div className="card">
            <h2 className="text-xl font-semibold mb-4">Processor Stats</h2>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-600">Status:</span>
                <span className="status-badge status-active">Active Processor</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Stake Amount:</span>
                <span className="font-semibold">{processorInfo.stakeAmount} RN</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Reputation:</span>
                <span className="font-semibold">{processorInfo.reputation}%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Total Earned:</span>
                <span className="font-semibold text-green-600">{processorInfo.earnedTokens} RN</span>
              </div>
            </div>
          </div>

          <div className="card">
            <h2 className="text-xl font-semibold mb-4">Request Stats</h2>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-600">Active Requests:</span>
                <span className="font-semibold">{processorInfo.activeRequests}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Completed:</span>
                <span className="font-semibold text-green-600">{processorInfo.completedRequests}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Success Rate:</span>
                <span className="font-semibold">
                  {processorInfo.completedRequests > 0 ? '98%' : 'N/A'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Avg. Processing Time:</span>
                <span className="font-semibold">2.3 days</span>
              </div>
            </div>
          </div>
        </div>
      ) : (
        /* Registration Form */
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Register as Processor</h2>
          <p className="text-gray-600 mb-6">
            Stake RN tokens to become a trusted processor and start earning from data removal requests.
          </p>

          <form onSubmit={handleRegister} className="space-y-6">
            <div className="form-group">
              <label className="form-label">Stake Amount (minimum 1000 RN)</label>
              <input
                type="number"
                name="stakeAmount"
                value={formData.stakeAmount}
                onChange={handleInputChange}
                className="form-input"
                min="1000"
                step="100"
                required
              />
              <p className="text-sm text-gray-500 mt-1">
                Higher stakes may attract more users and increase earnings potential
              </p>
            </div>

            <div className="form-group">
              <label className="form-label">Processor Description</label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                className="form-textarea"
                placeholder="Describe your service, experience, and what makes you trustworthy..."
                required
              />
              <p className="text-sm text-gray-500 mt-1">
                Users will see this when choosing processors they trust
              </p>
            </div>

            <button
              type="submit"
              disabled={registering}
              className="btn w-full flex items-center justify-center gap-2"
            >
              {registering && <div className="loading"></div>}
              Register as Processor
            </button>
          </form>
        </div>
      )}

      {/* Active Requests */}
      <div className="card">
        <h2 className="text-xl font-semibold mb-4">Removal Requests</h2>
        {mockRequests.length > 0 ? (
          <div className="space-y-4">
            {mockRequests.map((request) => (
              <div key={request.id} className="border rounded-lg p-4">
                <div className="flex justify-between items-start mb-3">
                  <div>
                    <h3 className="font-semibold">{request.brokerName} Removal</h3>
                    <p className="text-sm text-gray-600">
                      User: {formatAddress(request.userAddress)}
                    </p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className={`status-badge ${
                      request.status === 'completed' ? 'status-verified' :
                      request.status === 'in-progress' ? 'status-active' :
                      request.status === 'failed' ? 'status-pending' : 'status-pending'
                    }`}>
                      {request.status}
                    </span>
                    <span className="text-sm font-semibold text-green-600">
                      {request.reward} RN
                    </span>
                  </div>
                </div>

                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500">
                    Submitted: {request.submittedAt}
                  </span>
                  
                  <div className="flex gap-2">
                    {request.status === 'pending' && (
                      <button
                        onClick={() => handleRequestAction(request.id, 'accept')}
                        className="btn-secondary px-3 py-1 text-sm"
                      >
                        Accept
                      </button>
                    )}
                    {request.status === 'in-progress' && (
                      <button
                        onClick={() => handleRequestAction(request.id, 'complete')}
                        className="btn px-3 py-1 text-sm"
                      >
                        Mark Complete
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <p>No removal requests available</p>
            <p className="text-sm mt-1">
              {processorInfo.isRegistered 
                ? 'Requests will appear here when users select you as their processor'
                : 'Register as a processor to start receiving removal requests'
              }
            </p>
          </div>
        )}
      </div>

      {/* Help Section */}
      <div className="card">
        <h2 className="text-xl font-semibold mb-4">How Processing Works</h2>
        <div className="space-y-4 text-sm text-gray-600">
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">1.</span>
            <span>Users select you as their trusted processor during staking</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">2.</span>
            <span>Accept removal requests and handle them securely off-chain</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">3.</span>
            <span>Submit zkEmail proofs of successful removals for verification</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">4.</span>
            <span>Earn 50 RN tokens for each verified successful removal</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProcessorDashboard;
