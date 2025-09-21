#!/usr/bin/env node
/**
 * Development setup script for removal.ninja
 * This script helps set up the development environment and provides mock data
 * when blockchain is not available.
 */

const fs = require('fs');
const path = require('path');

console.log('🥷 Setting up removal.ninja development environment...\n');

// Create mock contract address file for development
const mockContractInfo = {
  contractAddress: '0x1234567890123456789012345678901234567890',
  deploymentTime: new Date().toISOString(),
  network: 'localhost',
  mock: true
};

const contractInfoPath = path.join(__dirname, '../server/contract-address.json');
fs.writeFileSync(contractInfoPath, JSON.stringify(mockContractInfo, null, 2));
console.log('✅ Created mock contract configuration');

// Create sample environment file
const envPath = path.join(__dirname, '../.env');
if (!fs.existsSync(envPath)) {
  const envContent = `# Development environment for removal.ninja
PORT=5000
NODE_ENV=development
RPC_URL=http://localhost:8545

# Mock mode - set to true for development without blockchain
MOCK_MODE=true
`;
  fs.writeFileSync(envPath, envContent);
  console.log('✅ Created .env file');
} else {
  console.log('ℹ️  .env file already exists');
}

// Create mock data directory
const mockDataDir = path.join(__dirname, '../server/mock-data');
if (!fs.existsSync(mockDataDir)) {
  fs.mkdirSync(mockDataDir, { recursive: true });
  
  // Create mock brokers data
  const mockBrokers = [
    {
      id: "1",
      name: "DataBroker Corp",
      website: "https://databroker-corp.example.com",
      removalInstructions: "Email privacy@databroker-corp.com with your request",
      submitter: "0x1234567890123456789012345678901234567890",
      verified: true,
      timestamp: new Date().toISOString()
    },
    {
      id: "2", 
      name: "InfoMiner Ltd",
      website: "https://infominer-ltd.example.com",
      removalInstructions: "Fill out the form at infominer-ltd.com/privacy/removal",
      submitter: "0x0987654321098765432109876543210987654321",
      verified: true,
      timestamp: new Date().toISOString()
    },
    {
      id: "3",
      name: "Personal Data Exchange",
      website: "https://pdx.example.com", 
      removalInstructions: "Call 1-800-PRIVACY during business hours",
      submitter: "0xabcdef1234567890abcdef1234567890abcdef12",
      verified: false,
      timestamp: new Date().toISOString()
    }
  ];
  
  fs.writeFileSync(
    path.join(mockDataDir, 'brokers.json'),
    JSON.stringify(mockBrokers, null, 2)
  );
  console.log('✅ Created mock data brokers');
}

console.log('\n📦 Development environment ready!');
console.log('\n🚀 To start the application:');
console.log('   npm run dev                   # Start both frontend and backend');
console.log('   npm run server:dev            # Start backend only');
console.log('   npm run client:dev            # Start frontend only');

console.log('\n🔗 Access points:');
console.log('   Frontend: http://localhost:3000');
console.log('   Backend:  http://localhost:5000');

console.log('\n💡 For full blockchain functionality:');
console.log('   1. cd contracts && npx hardhat node');
console.log('   2. cd contracts && npx hardhat run scripts/deploy.js --network localhost');
console.log('   3. Set MOCK_MODE=false in .env');

console.log('\n✨ Happy coding!');