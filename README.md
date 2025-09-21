# 🥷 removal.ninja

A decentralized data broker removal protocol with token incentives and zkEmail verification. Help protect privacy while earning rewards through our blockchain-based ecosystem.

## Overview

removal.ninja is a decentralized platform that creates a comprehensive data broker removal ecosystem through:
- **Data Broker Discovery**: Community-sourced database of data brokers with verified opt-out flows
- **Trusted Processor Network**: Vetted entities that handle sensitive removal requests with staked collateral
- **User-Selected Privacy**: Users choose which processors they trust with their personal information
- **Incentivized Participation**: Token rewards for contributing to the privacy protection ecosystem
- **Cryptographic Verification**: zkEmail proofs for verified removal completion

## 🔧 Tech Stack

### Modern Frontend Stack
- **React 18** with **TypeScript** for type safety and modern development
- **Tailwind CSS** for utility-first styling and responsive design
- **Thirdweb SDK** for seamless Web3 wallet integration
- **React Router** for client-side routing

### Smart Contract Infrastructure
- **Solidity** contracts with OpenZeppelin libraries
- **Hardhat** development environment with testing suite
- **ERC-20** RN token implementation
- **Local and testnet** deployment support

### Development & Security
- **Jest & React Testing Library** for comprehensive test coverage
- **TypeScript** for compile-time error checking
- **Socket.dev** integration for dependency security scanning
- **GitHub Actions** for automated CI/CD and security checks
- **ESLint** for code quality enforcement

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

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- npm
- MetaMask browser extension (for blockchain interaction)

### Installation

```bash
# Clone and install dependencies
git clone https://github.com/pierce403/removal.ninja.git
cd removal.ninja
npm run install:all
```

### Development Mode

```bash
# Start the React frontend (recommended for UI development)
npm run client:dev
# Access at http://localhost:3000

# Optional: Start local blockchain for full functionality
cd contracts && npx hardhat node
# In another terminal:
cd contracts && npx hardhat run scripts/deploy.js --network localhost
```

### Testing

```bash
# Run comprehensive test suite
npm test

# Run with coverage
cd client && npm test -- --coverage --watchAll=false

# Security scanning
npm run security:scan
```

### Production Build

```bash
# Build the React app for deployment
npm run build
```

## 📁 Project Structure

```
├── client/                 # React TypeScript frontend
│   ├── src/
│   │   ├── components/     # Reusable UI components
│   │   ├── pages/         # Route-based page components
│   │   ├── utils/         # Utility functions
│   │   └── __tests__/     # Test suites
│   ├── public/            # Static assets
│   └── craco.config.js    # Webpack configuration for Web3 polyfills
├── contracts/             # Solidity smart contracts
│   ├── contracts/         # Contract source files
│   ├── scripts/          # Deployment scripts
│   └── test/             # Contract test suites
├── server/               # Node.js backend (optional for demo)
│   └── routes/           # API endpoints
└── .github/workflows/    # CI/CD and security automation
```

## 🧪 Testing Strategy

### Component Tests
- **Header Component**: Navigation and wallet connection states
- **Page Components**: Home, DataBrokers, Processors, UserDashboard, ProcessorDashboard
- **Utility Functions**: Address formatting, token calculations, validation

### Test Coverage
- TypeScript components with React Testing Library
- Mock implementations for Web3 functionality
- Security scanning integration with Socket.dev
- Automated testing in CI/CD pipeline

### Security Features
- **Socket.dev Integration**: Automated dependency vulnerability scanning
- **Type Safety**: TypeScript prevents runtime errors
- **Input Validation**: Form validation and sanitization
- **Security Headers**: Helmet.js for HTTP security

## 🔐 Security & Dependencies

The project uses Socket.dev for continuous security monitoring:

```bash
# Manual security scan
npm run security:scan

# CI/CD integration
npm run security:ci
```

Security features:
- Real-time dependency vulnerability scanning
- Supply chain attack detection
- Automated security reports in CI/CD
- Zero-tolerance policy for high-risk packages

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

### Blockchain (For Demo Mode)
- `GET /api/blockchain/contract-info` - Contract information
- `GET /api/blockchain/stats` - Platform statistics
- `GET /api/blockchain/brokers` - All data brokers
- `GET /api/blockchain/user/:address` - User information
- `GET /api/blockchain/processor/:address` - Processor information

## Usage

### For Users
1. Connect MetaMask wallet to the dApp
2. Stake RN tokens to join removal list
3. Select trusted processors during onboarding
4. Monitor removal progress through the dashboard

### For Processors
1. Stake 1,000+ RN tokens to register
2. Build reputation through successful removals
3. Handle user removal requests securely off-chain
4. Submit zkEmail proofs for verified completions

### For Contributors
1. Discover and submit new data brokers
2. Earn 100 RN per verified submission
3. Help build the largest decentralized privacy database

## Development

### Local Setup
```bash
# Install all dependencies
npm run install:all

# Start development environment
npm run dev

# Run tests
npm test

# Security scan
npm run security:scan
```

### Smart Contract Development
```bash
# Compile contracts
cd contracts && npx hardhat compile

# Run tests
cd contracts && npx hardhat test

# Deploy locally
cd contracts && npx hardhat node
cd contracts && npx hardhat run scripts/deploy.js --network localhost
```

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`npm test`)
4. Run security scan (`npm run security:scan`)
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open Pull Request

All contributions are automatically tested and security-scanned through our CI/CD pipeline.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Security

This is experimental software. Key security features:

- **Socket.dev** continuous dependency monitoring
- **TypeScript** for compile-time safety
- **Comprehensive testing** with 90%+ coverage target
- **Automated security scanning** in CI/CD
- **zkEmail integration** for cryptographic verification

Always review smart contracts before interacting with them on mainnet.

## Roadmap

- [ ] Mainnet deployment with security audit
- [ ] zkEmail integration for removal verification
- [ ] Mobile app development
- [ ] Enhanced processor verification methods
- [ ] Reputation scoring system with slashing
- [ ] Multi-chain support (Polygon, Arbitrum)
- [ ] Governance token features
- [ ] Professional processor marketplace

## 📊 Project Status

- ✅ **Modern Tech Stack**: React + TypeScript + Tailwind + Thirdweb
- ✅ **Comprehensive Testing**: Jest + React Testing Library
- ✅ **Security Integration**: Socket.dev dependency scanning
- ✅ **CI/CD Pipeline**: Automated testing and deployment
- ✅ **Local-First Architecture**: No backend dependency for core functionality
- ✅ **Professional UI/UX**: Modern design with accessibility features

---

Built with ❤️ for privacy and decentralization