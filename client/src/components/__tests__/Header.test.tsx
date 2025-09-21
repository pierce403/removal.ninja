import React from 'react';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { ThirdwebProvider } from '@thirdweb-dev/react';
import Header from '../Header';

// Mock Thirdweb hooks
jest.mock('@thirdweb-dev/react', () => ({
  __esModule: true,
  ThirdwebProvider: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  useAddress: jest.fn(),
  useDisconnect: jest.fn(),
  useConnectionStatus: jest.fn(),
  ConnectWallet: jest.fn(() => <button>Connect Wallet</button>),
}));

const renderWithProviders = (component: React.ReactElement) => {
  return render(
    <BrowserRouter>
      <ThirdwebProvider activeChain="localhost" clientId="test">
        {component}
      </ThirdwebProvider>
    </BrowserRouter>
  );
};

describe('Header Component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('renders removal.ninja logo and navigation', () => {
    const { useAddress, useConnectionStatus } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);
    useConnectionStatus.mockReturnValue('disconnected');

    renderWithProviders(<Header />);
    
    expect(screen.getByText('🥷 removal.ninja')).toBeInTheDocument();
    expect(screen.getByText('Data Brokers')).toBeInTheDocument();
    expect(screen.getByText('Processors')).toBeInTheDocument();
  });

  test('shows additional navigation when wallet is connected', () => {
    const { useAddress, useConnectionStatus } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue('0x1234567890123456789012345678901234567890');
    useConnectionStatus.mockReturnValue('connected');

    renderWithProviders(<Header />);
    
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Processor')).toBeInTheDocument();
  });

  test('displays formatted address when connected', () => {
    const { useAddress, useConnectionStatus } = require('@thirdweb-dev/react');
    const mockAddress = '0x1234567890123456789012345678901234567890';
    useAddress.mockReturnValue(mockAddress);
    useConnectionStatus.mockReturnValue('connected');

    renderWithProviders(<Header />);
    
    expect(screen.getByText('0x1234...7890')).toBeInTheDocument();
  });

  test('shows connect wallet button when disconnected', () => {
    const { useAddress, useConnectionStatus, ConnectWallet } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);
    useConnectionStatus.mockReturnValue('disconnected');

    renderWithProviders(<Header />);

    expect(ConnectWallet).toHaveBeenCalled();

    const [props] = ConnectWallet.mock.calls[0];
    expect(props).toMatchObject({
      theme: 'light',
      btnTitle: 'Connect Wallet',
    });
    expect(props.className).toContain('!bg-ninja-600');
  });
});
