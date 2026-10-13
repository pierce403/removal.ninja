import React from 'react';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import App from '../App';

// Mock the v5 provider and wallet adapter without creating network clients.
vi.mock('thirdweb/react', () => ({
  ThirdwebProvider: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="thirdweb-provider">{children}</div>
  ),
}));
vi.mock('../web3/thirdwebCompat', () => ({
  useAddress: vi.fn(() => null),
  useDisconnect: vi.fn(),
  ConnectWallet: vi.fn(() => <button>Connect Wallet</button>),
  useContract: vi.fn(() => ({ contract: { call: vi.fn() } })),
  useContractRead: vi.fn(() => ({ data: undefined })),
  useContractWrite: vi.fn(() => ({ mutateAsync: vi.fn() })),
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
    expect(screen.getAllByText('🥷 removal.ninja').length).toBeGreaterThan(0);
    expect(screen.getByText('Data Brokers')).toBeInTheDocument();
    expect(screen.getByText('Processors')).toBeInTheDocument();
  });
});
