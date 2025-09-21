import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { WalletProvider } from './hooks/useWallet';
import Header from './components/Header';
import Home from './pages/Home';
import DataBrokers from './pages/DataBrokers';
import Processors from './pages/Processors';
import UserDashboard from './pages/UserDashboard';
import ProcessorDashboard from './pages/ProcessorDashboard';

function App() {
  return (
    <WalletProvider>
      <div className="App">
        <Header />
        <main className="container">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/brokers" element={<DataBrokers />} />
            <Route path="/processors" element={<Processors />} />
            <Route path="/dashboard" element={<UserDashboard />} />
            <Route path="/processor-dashboard" element={<ProcessorDashboard />} />
          </Routes>
        </main>
      </div>
    </WalletProvider>
  );
}

export default App;