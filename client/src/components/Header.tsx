import React from 'react';
import { Link } from 'react-router-dom';
import { useAddress, useDisconnect, ConnectWallet } from '@thirdweb-dev/react';

const Header: React.FC = () => {
  const address = useAddress();
  const disconnect = useDisconnect();

  const formatAddress = (address: string): string => {
    if (!address) return '';
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  return (
    <header className="bg-white shadow-sm py-4 mb-8">
      <nav className="container flex justify-between items-center">
        <Link 
          to="/" 
          className="text-2xl font-bold text-ninja-600 hover:text-ninja-700 transition-colors"
        >
          🥷 removal.ninja
        </Link>
        
        <div className="flex gap-8 items-center">
          <Link 
            to="/brokers" 
            className="text-gray-700 hover:text-ninja-600 font-medium transition-colors"
          >
            Data Brokers
          </Link>
          <Link 
            to="/processors" 
            className="text-gray-700 hover:text-ninja-600 font-medium transition-colors"
          >
            Processors
          </Link>
          {address && (
            <>
              <Link 
                to="/dashboard" 
                className="text-gray-700 hover:text-ninja-600 font-medium transition-colors"
              >
                Dashboard
              </Link>
              <Link 
                to="/processor-dashboard" 
                className="text-gray-700 hover:text-ninja-600 font-medium transition-colors"
              >
                Processor
              </Link>
            </>
          )}
        </div>

        <div className="flex gap-4 items-center">
          {address ? (
            <>
              <div className="flex flex-col items-end text-sm">
                <span className="text-gray-600">{formatAddress(address)}</span>
                {/* TODO: Add token balance display when contract is integrated */}
              </div>
              <button 
                className="btn-secondary px-4 py-2 rounded-lg text-sm"
                onClick={disconnect}
              >
                Disconnect
              </button>
            </>
          ) : (
            <div className="[&>div]:!bg-ninja-600 [&>div]:hover:!bg-ninja-700">
              <ConnectWallet 
                theme="light"
                btnTitle="Connect Wallet"
                className="!bg-ninja-600 !hover:bg-ninja-700"
              />
            </div>
          )}
        </div>
      </nav>
    </header>
  );
};

export default Header;
