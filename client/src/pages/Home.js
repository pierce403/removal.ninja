import React from 'react';
import { Link } from 'react-router-dom';
import { useWallet } from '../hooks/useWallet';
import styled from 'styled-components';

const Hero = styled.section`
  text-align: center;
  padding: 4rem 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 12px;
  margin-bottom: 3rem;
`;

const Title = styled.h1`
  font-size: 3rem;
  margin-bottom: 1rem;
  font-weight: 700;
`;

const Subtitle = styled.p`
  font-size: 1.2rem;
  margin-bottom: 2rem;
  opacity: 0.9;
`;

const Features = styled.section`
  margin: 3rem 0;
`;

const FeatureGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  margin-top: 2rem;
`;

const FeatureCard = styled.div`
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  text-align: center;
`;

const FeatureIcon = styled.div`
  font-size: 3rem;
  margin-bottom: 1rem;
`;

const Stats = styled.section`
  background: white;
  padding: 2rem;
  border-radius: 8px;
  margin: 2rem 0;
`;

const StatsGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 2rem;
  text-align: center;
`;

const StatItem = styled.div`
  h3 {
    font-size: 2rem;
    color: #007bff;
    margin-bottom: 0.5rem;
  }
  
  p {
    color: #666;
    font-weight: 500;
  }
`;

const Home = () => {
  const { account } = useWallet();

  return (
    <div>
      <Hero>
        <Title>🥷 removal.ninja</Title>
        <Subtitle>
          Decentralized data broker removal with token incentives
        </Subtitle>
        {!account && (
          <p>Connect your wallet to get started with decentralized privacy protection</p>
        )}
      </Hero>

      <Features>
        <h2 className="text-center mb-4">How It Works</h2>
        <FeatureGrid>
          <FeatureCard>
            <FeatureIcon>📋</FeatureIcon>
            <h3>Submit Data Brokers</h3>
            <p>
              Find and submit new data brokers to the platform. 
              Earn <strong>100 RN tokens</strong> for each verified submission.
            </p>
            <Link to="/brokers" className="btn mt-2">
              View Brokers
            </Link>
          </FeatureCard>

          <FeatureCard>
            <FeatureIcon>🔒</FeatureIcon>
            <h3>Stake for Removal</h3>
            <p>
              Stake tokens to get added to the removal list. 
              Choose trusted processors to handle your removals.
            </p>
            <Link to="/dashboard" className="btn mt-2">
              Get Started
            </Link>
          </FeatureCard>

          <FeatureCard>
            <FeatureIcon>⚡</FeatureIcon>
            <h3>Process Removals</h3>
            <p>
              Become a trusted processor. Stake tokens and earn 
              <strong>50 RN tokens</strong> for each completed removal.
            </p>
            <Link to="/processors" className="btn mt-2">
              Become Processor
            </Link>
          </FeatureCard>
        </FeatureGrid>
      </Features>

      <Stats>
        <h2 className="text-center mb-3">Platform Stats</h2>
        <StatsGrid>
          <StatItem>
            <h3>🎯</h3>
            <p>Data Brokers Tracked</p>
          </StatItem>
          <StatItem>
            <h3>👥</h3>
            <p>Active Processors</p>
          </StatItem>
          <StatItem>
            <h3>✅</h3>
            <p>Removals Completed</p>
          </StatItem>
          <StatItem>
            <h3>🪙</h3>
            <p>RN Tokens Distributed</p>
          </StatItem>
        </StatsGrid>
      </Stats>

      <div className="card text-center">
        <h2>Ready to Protect Your Privacy?</h2>
        <p className="mb-3">
          Join the decentralized movement for data privacy. 
          Earn tokens while helping others remove their data from brokers.
        </p>
        {account ? (
          <div>
            <Link to="/dashboard" className="btn mr-2">
              User Dashboard
            </Link>
            <Link to="/processors" className="btn btn-secondary">
              Become Processor
            </Link>
          </div>
        ) : (
          <p>
            <strong>Connect your wallet above to get started</strong>
          </p>
        )}
      </div>
    </div>
  );
};

export default Home;