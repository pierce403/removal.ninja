# 🥷 removal.ninja

A decentralized data broker removal protocol with token incentives and zkEmail verification. Help protect privacy while earning rewards through our blockchain-based ecosystem.

## Overview

removal.ninja is a decentralized platform that creates a comprehensive data broker removal ecosystem through:
- **Data Broker Discovery**: Community-sourced database of data brokers with verified opt-out flows
- **Trusted Processor Network**: Vetted entities that handle sensitive removal requests with staked collateral
- **User-Selected Privacy**: Users choose which processors they trust with their personal information
- **Incentivized Participation**: Token rewards for contributing to the privacy protection ecosystem
- **Cryptographic Verification**: zkEmail proofs for verified removal completion

## Protocol Design

### 🔄 Removal Flow Architecture

**1. Data Broker Registry**
- Community members discover and submit new data brokers with their opt-out procedures
- Each submission includes website, removal instructions, and email verification endpoints
- Verified submissions earn contributors 100 RN tokens

**2. Trusted Processor Network**
- Processors stake significant collateral (1,000+ RN tokens) that can be slashed for poor performance
- Users select which processors they trust with their sensitive personal information
- Creates a competitive marketplace of privacy service providers

**3. User Privacy Journey**
- Users stake tokens (minimum 10 RN) to join the removal list
- During onboarding, users select their preferred trusted processors
- Users never need to share personal information on-chain
- Sensitive data is only shared with user-selected processors off-chain

**4. zkEmail Verification**
- Removal requests typically end with email confirmations from data brokers
- Processors use zkEmail proofs to cryptographically verify removal completions
- Provides trustless verification without revealing email contents
- Ensures processors are paid only for verified successful removals

**5. Incentive Alignment**
- Data broker submissions: **100 RN tokens**
- Successful removal processing: **50 RN tokens per removal**
- Processor slashing for non-performance protects user interests
- Token staking ensures skin-in-the-game for all participants

## Key Features

### 🎯 Data Broker Submission System
- Community-driven database of data brokers
- Token rewards for verified submissions
- Detailed removal instructions

### 🔒 Staking-Based Removal List
- Users stake RN tokens to access removal services
- Choose trusted processors for handling sensitive data
- Decentralized processor selection

### ⚡ Trusted Processor Network
- Processors stake tokens and can be slashed for poor performance
- Earn rewards for processing removal requests
- Build reputation through successful completions

### 🪙 Token Economics
- ERC-20 RN (RemovalNinja) token
- Staking mechanisms with slashing protection
- Automated reward distribution

## Tech Stack

### 🔗 Blockchain Layer
- **Smart Contracts**: Solidity with OpenZeppelin libraries
- **Development Framework**: Hardhat for compilation, testing, and deployment
- **Token Standard**: ERC-20 for RN (RemovalNinja) tokens
- **Network**: Ethereum-compatible (supports mainnet, testnets, and local development)

### ⚡ Backend Infrastructure
- **Runtime**: Node.js with Express.js framework
- **Blockchain Integration**: ethers.js for smart contract interactions
- **Security**: Helmet for HTTP security, express-rate-limit for API protection
- **Development**: Nodemon for hot-reloading, concurrently for multi-process management

### 🎨 Frontend
- **Framework**: React.js with modern hooks
- **Web3 Integration**: MetaMask wallet connection
- **Styling**: Custom CSS with responsive design
- **State Management**: React hooks for local state, context for global state

### 🔐 Cryptographic Components
- **zkEmail**: Zero-knowledge email verification (planned integration)
- **Wallet Integration**: MetaMask and other Web3 wallets
- **Digital Signatures**: Ethereum-standard message signing

### 🛠 Development Tools
- **Testing**: Jest for unit tests, Hardhat for smart contract testing
- **Linting**: ESLint for code quality
- **Package Management**: npm with lock files for reproducible builds
- **Version Control**: Git with GitHub workflows

### 📦 Deployment
- **Frontend**: GitHub Pages (static hosting)
- **Backend**: Node.js compatible platforms
- **Smart Contracts**: Deployable to any Ethereum-compatible network
- **Local Development**: Hardhat local network with hot-reloading

## Architecture

```
├── contracts/          # Solidity smart contracts with Hardhat framework
│   ├── contracts/      # RemovalNinja.sol main contract
│   ├── scripts/        # Deployment and interaction scripts
│   └── test/          # Smart contract test suites
├── server/             # Node.js/Express backend API
│   ├── routes/        # API endpoint handlers
│   ├── mock-data/     # Development mock data
│   └── index.js       # Main server entry point
├── client/             # React.js frontend application
│   ├── src/           # React components and pages
│   ├── public/        # Static assets
│   └── package.json   # Frontend dependencies
└── scripts/           # Development and setup utilities
```

## Quick Start

### Prerequisites
- Node.js 18+
- npm or yarn
- MetaMask wallet
- Local Ethereum node (or testnet)

### Installation

1. **Clone and install dependencies**
```bash
git clone https://github.com/pierce403/removal.ninja.git
cd removal.ninja
npm run install:all
```

2. **Deploy smart contracts**
```bash
cd contracts
npm install
npx hardhat node  # In separate terminal
npx hardhat run scripts/deploy.js --network localhost
```

3. **Start the application**
```bash
npm run dev  # Runs both server and client
```

4. **Access the application**
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000

## Smart Contract

The `RemovalNinja.sol` contract implements:

- **ERC-20 Token**: RN tokens for ecosystem rewards
- **Data Broker Registry**: On-chain broker submissions
- **Processor Staking**: Trusted processor registration with slashing
- **User Staking**: Removal list participation
- **Reward Distribution**: Automated token rewards

### Token Economics
- Broker Submission Reward: **100 RN**
- Removal Processing Reward: **50 RN**
- Minimum Processor Stake: **1,000 RN**
- Minimum User Stake: **10 RN**

## API Endpoints

### Blockchain
- `GET /api/blockchain/contract-info` - Contract information
- `GET /api/blockchain/stats` - Platform statistics
- `GET /api/blockchain/brokers` - All data brokers
- `GET /api/blockchain/user/:address` - User information
- `GET /api/blockchain/processor/:address` - Processor information

### Data Brokers
- `GET /api/brokers` - List all brokers
- `POST /api/brokers/submit` - Submit new broker

### Users & Processors
- `POST /api/users/stake` - Stake for removal list
- `POST /api/processors/register` - Register as processor
- `POST /api/removals/request` - Request removal

## Usage

### For Users
1. Connect MetaMask wallet
2. Stake RN tokens to join removal list
3. Select trusted processors
4. Request removals from data brokers

### For Processors
1. Stake 1,000+ RN tokens
2. Register as trusted processor
3. Process user removal requests
4. Earn 50 RN per completed removal

### For Contributors
1. Find and submit new data brokers
2. Earn 100 RN per verified submission
3. Help build the largest decentralized privacy database

## Development

### Running Tests
```bash
# Smart contract tests
cd contracts && npm test

# Server tests
npm test
```

### Local Development
```bash
# Terminal 1: Blockchain node
cd contracts && npx hardhat node

# Terminal 2: Deploy contracts
cd contracts && npx hardhat run scripts/deploy.js --network localhost

# Terminal 3: Start development server
npm run dev
```

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Security

This is experimental software. Use at your own risk. Always review smart contracts before interacting with them on mainnet.

## Roadmap

- [ ] Mainnet deployment
- [ ] Mobile app
- [ ] Additional processor verification methods
- [ ] Reputation scoring system
- [ ] Multi-chain support
- [ ] Governance token features