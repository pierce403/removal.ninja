import React, { useState, useEffect, useCallback } from 'react';
import { useAddress, useContract, useContractRead, useContractWrite } from '@thirdweb-dev/react';
import { getFactoryAddress, getRegistryAddress, getTokenAddress } from '../config/contracts';
import { DataBroker, CreateTaskForm } from '../types/contracts';

// Contract ABIs for the modular system
const FACTORY_ABI = [
  "function createTask(uint256 brokerId, bytes32 subjectCommit, uint256 payout, uint256 duration) external returns (uint256 taskId, address taskContract)",
  "function getUserTasks(address user) external view returns (uint256[] memory)",
  "function getStats() external view returns (uint256 totalTasks)",
  "function tasks(uint256) external view returns (address)"
];

const REGISTRY_ABI = [
  "function brokers(uint256) external view returns (uint256 id, string name, string website, string removalLink, string contact, uint256 weight, bool isActive, uint256 totalRemovals, uint256 totalDisputes)",
  "function nextBrokerId() external view returns (uint256)"
];

const TOKEN_ABI = [
  "function balanceOf(address) external view returns (uint256)",
  "function allowance(address owner, address spender) external view returns (uint256)",
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function transfer(address to, uint256 amount) external returns (bool)"
];

const UserDashboard: React.FC = () => {
  const address = useAddress();
  
  // Contract hooks
  const { contract: factoryContract } = useContract(getFactoryAddress(), FACTORY_ABI);
  const { contract: registryContract } = useContract(getRegistryAddress(), REGISTRY_ABI);
  const { contract: tokenContract } = useContract(getTokenAddress(), TOKEN_ABI);
  
  const { data: userTaskIds } = useContractRead(factoryContract, "getUserTasks", [address]);
  const { data: nextBrokerId } = useContractRead(registryContract, "nextBrokerId");
  const { data: tokenBalance } = useContractRead(tokenContract, "balanceOf", [address]);
  const { data: tokenAllowance } = useContractRead(tokenContract, "allowance", [address, getFactoryAddress()]);
  
  const { mutateAsync: createTask } = useContractWrite(factoryContract, "createTask");
  const { mutateAsync: approveTokens } = useContractWrite(tokenContract, "approve");
  
  // Component state
  const [brokers, setBrokers] = useState<DataBroker[]>([]);
  const [creating, setCreating] = useState(false);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [createFormData, setCreateFormData] = useState<CreateTaskForm>({
    brokerId: '',
    payout: '50',
    duration: '30',
    description: ''
  });

  // Fetch brokers from registry
  const fetchBrokers = useCallback(async () => {
    if (!registryContract || !nextBrokerId) return;
    
    try {
      const brokersData: DataBroker[] = [];
      
      for (let i = 1; i < Number(nextBrokerId); i++) {
        try {
          const brokerData = await registryContract.call("brokers", [i]);
          if (brokerData && brokerData[6]) { // isActive
            brokersData.push({
              id: Number(brokerData[0]),
              name: brokerData[1],
              website: brokerData[2],
              removalLink: brokerData[3],
              contact: brokerData[4],
              weight: Number(brokerData[5]),
              isActive: brokerData[6],
              totalRemovals: Number(brokerData[7]),
              totalDisputes: Number(brokerData[8])
            });
          }
        } catch (error) {
          console.error(`Error fetching broker ${i}:`, error);
        }
      }
      
      setBrokers(brokersData);
    } catch (error) {
      console.error('Error fetching brokers:', error);
    }
  }, [registryContract, nextBrokerId]);

  // Load data on component mount
  useEffect(() => {
    fetchBrokers();
  }, [registryContract, nextBrokerId, fetchBrokers]);

  const formatAddress = (address: string): string => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  const formatTokenAmount = (amount: string | number): string => {
    const value = typeof amount === 'string' ? parseFloat(amount) : amount;
    return (value / Math.pow(10, 18)).toFixed(2);
  };

  const handleCreateTask = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!address || !factoryContract || !tokenContract) {
      alert('Please connect your wallet and ensure contracts are loaded');
      return;
    }

    const payout = parseFloat(createFormData.payout) * Math.pow(10, 18); // Convert to wei
    const duration = parseInt(createFormData.duration) * 24 * 60 * 60; // Convert days to seconds
    
    if (payout < 10 * Math.pow(10, 18)) {
      alert('Minimum payout is 10 RN tokens');
      return;
    }

    setCreating(true);
    try {
      // Check if we need to approve tokens
      const currentAllowance = tokenAllowance ? Number(tokenAllowance) : 0;
      if (currentAllowance < payout) {
        console.log('Approving tokens...');
        await approveTokens({
          args: [getFactoryAddress(), payout.toString()]
        });
        // Wait a bit for approval transaction to be mined
        await new Promise(resolve => setTimeout(resolve, 2000));
      }

      // Generate a simple subject commit (in production, this would be a proper hash)
      const subjectCommit = `0x${Math.random().toString(16).substring(2).padStart(64, '0')}`;

      // Create the task
      const result = await createTask({
        args: [
          parseInt(createFormData.brokerId),
          subjectCommit,
          payout.toString(),
          duration
        ]
      });

      console.log('Task created successfully:', result);
      alert(`Removal task created successfully! 🎉`);
      
      // Reset form
      setCreateFormData({
        brokerId: '',
        payout: '50',
        duration: '30',
        description: ''
      });
      setShowCreateForm(false);
      
    } catch (error: any) {
      console.error('Error creating task:', error);
      const errorMessage = error?.reason || error?.message || 'Unknown error occurred';
      alert(`Error creating task: ${errorMessage}`);
    } finally {
      setCreating(false);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setCreateFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  if (!address) {
    return (
      <div className="card text-center">
        <h1 className="text-2xl font-bold mb-4">User Dashboard</h1>
        <p className="text-gray-600 mb-6">
          Connect your wallet to create removal tasks and track your data removal progress.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">User Dashboard</h1>
          <p className="text-gray-600 mt-2">
            Create and manage your data removal tasks
          </p>
        </div>
        <button
          onClick={() => setShowCreateForm(!showCreateForm)}
          className="btn"
        >
          {showCreateForm ? 'Cancel' : 'Create Removal Task'}
        </button>
      </div>

      {/* User Status */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Wallet Info</h2>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-600">Address:</span>
              <span className="font-mono">{formatAddress(address)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">RN Balance:</span>
              <span className="font-semibold">
                {tokenBalance ? formatTokenAmount(tokenBalance.toString()) : '0.00'} RN
              </span>
            </div>
          </div>
        </div>

        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Task Stats</h2>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-600">Total Tasks:</span>
              <span className="font-semibold">{userTaskIds ? userTaskIds.length : 0}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Active Tasks:</span>
              <span className="font-semibold text-blue-600">
                {userTaskIds?.length || 0}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Completed:</span>
              <span className="font-semibold text-green-600">
                0
              </span>
            </div>
          </div>
        </div>

        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Available Brokers</h2>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-600">Total Brokers:</span>
              <span className="font-semibold">{brokers.length}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">High Impact:</span>
              <span className="font-semibold text-red-600">
                {brokers.filter(b => b.weight >= 300).length}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Create Task Form */}
      {showCreateForm && (
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Create Removal Task</h2>
          <p className="text-gray-600 mb-6">
            Create a task for a worker to remove your data from a specific broker.
            Higher payouts attract better workers.
          </p>

          <form onSubmit={handleCreateTask} className="space-y-6">
            <div className="form-group">
              <label className="form-label">Data Broker *</label>
              <select
                name="brokerId"
                value={createFormData.brokerId}
                onChange={handleInputChange}
                className="form-input"
                required
              >
                <option value="">Select a broker...</option>
                {brokers.map((broker) => (
                  <option key={broker.id} value={broker.id}>
                    {broker.name} - {broker.weight >= 300 ? 'High Impact' : broker.weight >= 200 ? 'Medium Impact' : 'Standard'} 
                    ({broker.weight / 100}x multiplier)
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Payout Amount (RN tokens) *</label>
              <input
                type="number"
                name="payout"
                value={createFormData.payout}
                onChange={handleInputChange}
                className="form-input"
                min="10"
                step="1"
                required
              />
              <p className="text-sm text-gray-500 mt-1">
                Minimum 10 RN. Higher amounts attract more experienced workers.
              </p>
            </div>

            <div className="form-group">
              <label className="form-label">Task Duration (days) *</label>
              <input
                type="number"
                name="duration"
                value={createFormData.duration}
                onChange={handleInputChange}
                className="form-input"
                min="7"
                max="90"
                step="1"
                required
              />
              <p className="text-sm text-gray-500 mt-1">
                How long workers have to complete the removal (7-90 days)
              </p>
            </div>

            <div className="form-group">
              <label className="form-label">Description (Optional)</label>
              <textarea
                name="description"
                value={createFormData.description}
                onChange={handleInputChange}
                className="form-textarea"
                placeholder="Any specific instructions or requirements for the removal..."
                rows={3}
              />
            </div>

            <div className="flex gap-4">
              <button
                type="submit"
                disabled={creating}
                className="btn flex items-center gap-2"
              >
                {creating && <div className="loading"></div>}
                Create Task
              </button>
              <button
                type="button"
                onClick={() => setShowCreateForm(false)}
                className="btn-secondary"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Your Tasks */}
      <div className="card">
        <h2 className="text-xl font-semibold mb-4">Your Removal Tasks</h2>
        
        {userTaskIds && userTaskIds.length > 0 ? (
          <div className="space-y-4">
            <p className="text-gray-600">
              You have {userTaskIds.length} task{userTaskIds.length !== 1 ? 's' : ''} created.
            </p>
            <div className="text-center py-8 text-gray-500">
              <p>Task details will be loaded here.</p>
              <p className="text-sm mt-2">Contract integration in progress...</p>
            </div>
          </div>
        ) : (
          <div className="text-center py-8">
            <h3 className="text-lg font-semibold mb-2">No Tasks Yet</h3>
            <p className="text-gray-600 mb-4">
              Create your first removal task to get started with data removal.
            </p>
            <button
              onClick={() => setShowCreateForm(true)}
              className="btn"
            >
              Create Your First Task
            </button>
          </div>
        )}
      </div>

      {/* Help Section */}
      <div className="card">
        <h2 className="text-xl font-semibold mb-4">How It Works</h2>
        <div className="space-y-4 text-sm text-gray-600">
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">1.</span>
            <span>Choose a data broker and create a removal task with a payout</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">2.</span>
            <span>Workers take on your task and handle the removal process</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">3.</span>
            <span>Workers submit evidence of successful removal</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">4.</span>
            <span>Verifiers check the evidence and confirm completion</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">5.</span>
            <span>Payment is released to the worker upon verification</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserDashboard;
