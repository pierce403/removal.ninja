import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { ThirdwebProvider } from '@thirdweb-dev/react';
import DataBrokers from '../DataBrokers';

// Mock Thirdweb hooks
jest.mock('@thirdweb-dev/react', () => ({
  __esModule: true,
  ThirdwebProvider: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  useAddress: jest.fn(),
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

describe('DataBrokers Page', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('renders page title and description', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);

    renderWithProviders(<DataBrokers />);
    
    expect(screen.getByText('Data Brokers')).toBeInTheDocument();
    expect(screen.getByText(/Community-sourced database of data brokers/)).toBeInTheDocument();
  });

  test('displays mock data brokers', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);

    renderWithProviders(<DataBrokers />);
    
    expect(screen.getByText('Acxiom')).toBeInTheDocument();
    expect(screen.getByText('LexisNexis')).toBeInTheDocument();
    expect(screen.getByText('Spokeo')).toBeInTheDocument();
  });

  test('shows submit button when wallet is connected', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue('0x1234567890123456789012345678901234567890');

    renderWithProviders(<DataBrokers />);
    
    expect(screen.getByText('Submit New Broker')).toBeInTheDocument();
  });

  test('shows connect wallet message when disconnected', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);

    renderWithProviders(<DataBrokers />);
    
    expect(screen.getByText(/Connect your wallet to submit new data brokers/)).toBeInTheDocument();
  });

  test('can open and close submission form', async () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue('0x1234567890123456789012345678901234567890');

    renderWithProviders(<DataBrokers />);
    
    const submitButton = screen.getByText('Submit New Broker');
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('Submit New Data Broker')).toBeInTheDocument();
    });

    const cancelButtons = screen.getAllByText('Cancel');
    const cancelButton = cancelButtons[cancelButtons.length - 1];
    fireEvent.click(cancelButton);

    await waitFor(() => {
      expect(screen.queryByText('Submit New Data Broker')).not.toBeInTheDocument();
    });
  });

  test('displays platform statistics', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);

    renderWithProviders(<DataBrokers />);
    
    expect(screen.getByText('Total Brokers')).toBeInTheDocument();
    expect(screen.getAllByText('Verified').length).toBeGreaterThan(0);
    expect(screen.getByText('RN Reward per Submission')).toBeInTheDocument();
  });

  test('shows broker verification status', () => {
    const { useAddress } = require('@thirdweb-dev/react');
    useAddress.mockReturnValue(null);

    renderWithProviders(<DataBrokers />);
    
    const verifiedBadges = screen
      .getAllByText('Verified')
      .filter((element: HTMLElement) => element.tagName.toLowerCase() === 'span');
    expect(verifiedBadges).toHaveLength(2); // Acxiom and LexisNexis
    expect(screen.getByText('Pending')).toBeInTheDocument(); // Spokeo
  });
});
