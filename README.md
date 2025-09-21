# 🥷 removal.ninja

A decentralized data broker removal tool with token incentives. Help protect privacy while earning rewards through our blockchain-based ecosystem.

## Overview

removal.ninja is a decentralized platform that incentivizes:
- **Data Broker Discovery**: Users earn 100 RN tokens for submitting new data brokers
- **Removal Processing**: Trusted processors earn 50 RN tokens for each completed removal
- **User Privacy Protection**: Users stake tokens to get comprehensive data removal services

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

## Architecture

```
├── contracts/          # Smart contracts (Solidity)
├── server/             # Backend API (Node.js/Express)
├── client/             # Frontend (React)
└── docs/               # Documentation
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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Security

This is experimental software. Use at your own risk. Always review smart contracts before interacting with them on mainnet.

## Roadmap

- [ ] Mainnet deployment
- [ ] Mobile app
- [ ] Additional processor verification methods
- [ ] Reputation scoring system
- [ ] Multi-chain support
- [ ] Governance token features