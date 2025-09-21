import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { ThirdwebProvider, metamaskWallet, coinbaseWallet, rainbowWallet, walletConnect } from '@thirdweb-dev/react';
import { BaseSepoliaTestnet } from '@thirdweb-dev/chains';
import Header from './components/Header';
import Home from './pages/Home';
import DataBrokers from './pages/DataBrokers';
import Processors from './pages/Processors';
import UserDashboard from './pages/UserDashboard';
import ProcessorDashboard from './pages/ProcessorDashboard';

// Base Sepolia testnet configuration
const ACTIVE_CHAIN = BaseSepoliaTestnet;

function App() {
  return (
    <ThirdwebProvider
      activeChain={ACTIVE_CHAIN}
      clientId={process.env.REACT_APP_THIRDWEB_CLIENT_ID}
      supportedWallets={[
        metamaskWallet(),
        coinbaseWallet(),
        rainbowWallet(),
        walletConnect(),
      ]}
    >
      <div className="min-h-screen bg-gray-50">
        <Header />
        <main className="container py-8">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/brokers" element={<DataBrokers />} />
            <Route path="/processors" element={<Processors />} />
            <Route path="/dashboard" element={<UserDashboard />} />
            <Route path="/processor-dashboard" element={<ProcessorDashboard />} />
          </Routes>
        </main>
      </div>
    </ThirdwebProvider>
  );
}

export default App;
