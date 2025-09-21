import React from 'react';
import { useWallet } from '../hooks/useWallet';

const Processors = () => {
  const { account } = useWallet();

  return (
    <div>
      <div className="card">
        <h1>Become a Processor</h1>
        <p>
          Earn tokens by processing removal requests for users. Processors are trusted 
          entities that help users remove their data from brokers.
        </p>
      </div>

      <div className="card">
        <h2>Processor Requirements</h2>
        <ul>
          <li>Minimum stake: <strong>1,000 RN tokens</strong></li>
          <li>Trusted by users to handle sensitive information</li>
          <li>Process removal requests efficiently</li>
          <li>Maintain good standing (avoid slashing)</li>
        </ul>
      </div>

      <div className="card">
        <h2>How It Works</h2>
        <ol>
          <li>Stake 1,000+ RN tokens to become a processor</li>
          <li>Users select you as their trusted processor</li>
          <li>Process removal requests and earn 50 RN per request</li>
          <li>Build reputation and attract more users</li>
        </ol>
      </div>

      {account ? (
        <div className="card">
          <h2>Get Started</h2>
          <p>Ready to become a processor? Visit the processor dashboard to register.</p>
          <a href="/processor-dashboard" className="btn">
            Processor Dashboard
          </a>
        </div>
      ) : (
        <div className="card text-center">
          <p>Connect your wallet to become a processor</p>
        </div>
      )}
    </div>
  );
};

export default Processors;