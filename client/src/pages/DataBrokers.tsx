import React, { useState, useEffect, useCallback } from 'react';
import { useAddress, useContract, useContractRead, useContractWrite } from '@thirdweb-dev/react';
import { getRegistryAddress } from '../config/contracts';
import { DataBroker, AddBrokerForm, WEIGHT_LABELS, WEIGHT_COLORS } from '../types/contracts';

// Simple ABI for DataBrokerRegistryUltraSimple contract
const REGISTRY_ABI = [
  "function addBroker(string calldata name, string calldata website, string calldata removalLink, string calldata contact, uint256 weight) external returns (uint256)",
  "function brokers(uint256) external view returns (uint256 id, string name, string website, string removalLink, string contact, uint256 weight, bool isActive, uint256 totalRemovals, uint256 totalDisputes)",
  "function getStats() external view returns (uint256 totalBrokers, uint256 activeBrokers)",
  "function nextBrokerId() external view returns (uint256)"
];

const DataBrokers: React.FC = () => {
  const address = useAddress();
  
  // Contract hooks
  const { contract } = useContract(getRegistryAddress(), REGISTRY_ABI);
  const { data: nextBrokerId } = useContractRead(contract, "nextBrokerId");
  const { data: stats } = useContractRead(contract, "getStats");
  const { mutateAsync: addBroker } = useContractWrite(contract, "addBroker");
  
  // Component state
  const [brokers, setBrokers] = useState<DataBroker[]>([]);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState<AddBrokerForm>({
    name: '',
    website: '',
    removalLink: '',
    contact: '',
    weight: '300' // Default to high impact
  });

  // Fetch brokers from contract
  const fetchBrokers = useCallback(async () => {
    if (!contract || !nextBrokerId) return;
    
    setLoading(true);
    try {
      const brokersData: DataBroker[] = [];
      
      // Fetch each broker by ID (starting from 1)
      for (let i = 1; i < Number(nextBrokerId); i++) {
        try {
          const brokerData = await contract.call("brokers", [i]);
          if (brokerData && brokerData[6]) { // isActive is at index 6
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
    } finally {
      setLoading(false);
    }
  }, [contract, nextBrokerId]);

  // Load brokers on component mount and when contract data changes
  useEffect(() => {
    fetchBrokers();
  }, [contract, nextBrokerId, fetchBrokers]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
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

    if (!contract) {
      alert('Contract not loaded. Please try again.');
      return;
    }

    setSubmitting(true);
    try {
      // Call the addBroker function on the contract
      const result = await addBroker({
        args: [
          formData.name,
          formData.website,
          formData.removalLink,
          formData.contact,
          parseInt(formData.weight)
        ]
      });

      console.log('Broker submitted successfully:', result);
      alert(`Data broker "${formData.name}" submitted successfully! 🎉`);
      
      // Reset form and refresh data
      setFormData({ 
        name: '', 
        website: '', 
        removalLink: '', 
        contact: '', 
        weight: '300' 
      });
      setShowForm(false);
      
      // Refresh brokers list
      setTimeout(fetchBrokers, 2000); // Give some time for the transaction to be mined
      
    } catch (error: any) {
      console.error('Error submitting broker:', error);
      const errorMessage = error?.reason || error?.message || 'Unknown error occurred';
      alert(`Error submitting broker: ${errorMessage}`);
    } finally {
      setSubmitting(false);
    }
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
              <label className="form-label">Removal Link *</label>
              <input
                type="url"
                name="removalLink"
                value={formData.removalLink}
                onChange={handleInputChange}
                className="form-input"
                placeholder="https://example.com/optout"
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Contact Information *</label>
              <input
                type="text"
                name="contact"
                value={formData.contact}
                onChange={handleInputChange}
                className="form-input"
                placeholder="privacy@example.com or phone number"
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Impact Level *</label>
              <select
                name="weight"
                value={formData.weight}
                onChange={handleInputChange}
                className="form-input"
                required
              >
                <option value="100">Standard Impact (1x reward)</option>
                <option value="200">Medium Impact (2x reward)</option>
                <option value="300">High Impact (3x reward)</option>
              </select>
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
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="card text-center">
          <div className="text-2xl font-bold text-ninja-600">
            {stats ? Number(stats[0]) : brokers.length}
          </div>
          <div className="text-gray-600">Total Brokers</div>
        </div>
        <div className="card text-center">
          <div className="text-2xl font-bold text-green-600">
            {stats ? Number(stats[1]) : brokers.filter(b => b.isActive).length}
          </div>
          <div className="text-gray-600">Active</div>
        </div>
        <div className="card text-center">
          <div className="text-2xl font-bold text-red-600">
            {brokers.filter(b => b.weight >= 300).length}
          </div>
          <div className="text-gray-600">High Impact</div>
        </div>
        <div className="card text-center">
          <div className="text-2xl font-bold text-ninja-600">100</div>
          <div className="text-gray-600">RN Reward Base</div>
        </div>
      </div>

      {/* Brokers List */}
      <div className="space-y-4">
        <h2 className="text-xl font-semibold">All Data Brokers</h2>
        
        {loading ? (
          <div className="flex justify-center py-8">
            <div className="loading"></div>
          </div>
        ) : brokers.length === 0 ? (
          <div className="card text-center">
            <h3 className="text-lg font-semibold mb-2">No Data Brokers Found</h3>
            <p className="text-gray-600 mb-4">
              Be the first to submit a data broker and earn RN tokens!
            </p>
            {address && (
              <button
                onClick={() => setShowForm(true)}
                className="btn"
              >
                Submit First Broker
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-4">
            {brokers.map((broker) => (
              <div
                key={broker.id}
                className={`card border-l-4 ${
                  broker.isActive ? 'border-l-green-500' : 'border-l-gray-400'
                } ${broker.weight >= 300 ? 'bg-red-50' : ''}`}
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
                      broker.isActive ? 'status-verified' : 'status-pending'
                    }`}>
                      {broker.isActive ? 'Active' : 'Inactive'}
                    </span>
                    <span className={`status-badge ${WEIGHT_COLORS[broker.weight] || 'bg-gray-100 text-gray-800'}`}>
                      {WEIGHT_LABELS[broker.weight] || `${broker.weight}x`}
                    </span>
                  </div>
                </div>

                <div className="mb-4 space-y-2">
                  <div>
                    <span className="font-medium">Removal Link: </span>
                    <a
                      href={broker.removalLink}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-ninja-600 hover:text-ninja-700"
                    >
                      {broker.removalLink}
                    </a>
                  </div>
                  <div>
                    <span className="font-medium">Contact: </span>
                    <span className="text-gray-600">{broker.contact}</span>
                  </div>
                </div>

                <div className="text-sm text-gray-500 border-t pt-3">
                  <div className="flex justify-between">
                    <span>Removals: {broker.totalRemovals}</span>
                    <span>Disputes: {broker.totalDisputes}</span>
                    <span>Weight: {broker.weight / 100}x multiplier</span>
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
