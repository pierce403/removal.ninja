import React from 'react';
import * as compat from '../../web3/thirdwebCompat';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { ThirdwebProvider } from 'thirdweb/react';
import Header from '../Header';

// Mock Thirdweb hooks
vi.mock('thirdweb/react', () => ({
  __esModule: true,
  ThirdwebProvider: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
}));
vi.mock('../../web3/thirdwebCompat', () => ({
  useAddress: vi.fn(),
  useDisconnect: vi.fn(),
  ConnectWallet: vi.fn(() => <button>Connect Wallet</button>),
}));

const renderWithProviders = (component: React.ReactElement) => {
  return render(
    <BrowserRouter>
      <ThirdwebProvider>
        {component}
      </ThirdwebProvider>
    </BrowserRouter>
  );
};

describe('Header Component', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test('renders removal.ninja logo and navigation', () => {
    const { useAddress } = (compat as any);
    useAddress.mockReturnValue(null);

    renderWithProviders(<Header />);
    
    expect(screen.getByText('🥷 removal.ninja')).toBeInTheDocument();
    expect(screen.getByText('Data Brokers')).toBeInTheDocument();
    expect(screen.getByText('Processors')).toBeInTheDocument();
  });

  test('shows additional navigation when wallet is connected', () => {
    const { useAddress } = (compat as any);
    useAddress.mockReturnValue('0x1234567890123456789012345678901234567890');

    renderWithProviders(<Header />);
    
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Processor')).toBeInTheDocument();
  });

  test('displays formatted address when connected', () => {
    const { useAddress } = (compat as any);
    const mockAddress = '0x1234567890123456789012345678901234567890';
    useAddress.mockReturnValue(mockAddress);

    renderWithProviders(<Header />);
    
    expect(screen.getByText('0x1234...7890')).toBeInTheDocument();
  });

  test('shows connect wallet button when disconnected', () => {
    const { useAddress, ConnectWallet } = (compat as any);
    useAddress.mockReturnValue(null);

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
