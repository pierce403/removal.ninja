import React, { useState, useEffect } from 'react';
import { useAddress, useContract, useContractRead, useContractWrite } from '@thirdweb-dev/react';
import { getFactoryAddress, getRegistryAddress, getTokenAddress } from '../config/contracts';
import { Worker, RemovalTask, DataBroker, TaskStatus, RegisterWorkerForm, TASK_STATUS_LABELS, TASK_STATUS_COLORS } from '../types/contracts';

// Contract ABIs
const FACTORY_ABI = [
  "function registerWorker(uint256 stakeAmount, string calldata description) external",
  "function selfAssignToTask(uint256 taskId) external",
  "function getAvailableTasks() external view returns (uint256[] memory)",
  "function getWorkerTasks(address worker) external view returns (uint256[] memory)",
  "function workers(address) external view returns (bool isRegistered, uint256 stake, uint256 completedTasks, uint256 successRate, uint256 reputation, string memory description, bool isSlashed)",
  "function tasks(uint256) external view returns (address)"
];

const REGISTRY_ABI = [
  "function brokers(uint256) external view returns (uint256 id, string name, string website, string removalLink, string contact, uint256 weight, bool isActive, uint256 totalRemovals, uint256 totalDisputes)"
];

const TOKEN_ABI = [
  "function balanceOf(address) external view returns (uint256)",
  "function allowance(address owner, address spender) external view returns (uint256)",
  "function approve(address spender, uint256 amount) external returns (bool)"
];

const ProcessorDashboard: React.FC = () => {
  const address = useAddress();
  
  // Contract hooks
  const { contract: factoryContract } = useContract(getFactoryAddress(), FACTORY_ABI);
  const { contract: registryContract } = useContract(getRegistryAddress(), REGISTRY_ABI);
  const { contract: tokenContract } = useContract(getTokenAddress(), TOKEN_ABI);
  
  const { data: workerInfo } = useContractRead(factoryContract, "workers", [address]);
  const { data: availableTaskIds } = useContractRead(factoryContract, "getAvailableTasks");
  const { data: assignedTaskIds } = useContractRead(factoryContract, "getWorkerTasks", [address]);
  const { data: tokenBalance } = useContractRead(tokenContract, "balanceOf", [address]);
  const { data: tokenAllowance } = useContractRead(tokenContract, "allowance", [address, getFactoryAddress()]);
  
  const { mutateAsync: registerWorker } = useContractWrite(factoryContract, "registerWorker");
  const { mutateAsync: assignToTask } = useContractWrite(factoryContract, "selfAssignToTask");
  const { mutateAsync: approveTokens } = useContractWrite(tokenContract, "approve");
  
  // Component state
  const [registering, setRegistering] = useState(false);
  const [loading, setLoading] = useState(false);
  const [availableTasks, setAvailableTasks] = useState<RemovalTask[]>([]);
  const [assignedTasks, setAssignedTasks] = useState<RemovalTask[]>([]);
  const [brokers, setBrokers] = useState<DataBroker[]>([]);
  const [formData, setFormData] = useState<RegisterWorkerForm>({
    stakeAmount: '100',
    description: ''
  });

  const formatAddress = (address: string): string => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  const formatTokenAmount = (amount: string | number): string => {
    const value = typeof amount === 'string' ? parseFloat(amount) : amount;
    return (value / Math.pow(10, 18)).toFixed(2);
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
    
    if (!address || !factoryContract || !tokenContract) {
      alert('Please connect your wallet and ensure contracts are loaded');
      return;
    }

    const stakeAmount = parseFloat(formData.stakeAmount) * Math.pow(10, 18); // Convert to wei
    
    if (stakeAmount < 100 * Math.pow(10, 18)) {
      alert('Minimum stake amount is 100 RN tokens');
      return;
    }

    setRegistering(true);
    try {
      // Check if we need to approve tokens
      const currentAllowance = tokenAllowance ? Number(tokenAllowance) : 0;
      if (currentAllowance < stakeAmount) {
        console.log('Approving tokens...');
        await approveTokens({
          args: [getFactoryAddress(), stakeAmount.toString()]
        });
        // Wait for approval transaction
        await new Promise(resolve => setTimeout(resolve, 2000));
      }

      // Register as worker
      const result = await registerWorker({
        args: [stakeAmount.toString(), formData.description]
      });

      console.log('Worker registered successfully:', result);
      alert(`Successfully registered as worker! 🎉`);
      
      // Reset form
      setFormData({
        stakeAmount: '100',
        description: ''
      });
      
    } catch (error: any) {
      console.error('Error registering as worker:', error);
      const errorMessage = error?.reason || error?.message || 'Unknown error occurred';
      alert(`Error registering as worker: ${errorMessage}`);
    } finally {
      setRegistering(false);
    }
  };

  const handleAssignToTask = async (taskId: number) => {
    if (!factoryContract) {
      alert('Contract not loaded. Please try again.');
      return;
    }

    try {
      const result = await assignToTask({
        args: [taskId]
      });

      console.log('Assigned to task successfully:', result);
      alert(`Successfully assigned to task ${taskId}! 🎉`);
      
    } catch (error: any) {
      console.error('Error assigning to task:', error);
      const errorMessage = error?.reason || error?.message || 'Unknown error occurred';
      alert(`Error assigning to task: ${errorMessage}`);
    }
  };

  // Check if user is registered worker
  const isRegisteredWorker = workerInfo && workerInfo[0]; // isRegistered is first element

  if (!address) {
    return (
      <div className="card text-center">
        <h1 className="text-2xl font-bold mb-4">Worker Dashboard</h1>
        <p className="text-gray-600">
          Connect your wallet to register as a worker and start earning from data removal tasks.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Worker Dashboard</h1>
        <p className="text-gray-600 mt-2">
          Register as a worker to take on removal tasks and earn RN tokens
        </p>
      </div>

      {/* Worker Status */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Worker Info</h2>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-600">Status:</span>
              <span className={`status-badge ${isRegisteredWorker ? 'status-active' : 'status-pending'}`}>
                {isRegisteredWorker ? 'Registered' : 'Not Registered'}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">RN Balance:</span>
              <span className="font-semibold">
                {tokenBalance ? formatTokenAmount(tokenBalance.toString()) : '0.00'} RN
              </span>
            </div>
            {isRegisteredWorker && (
              <div className="flex justify-between">
                <span className="text-gray-600">Stake Amount:</span>
                <span className="font-semibold">
                  {workerInfo ? formatTokenAmount(workerInfo[1].toString()) : '0.00'} RN
                </span>
              </div>
            )}
          </div>
        </div>

        {isRegisteredWorker && (
          <>
            <div className="card">
              <h2 className="text-xl font-semibold mb-4">Performance</h2>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">Completed Tasks:</span>
                  <span className="font-semibold">{workerInfo ? Number(workerInfo[2]) : 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Success Rate:</span>
                  <span className="font-semibold">{workerInfo ? Number(workerInfo[3]) : 0}%</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Reputation:</span>
                  <span className="font-semibold">{workerInfo ? Number(workerInfo[4]) : 0}</span>
                </div>
              </div>
            </div>

            <div className="card">
              <h2 className="text-xl font-semibold mb-4">Task Stats</h2>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">Available Tasks:</span>
                  <span className="font-semibold">{availableTaskIds ? availableTaskIds.length : 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Assigned Tasks:</span>
                  <span className="font-semibold text-blue-600">{assignedTaskIds ? assignedTaskIds.length : 0}</span>
                </div>
              </div>
            </div>
          </>
        )}
      </div>

      {/* Registration Form */}
      {!isRegisteredWorker && (
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Register as Worker</h2>
          <p className="text-gray-600 mb-6">
            Stake RN tokens to become a worker and start earning from data removal tasks.
            Higher stakes may lead to better task assignments.
          </p>

          <form onSubmit={handleRegister} className="space-y-6">
            <div className="form-group">
              <label className="form-label">Stake Amount (minimum 100 RN)</label>
              <input
                type="number"
                name="stakeAmount"
                value={formData.stakeAmount}
                onChange={handleInputChange}
                className="form-input"
                min="100"
                step="10"
                required
              />
              <p className="text-sm text-gray-500 mt-1">
                Stake RN tokens to show commitment. Higher stakes may receive priority.
              </p>
            </div>

            <div className="form-group">
              <label className="form-label">Worker Description</label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                className="form-textarea"
                placeholder="Describe your experience with data removal, privacy tools, and why you'd be a good worker..."
                required
              />
              <p className="text-sm text-gray-500 mt-1">
                Describe your qualifications and experience
              </p>
            </div>

            <button
              type="submit"
              disabled={registering}
              className="btn w-full flex items-center justify-center gap-2"
            >
              {registering && <div className="loading"></div>}
              Register as Worker
            </button>
          </form>
        </div>
      )}

      {/* Available Tasks */}
      {isRegisteredWorker && (
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Available Tasks</h2>
          
          {availableTaskIds && availableTaskIds.length > 0 ? (
            <div className="space-y-4">
              <p className="text-gray-600">
                {availableTaskIds.length} task{availableTaskIds.length !== 1 ? 's' : ''} available for assignment.
              </p>
              
              {availableTaskIds.slice(0, 5).map((taskId: any) => (
                <div key={taskId.toString()} className="border rounded-lg p-4">
                  <div className="flex justify-between items-start mb-3">
                    <div>
                      <h3 className="font-semibold">Task #{taskId.toString()}</h3>
                      <p className="text-sm text-gray-600">
                        Click to assign yourself to this task
                      </p>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="status-badge status-pending">Available</span>
                    </div>
                  </div>

                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-500">
                      Task ID: {taskId.toString()}
                    </span>
                    
                    <button
                      onClick={() => handleAssignToTask(Number(taskId))}
                      className="btn px-3 py-1 text-sm"
                    >
                      Assign to Me
                    </button>
                  </div>
                </div>
              ))}
              
              {availableTaskIds.length > 5 && (
                <p className="text-center text-gray-500">
                  ... and {availableTaskIds.length - 5} more tasks
                </p>
              )}
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500">
              <p>No available tasks</p>
              <p className="text-sm mt-1">
                Available tasks will appear here when users create them
              </p>
            </div>
          )}
        </div>
      )}

      {/* Assigned Tasks */}
      {isRegisteredWorker && (
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Your Assigned Tasks</h2>
          
          {assignedTaskIds && assignedTaskIds.length > 0 ? (
            <div className="space-y-4">
              <p className="text-gray-600">
                You have {assignedTaskIds.length} assigned task{assignedTaskIds.length !== 1 ? 's' : ''}.
              </p>
              
              <div className="text-center py-8 text-gray-500">
                <p>Task details will be loaded here.</p>
                <p className="text-sm mt-2">Full task management in progress...</p>
              </div>
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500">
              <p>No assigned tasks</p>
              <p className="text-sm mt-1">
                Assign yourself to available tasks to start working
              </p>
            </div>
          )}
        </div>
      )}

      {/* Help Section */}
      <div className="card">
        <h2 className="text-xl font-semibold mb-4">How Worker System Works</h2>
        <div className="space-y-4 text-sm text-gray-600">
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">1.</span>
            <span>Register as a worker by staking RN tokens and providing your credentials</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">2.</span>
            <span>Browse available removal tasks and assign yourself to tasks you can handle</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">3.</span>
            <span>Complete the removal process and submit evidence of successful removal</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">4.</span>
            <span>Get verified by the verifier network and receive payment upon confirmation</span>
          </div>
          <div className="flex gap-3">
            <span className="text-ninja-600 font-bold">5.</span>
            <span>Build reputation through successful completions to access higher-paying tasks</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProcessorDashboard;
