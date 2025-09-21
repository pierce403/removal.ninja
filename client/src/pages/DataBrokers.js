import React, { useState, useEffect } from 'react';
import { useWallet } from '../hooks/useWallet';
import toast from 'react-hot-toast';
import styled from 'styled-components';

const BrokerCard = styled.div`
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 1rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  border-left: 4px solid ${props => props.verified ? '#28a745' : '#ffc107'};
`;

const BrokerHeader = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
`;

const BrokerName = styled.h3`
  margin: 0;
  color: #333;
`;

const SubmissionForm = styled.form`
  background: white;
  padding: 2rem;
  border-radius: 8px;
  margin-bottom: 2rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
`;

const DataBrokers = () => {
  const { account, contract } = useWallet();
  const [brokers, setBrokers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    website: '',
    removalInstructions: ''
  });

  const fetchBrokers = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/blockchain/brokers');
      if (response.ok) {
        const data = await response.json();
        setBrokers(data);
      }
    } catch (error) {
      console.error('Error fetching brokers:', error);
      toast.error('Failed to load data brokers');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBrokers();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!account || !contract) {
      toast.error('Please connect your wallet first');
      return;
    }

    try {
      setSubmitting(true);
      
      const tx = await contract.submitDataBroker(
        formData.name,
        formData.website,
        formData.removalInstructions
      );
      
      toast.success('Transaction submitted! Waiting for confirmation...');
      await tx.wait();
      
      toast.success('Data broker submitted successfully! You earned 100 RN tokens!');
      setFormData({ name: '', website: '', removalInstructions: '' });
      setShowForm(false);
      fetchBrokers();
      
    } catch (error) {
      console.error('Error submitting broker:', error);
      toast.error('Failed to submit data broker');
    } finally {
      setSubmitting(false);
    }
  };

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const requestRemoval = async (brokerId) => {
    if (!account || !contract) {
      toast.error('Please connect your wallet first');
      return;
    }

    try {
      const tx = await contract.requestRemoval(brokerId);
      toast.success('Removal request submitted!');
      await tx.wait();
      toast.success('Removal request confirmed!');
    } catch (error) {
      console.error('Error requesting removal:', error);
      toast.error('Failed to request removal. Make sure you are staked on the removal list.');
    }
  };

  return (
    <div>
      <div className="card">
        <h1>Data Brokers Directory</h1>
        <p>
          Browse known data brokers and submit new ones to earn rewards. 
          Each verified submission earns you 100 RN tokens!
        </p>
        
        {account && (
          <button 
            className="btn mt-2"
            onClick={() => setShowForm(!showForm)}
          >
            {showForm ? 'Cancel' : '+ Submit New Broker'}
          </button>
        )}
      </div>

      {showForm && (
        <SubmissionForm onSubmit={handleSubmit}>
          <h2>Submit New Data Broker</h2>
          <p>Help the community by adding new data brokers. Earn 100 RN tokens for verified submissions!</p>
          
          <div className="form-group">
            <label className="form-label">Company Name *</label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              className="form-input"
              required
              placeholder="e.g., Acme Data Solutions"
            />
          </div>

          <div className="form-group">
            <label className="form-label">Website URL *</label>
            <input
              type="url"
              name="website"
              value={formData.website}
              onChange={handleInputChange}
              className="form-input"
              required
              placeholder="https://example.com"
            />
          </div>

          <div className="form-group">
            <label className="form-label">Removal Instructions</label>
            <textarea
              name="removalInstructions"
              value={formData.removalInstructions}
              onChange={handleInputChange}
              className="form-textarea"
              placeholder="Describe how to request data removal from this broker..."
            />
          </div>

          <div>
            <button 
              type="submit" 
              className="btn"
              disabled={submitting}
            >
              {submitting ? <span className="loading"></span> : 'Submit Broker (Earn 100 RN)'}
            </button>
            <button 
              type="button" 
              className="btn btn-secondary"
              onClick={() => setShowForm(false)}
              style={{ marginLeft: '1rem' }}
            >
              Cancel
            </button>
          </div>
        </SubmissionForm>
      )}

      <div>
        <h2>Known Data Brokers ({brokers.length})</h2>
        
        {loading ? (
          <div className="text-center">
            <span className="loading"></span>
            <p>Loading data brokers...</p>
          </div>
        ) : brokers.length === 0 ? (
          <div className="card text-center">
            <p>No data brokers found. Be the first to submit one!</p>
          </div>
        ) : (
          brokers.map((broker) => (
            <BrokerCard key={broker.id} verified={broker.verified}>
              <BrokerHeader>
                <div>
                  <BrokerName>{broker.name}</BrokerName>
                  <p>
                    <a href={broker.website} target="_blank" rel="noopener noreferrer">
                      {broker.website}
                    </a>
                  </p>
                </div>
                <div>
                  <span className={`status-badge ${broker.verified ? 'status-verified' : 'status-pending'}`}>
                    {broker.verified ? 'Verified' : 'Pending'}
                  </span>
                </div>
              </BrokerHeader>
              
              {broker.removalInstructions && (
                <div>
                  <strong>Removal Instructions:</strong>
                  <p>{broker.removalInstructions}</p>
                </div>
              )}
              
              <div className="mt-2">
                <small>
                  Submitted by: {broker.submitter.slice(0, 6)}...{broker.submitter.slice(-4)} | 
                  {' '}{new Date(broker.timestamp).toLocaleDateString()}
                </small>
              </div>
              
              {account && broker.verified && (
                <button 
                  className="btn btn-success mt-2"
                  onClick={() => requestRemoval(broker.id)}
                >
                  Request Removal
                </button>
              )}
            </BrokerCard>
          ))
        )}
      </div>
    </div>
  );
};

export default DataBrokers;