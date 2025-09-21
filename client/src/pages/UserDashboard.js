import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useWallet } from '../hooks/useWallet';
import toast from 'react-hot-toast';

const UserDashboard = () => {
  const { account, contract, balance, updateBalance } = useWallet();
  const [userInfo, setUserInfo] = useState(null);
  const [processors, setProcessors] = useState([]);
  const [loading, setLoading] = useState(false);
  const [staking, setStaking] = useState(false);
  const [stakeAmount, setStakeAmount] = useState('10');
  const [selectedProcessors, setSelectedProcessors] = useState([]);

  const fetchUserInfo = async () => {
    if (!account) return;
    
    try {
      const response = await fetch(`/api/blockchain/user/${account}`);
      if (response.ok) {
        const data = await response.json();
        setUserInfo(data);
        setSelectedProcessors(data.selectedProcessors || []);
      }
    } catch (error) {
      console.error('Error fetching user info:', error);
    }
  };

  const fetchProcessors = async () => {
    // This would fetch available processors from the blockchain
    // For now, we'll use mock data
    setProcessors([
      { address: '0x1234...5678', active: true, description: 'Trusted removal processor' },
      { address: '0x9876...5432', active: true, description: 'Fast processing service' }
    ]);
  };

  useEffect(() => {
    if (account) {
      fetchUserInfo();
      fetchProcessors();
    }
  }, [account]);

  const handleStakeForRemoval = async (e) => {
    e.preventDefault();
    
    if (!account || !contract) {
      toast.error('Please connect your wallet first');
      return;
    }

    if (selectedProcessors.length === 0) {
      toast.error('Please select at least one processor');
      return;
    }

    try {
      setStaking(true);
      
      const stakeAmountWei = ethers.parseEther(stakeAmount);
      
      const tx = await contract.stakeForRemovalList(
        stakeAmountWei,
        selectedProcessors
      );
      
      toast.success('Transaction submitted! Waiting for confirmation...');
      await tx.wait();
      
      toast.success('Successfully staked for removal list!');
      fetchUserInfo();
      updateBalance();
      
    } catch (error) {
      console.error('Error staking:', error);
      toast.error('Failed to stake for removal list');
    } finally {
      setStaking(false);
    }
  };

  const toggleProcessor = (processorAddress) => {
    setSelectedProcessors(prev => 
      prev.includes(processorAddress)
        ? prev.filter(addr => addr !== processorAddress)
        : [...prev, processorAddress]
    );
  };

  if (!account) {
    return (
      <div className="card text-center">
        <h1>User Dashboard</h1>
        <p>Please connect your wallet to access your dashboard.</p>
      </div>
    );
  }

  return (
    <div>
      <div className="card">
        <h1>User Dashboard</h1>
        <p>Manage your removal list status and track your activity.</p>
      </div>

      <div className="grid grid-2">
        <div className="card">
          <h2>Your Status</h2>
          <div>
            <p><strong>Wallet:</strong> {account}</p>
            <p><strong>Token Balance:</strong> {parseFloat(balance).toFixed(2)} RN</p>
            <p><strong>On Removal List:</strong> 
              <span className={`status-badge ${userInfo?.onRemovalList ? 'status-verified' : 'status-pending'}`}>
                {userInfo?.onRemovalList ? 'Yes' : 'No'}
              </span>
            </p>
            {userInfo?.onRemovalList && (
              <p><strong>Staked Amount:</strong> {userInfo.stakedAmount} RN</p>
            )}
          </div>
        </div>

        <div className="card">
          <h2>Quick Actions</h2>
          <div>
            <a href="/brokers" className="btn mb-2" style={{ display: 'block' }}>
              Browse Data Brokers
            </a>
            <a href="/brokers" className="btn btn-success mb-2" style={{ display: 'block' }}>
              Request Removals
            </a>
            {!userInfo?.onRemovalList && (
              <p><em>Stake tokens below to enable removal requests</em></p>
            )}
          </div>
        </div>
      </div>

      {!userInfo?.onRemovalList && (
        <div className="card">
          <h2>Join Removal List</h2>
          <p>
            Stake RN tokens to get added to the removal list. This allows you to request 
            removals from data brokers through trusted processors.
          </p>
          
          <form onSubmit={handleStakeForRemoval}>
            <div className="form-group">
              <label className="form-label">Stake Amount (minimum 10 RN)</label>
              <input
                type="number"
                value={stakeAmount}
                onChange={(e) => setStakeAmount(e.target.value)}
                className="form-input"
                min="10"
                step="0.1"
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Select Trusted Processors</label>
              <p>Choose which processors you trust to handle your removal requests:</p>
              
              {processors.map(processor => (
                <div key={processor.address} style={{ marginBottom: '0.5rem' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <input
                      type="checkbox"
                      checked={selectedProcessors.includes(processor.address)}
                      onChange={() => toggleProcessor(processor.address)}
                    />
                    <span>
                      {processor.address} - {processor.description}
                    </span>
                  </label>
                </div>
              ))}
            </div>

            <button 
              type="submit" 
              className="btn"
              disabled={staking || parseFloat(balance) < parseFloat(stakeAmount)}
            >
              {staking ? <span className="loading"></span> : `Stake ${stakeAmount} RN Tokens`}
            </button>
            
            {parseFloat(balance) < parseFloat(stakeAmount) && (
              <p style={{ color: 'red', marginTop: '0.5rem' }}>
                Insufficient balance. You need {stakeAmount} RN tokens.
              </p>
            )}
          </form>
        </div>
      )}

      {userInfo?.onRemovalList && (
        <div className="card">
          <h2>Your Selected Processors</h2>
          <p>These processors can handle removal requests on your behalf:</p>
          
          {userInfo.selectedProcessors?.length > 0 ? (
            <ul>
              {userInfo.selectedProcessors.map(processor => (
                <li key={processor}>{processor}</li>
              ))}
            </ul>
          ) : (
            <p>No processors selected.</p>
          )}
        </div>
      )}
    </div>
  );
};

export default UserDashboard;