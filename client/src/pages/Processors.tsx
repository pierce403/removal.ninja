import React from 'react';
import { Link } from 'react-router-dom';
import { useAddress } from '@thirdweb-dev/react';

const Processors: React.FC = () => {
  const address = useAddress();

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="card text-center">
        <h1 className="text-3xl font-bold mb-4">Become a Trusted Processor</h1>
        <p className="text-lg text-gray-600 max-w-3xl mx-auto">
          Earn tokens by processing removal requests for users. Processors are vetted 
          entities that users trust to handle their sensitive personal information 
          and execute data removal requests.
        </p>
      </div>

      {/* How It Works */}
      <div className="card">
        <h2 className="text-2xl font-semibold mb-6">How the Processor Network Works</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div>
            <h3 className="text-lg font-semibold mb-3 text-ninja-600">🔒 User-Selected Trust</h3>
            <p className="text-gray-600 mb-4">
              Users choose which processors they trust with their personal information. 
              This creates a competitive marketplace where reputation matters.
            </p>
          </div>
          <div>
            <h3 className="text-lg font-semibold mb-3 text-ninja-600">🛡️ Staking & Slashing</h3>
            <p className="text-gray-600 mb-4">
              Processors stake significant collateral that can be slashed for poor performance, 
              ensuring alignment with user interests.
            </p>
          </div>
          <div>
            <h3 className="text-lg font-semibold mb-3 text-ninja-600">📧 zkEmail Verification</h3>
            <p className="text-gray-600 mb-4">
              Completion is verified through zkEmail proofs of removal confirmations, 
              providing trustless verification without revealing email contents.
            </p>
          </div>
          <div>
            <h3 className="text-lg font-semibold mb-3 text-ninja-600">💰 Token Rewards</h3>
            <p className="text-gray-600 mb-4">
              Earn 50 RN tokens for each successfully completed and verified removal request.
            </p>
          </div>
        </div>
      </div>

      {/* Requirements */}
      <div className="card">
        <h2 className="text-2xl font-semibold mb-6">Processor Requirements</h2>
        <div className="space-y-4">
          <div className="flex items-start gap-4">
            <div className="bg-ninja-100 text-ninja-600 rounded-full p-2 min-w-fit">
              <span className="text-lg font-bold">🪙</span>
            </div>
            <div>
              <h3 className="font-semibold">Minimum Stake: 1,000 RN Tokens</h3>
              <p className="text-gray-600">Stake tokens as collateral that can be slashed for poor performance</p>
            </div>
          </div>
          
          <div className="flex items-start gap-4">
            <div className="bg-ninja-100 text-ninja-600 rounded-full p-2 min-w-fit">
              <span className="text-lg font-bold">🤝</span>
            </div>
            <div>
              <h3 className="font-semibold">Trusted by Users</h3>
              <p className="text-gray-600">Build reputation to be selected by users for handling sensitive information</p>
            </div>
          </div>
          
          <div className="flex items-start gap-4">
            <div className="bg-ninja-100 text-ninja-600 rounded-full p-2 min-w-fit">
              <span className="text-lg font-bold">⚡</span>
            </div>
            <div>
              <h3 className="font-semibold">Efficient Processing</h3>
              <p className="text-gray-600">Process removal requests promptly and accurately</p>
            </div>
          </div>
          
          <div className="flex items-start gap-4">
            <div className="bg-ninja-100 text-ninja-600 rounded-full p-2 min-w-fit">
              <span className="text-lg font-bold">🛡️</span>
            </div>
            <div>
              <h3 className="font-semibold">Maintain Good Standing</h3>
              <p className="text-gray-600">Avoid slashing penalties by maintaining high success rates</p>
            </div>
          </div>
        </div>
      </div>

      {/* Process Steps */}
      <div className="card">
        <h2 className="text-2xl font-semibold mb-6">Getting Started Process</h2>
        <div className="space-y-6">
          <div className="flex items-center gap-4">
            <div className="bg-ninja-600 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold">
              1
            </div>
            <div>
              <h3 className="font-semibold">Stake Your Tokens</h3>
              <p className="text-gray-600">Stake 1,000+ RN tokens to join the processor network</p>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="bg-ninja-600 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold">
              2
            </div>
            <div>
              <h3 className="font-semibold">Build Your Profile</h3>
              <p className="text-gray-600">Create a compelling processor profile that users will trust</p>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="bg-ninja-600 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold">
              3
            </div>
            <div>
              <h3 className="font-semibold">Get Selected by Users</h3>
              <p className="text-gray-600">Users will choose you as their trusted processor during onboarding</p>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="bg-ninja-600 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold">
              4
            </div>
            <div>
              <h3 className="font-semibold">Process & Earn</h3>
              <p className="text-gray-600">Handle removal requests and earn 50 RN tokens per verified completion</p>
            </div>
          </div>
        </div>
      </div>

      {/* CTA */}
      {address ? (
        <div className="card text-center">
          <h2 className="text-xl font-semibold mb-4">Ready to Get Started?</h2>
          <p className="text-gray-600 mb-6">
            Join the trusted processor network and start earning tokens for helping protect user privacy.
          </p>
          <Link to="/processor-dashboard" className="btn">
            Processor Dashboard
          </Link>
        </div>
      ) : (
        <div className="card text-center">
          <h3 className="text-lg font-semibold mb-2">Connect Your Wallet</h3>
          <p className="text-gray-600">
            Connect your wallet to join the trusted processor network and start earning RN tokens.
          </p>
        </div>
      )}
    </div>
  );
};

export default Processors;
