import React, { useState } from 'react';
import { ethers } from 'ethers';
import { useWallet } from '../hooks/useWallet';
import toast from 'react-hot-toast';

const ProcessorDashboard = () => {
  const { account, contract, balance } = useWallet();
  const [registering, setRegistering] = useState(false);
  const [formData, setFormData] = useState({
    stakeAmount: '1000',
    description: ''
  });

  const handleRegister = async (e) => {
    e.preventDefault();
    
    if (!account || !contract) {
      toast.error('Please connect your wallet first');
      return;
    }

    try {
      setRegistering(true);
      
      const stakeAmountWei = ethers.parseEther(formData.stakeAmount);
      
      const tx = await contract.registerAsProcessor(
        stakeAmountWei,
        formData.description
      );
      
      toast.success('Registration submitted! Waiting for confirmation...');
      await tx.wait();
      
      toast.success('Successfully registered as processor!');
      
    } catch (error) {
      console.error('Error registering as processor:', error);
      toast.error('Failed to register as processor');
    } finally {
      setRegistering(false);
    }
  };

  if (!account) {
    return (
      <div className="card text-center">
        <h1>Processor Dashboard</h1>
        <p>Please connect your wallet to access the processor dashboard.</p>
      </div>
    );
  }

  return (
    <div>
      <div className="card">
        <h1>Processor Dashboard</h1>
        <p>Manage your processor registration and track your removal processing activity.</p>
      </div>

      <div className="card">
        <h2>Register as Processor</h2>
        <p>
          Stake tokens to become a trusted processor and earn rewards for handling removal requests.
        </p>
        
        <form onSubmit={handleRegister}>
          <div className="form-group">
            <label className="form-label">Stake Amount (minimum 1,000 RN)</label>
            <input
              type="number"
              value={formData.stakeAmount}
              onChange={(e) => setFormData({...formData, stakeAmount: e.target.value})}
              className="form-input"
              min="1000"
              step="1"
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Description</label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              className="form-textarea"
              placeholder="Describe your processing service..."
              required
            />
          </div>

          <button 
            type="submit" 
            className="btn"
            disabled={registering || parseFloat(balance) < parseFloat(formData.stakeAmount)}
          >
            {registering ? <span className="loading"></span> : `Register (Stake ${formData.stakeAmount} RN)`}
          </button>
          
          {parseFloat(balance) < parseFloat(formData.stakeAmount) && (
            <p style={{ color: 'red', marginTop: '0.5rem' }}>
              Insufficient balance. You need {formData.stakeAmount} RN tokens.
            </p>
          )}
        </form>
      </div>
    </div>
  );
};

export default ProcessorDashboard;