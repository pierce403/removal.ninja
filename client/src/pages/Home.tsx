import React from 'react';
import { Link } from 'react-router-dom';
import { useAddress } from '@thirdweb-dev/react';

const Home: React.FC = () => {
  const address = useAddress();

  return (
    <div className="space-y-12">
      {/* Hero Section */}
      <section className="text-center py-16 gradient-bg text-white rounded-xl">
        <h1 className="text-5xl font-bold mb-4">🥷 removal.ninja</h1>
        <p className="text-xl mb-8 opacity-90 max-w-2xl mx-auto">
          Decentralized data broker removal with token incentives and zkEmail verification
        </p>
        {!address && (
          <p className="text-lg opacity-80">
            Connect your wallet to get started with decentralized privacy protection
          </p>
        )}
      </section>

      {/* Features Section */}
      <section>
        <h2 className="text-3xl font-bold text-center mb-8">How It Works</h2>
        <div className="grid grid-3 gap-8">
          <div className="card text-center">
            <div className="text-5xl mb-4">📋</div>
            <h3 className="text-xl font-semibold mb-4">Submit Data Brokers</h3>
            <p className="text-gray-600 mb-6">
              Find and submit new data brokers to the platform. 
              Earn <strong className="text-ninja-600">100 RN tokens</strong> for each verified submission.
            </p>
            <Link to="/brokers" className="btn">
              View Brokers
            </Link>
          </div>

          <div className="card text-center">
            <div className="text-5xl mb-4">🔒</div>
            <h3 className="text-xl font-semibold mb-4">Stake for Removal</h3>
            <p className="text-gray-600 mb-6">
              Stake tokens to get added to the removal list. 
              Choose trusted processors to handle your removals.
            </p>
            <Link to="/dashboard" className="btn">
              Get Started
            </Link>
          </div>

          <div className="card text-center">
            <div className="text-5xl mb-4">⚡</div>
            <h3 className="text-xl font-semibold mb-4">Process Removals</h3>
            <p className="text-gray-600 mb-6">
              Become a trusted processor. Stake tokens and earn{' '}
              <strong className="text-ninja-600">50 RN tokens</strong> for each completed removal.
            </p>
            <Link to="/processors" className="btn">
              Become Processor
            </Link>
          </div>
        </div>
      </section>

      {/* Protocol Design Section */}
      <section className="card">
        <h2 className="text-2xl font-bold mb-6 text-center">Protocol Architecture</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div>
            <h3 className="text-lg font-semibold mb-3 text-ninja-600">🔄 Trusted Processor Network</h3>
            <p className="text-gray-600 mb-4">
              Processors stake significant collateral and compete to provide privacy services.
              Users select which processors they trust with their sensitive information.
            </p>
          </div>
          <div>
            <h3 className="text-lg font-semibold mb-3 text-ninja-600">🔐 zkEmail Verification</h3>
            <p className="text-gray-600 mb-4">
              Removal confirmations are verified cryptographically using zkEmail proofs,
              ensuring processors are paid only for successful removals.
            </p>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="card">
        <h2 className="text-2xl font-bold text-center mb-8">Platform Stats</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
          <div>
            <div className="text-3xl text-ninja-600 font-bold mb-2">🎯</div>
            <p className="text-gray-600 font-medium">Data Brokers Tracked</p>
          </div>
          <div>
            <div className="text-3xl text-ninja-600 font-bold mb-2">👥</div>
            <p className="text-gray-600 font-medium">Active Processors</p>
          </div>
          <div>
            <div className="text-3xl text-ninja-600 font-bold mb-2">✅</div>
            <p className="text-gray-600 font-medium">Removals Completed</p>
          </div>
          <div>
            <div className="text-3xl text-ninja-600 font-bold mb-2">🪙</div>
            <p className="text-gray-600 font-medium">RN Tokens Distributed</p>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <div className="card text-center">
        <h2 className="text-2xl font-bold mb-4">Ready to Protect Your Privacy?</h2>
        <p className="text-gray-600 mb-6 max-w-2xl mx-auto">
          Join the decentralized movement for data privacy. 
          Earn tokens while helping others remove their data from brokers through 
          our trusted processor network.
        </p>
        {address ? (
          <div className="space-x-4">
            <Link to="/dashboard" className="btn">
              User Dashboard
            </Link>
            <Link to="/processors" className="btn-secondary">
              Become Processor
            </Link>
          </div>
        ) : (
          <p className="text-lg">
            <strong className="text-ninja-600">Connect your wallet above to get started</strong>
          </p>
        )}
      </div>
    </div>
  );
};

export default Home;
