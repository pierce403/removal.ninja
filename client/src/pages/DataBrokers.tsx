import React, { useState } from 'react';
import { useAddress } from '@thirdweb-dev/react';

interface DataBroker {
  id: string;
  name: string;
  website: string;
  removalInstructions: string;
  verified: boolean;
  submittedBy: string;
  dateSubmitted: string;
}

// Mock data for development
const mockBrokers: DataBroker[] = [
  {
    id: '1',
    name: 'Acxiom',
    website: 'https://acxiom.com',
    removalInstructions: 'Visit privacy center and submit removal request with ID verification',
    verified: true,
    submittedBy: '0x1234...5678',
    dateSubmitted: '2024-01-15'
  },
  {
    id: '2',
    name: 'LexisNexis',
    website: 'https://lexisnexis.com',
    removalInstructions: 'Email privacy team with full name and address for removal',
    verified: true,
    submittedBy: '0x2345...6789',
    dateSubmitted: '2024-01-10'
  },
  {
    id: '3',
    name: 'Spokeo',
    website: 'https://spokeo.com',
    removalInstructions: 'Use online opt-out form and verify email address',
    verified: false,
    submittedBy: '0x3456...7890',
    dateSubmitted: '2024-01-20'
  }
];

interface FormData {
  name: string;
  website: string;
  removalInstructions: string;
}

const DataBrokers: React.FC = () => {
  const address = useAddress();
  const [brokers] = useState<DataBroker[]>(mockBrokers);
  const [loading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState<FormData>({
    name: '',
    website: '',
    removalInstructions: ''
  });

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!address) {
      alert('Please connect your wallet to submit a data broker');
      return;
    }

    setSubmitting(true);
    try {
      // TODO: Integrate with smart contract
      console.log('Submitting broker:', formData);
      alert('Data broker submission would be sent to smart contract. This will earn you 100 RN tokens!');
      setFormData({ name: '', website: '', removalInstructions: '' });
      setShowForm(false);
    } catch (error) {
      console.error('Error submitting broker:', error);
      alert('Error submitting broker');
    } finally {
      setSubmitting(false);
    }
  };

  const formatAddress = (address: string): string => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Data Brokers</h1>
          <p className="text-gray-600 mt-2">
            Community-sourced database of data brokers and their removal procedures
          </p>
        </div>
        {address && (
          <button
            onClick={() => setShowForm(!showForm)}
            className="btn"
          >
            {showForm ? 'Cancel' : 'Submit New Broker'}
          </button>
        )}
      </div>

      {/* Submission Form */}
      {showForm && (
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Submit New Data Broker</h2>
          <p className="text-gray-600 mb-6">
            Earn <strong className="text-ninja-600">100 RN tokens</strong> for each verified data broker submission
          </p>
          
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="form-group">
              <label className="form-label">Broker Name *</label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                className="form-input"
                placeholder="e.g., Acxiom, LexisNexis, Spokeo"
                required
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
                placeholder="https://example.com"
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Removal Instructions *</label>
              <textarea
                name="removalInstructions"
                value={formData.removalInstructions}
                onChange={handleInputChange}
                className="form-textarea"
                placeholder="Detailed steps for data removal, including URLs, forms, or contact information"
                required
              />
            </div>

            <div className="flex gap-4">
              <button
                type="submit"
                disabled={submitting}
                className="btn flex items-center gap-2"
              >
                {submitting && <div className="loading"></div>}
                Submit Broker
              </button>
              <button
                type="button"
                onClick={() => setShowForm(false)}
                className="btn-secondary"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div className="card text-center">
          <div className="text-2xl font-bold text-ninja-600">{brokers.length}</div>
          <div className="text-gray-600">Total Brokers</div>
        </div>
        <div className="card text-center">
          <div className="text-2xl font-bold text-green-600">
            {brokers.filter(b => b.verified).length}
          </div>
          <div className="text-gray-600">Verified</div>
        </div>
        <div className="card text-center">
          <div className="text-2xl font-bold text-ninja-600">100</div>
          <div className="text-gray-600">RN Reward per Submission</div>
        </div>
      </div>

      {/* Brokers List */}
      <div className="space-y-4">
        <h2 className="text-xl font-semibold">All Data Brokers</h2>
        
        {loading ? (
          <div className="flex justify-center py-8">
            <div className="loading"></div>
          </div>
        ) : (
          <div className="space-y-4">
            {brokers.map((broker) => (
              <div
                key={broker.id}
                className={`card border-l-4 ${
                  broker.verified ? 'border-l-green-500' : 'border-l-yellow-500'
                }`}
              >
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-lg font-semibold">{broker.name}</h3>
                    <a
                      href={broker.website}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-ninja-600 hover:text-ninja-700"
                    >
                      {broker.website}
                    </a>
                  </div>
                  <div className="flex gap-2">
                    <span className={`status-badge ${
                      broker.verified ? 'status-verified' : 'status-pending'
                    }`}>
                      {broker.verified ? 'Verified' : 'Pending'}
                    </span>
                  </div>
                </div>

                <div className="mb-4">
                  <h4 className="font-medium mb-2">Removal Instructions:</h4>
                  <p className="text-gray-600">{broker.removalInstructions}</p>
                </div>

                <div className="text-sm text-gray-500 border-t pt-3">
                  <div className="flex justify-between">
                    <span>Submitted by: {formatAddress(broker.submittedBy)}</span>
                    <span>Date: {broker.dateSubmitted}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {!address && (
        <div className="card text-center">
          <h3 className="text-lg font-semibold mb-2">Connect Your Wallet</h3>
          <p className="text-gray-600">
            Connect your wallet to submit new data brokers and earn RN tokens
          </p>
        </div>
      )}
    </div>
  );
};

export default DataBrokers;
