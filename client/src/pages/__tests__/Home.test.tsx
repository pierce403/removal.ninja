import React from 'react';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { ThirdwebProvider } from '@thirdweb-dev/react';
import Home from '../Home';

// Mock Thirdweb hooks
jest.mock('@thirdweb-dev/react', () => ({
  ...jest.requireActual('@thirdweb-dev/react'),
  useAddress: jest.fn(),
  ThirdwebProvider: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
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

describe('Home Page', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('renders hero section with title and description', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);

    renderWithProviders(<Home />);
    
    expect(screen.getByText('🥷 removal.ninja')).toBeInTheDocument();
    expect(screen.getByText(/Decentralized data broker removal with token incentives/)).toBeInTheDocument();
  });

  test('displays protocol information sections', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);

    renderWithProviders(<Home />);
    
    expect(screen.getByText('How It Works')).toBeInTheDocument();
    expect(screen.getByText('Submit Data Brokers')).toBeInTheDocument();
    expect(screen.getByText('Stake for Removal')).toBeInTheDocument();
    expect(screen.getByText('Process Removals')).toBeInTheDocument();
  });

  test('shows protocol architecture information', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);

    renderWithProviders(<Home />);
    
    expect(screen.getByText('Protocol Architecture')).toBeInTheDocument();
    expect(screen.getByText('🔄 Trusted Processor Network')).toBeInTheDocument();
    expect(screen.getByText('🔐 zkEmail Verification')).toBeInTheDocument();
  });

  test('displays different CTA based on wallet connection', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    
    // Test disconnected state
    useAddress.mockReturnValue(null);
    const { rerender } = renderWithProviders(<Home />);
    expect(screen.getByText(/Connect your wallet above to get started/)).toBeInTheDocument();

    // Test connected state
    useAddress.mockReturnValue('0x1234567890123456789012345678901234567890');
    rerender(
      <BrowserRouter>
        <ThirdwebProvider activeChain="localhost" clientId="test">
          <Home />
        </ThirdwebProvider>
      </BrowserRouter>
    );
    expect(screen.getByText('User Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Become Processor')).toBeInTheDocument();
  });

  test('contains token reward information', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);

    renderWithProviders(<Home />);
    
    expect(screen.getByText(/100 RN tokens/)).toBeInTheDocument();
    expect(screen.getByText(/50 RN tokens/)).toBeInTheDocument();
  });
});
