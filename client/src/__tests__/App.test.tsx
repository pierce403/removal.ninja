import React from 'react';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import App from '../App';

// Mock Thirdweb provider to avoid polyfill issues in tests
jest.mock('@thirdweb-dev/react', () => ({
  ThirdwebProvider: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="thirdweb-provider">{children}</div>
  ),
  metamaskWallet: jest.fn(),
  coinbaseWallet: jest.fn(),
  walletConnect: jest.fn(),
  useAddress: jest.fn(() => null),
  useDisconnect: jest.fn(),
  useConnectionStatus: jest.fn(() => 'disconnected'),
  ConnectWallet: jest.fn(() => <button>Connect Wallet</button>),
}));

describe('App Component', () => {
  test('renders without crashing', () => {
    render(
      <BrowserRouter>
        <App />
      </BrowserRouter>
    );
    
    expect(screen.getByTestId('thirdweb-provider')).toBeInTheDocument();
  });

  test('displays main navigation elements', () => {
    render(
      <BrowserRouter>
        <App />
      </BrowserRouter>
    );
    
    // Check if header navigation is present
    expect(screen.getByText('🥷 removal.ninja')).toBeInTheDocument();
    expect(screen.getByText('Data Brokers')).toBeInTheDocument();
    expect(screen.getByText('Processors')).toBeInTheDocument();
  });
});
