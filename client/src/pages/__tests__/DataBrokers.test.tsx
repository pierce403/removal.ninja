import React from 'react';
import * as compat from '../../web3/thirdwebCompat';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { ThirdwebProvider } from 'thirdweb/react';
import DataBrokers from '../DataBrokers';

// Mock Thirdweb hooks
vi.mock('thirdweb/react', () => ({
  __esModule: true,
  ThirdwebProvider: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
}));
vi.mock('../../web3/thirdwebCompat', () => ({
  useAddress: vi.fn(),
  useContract: vi.fn(() => ({ contract: { call: vi.fn() } })),
  useContractRead: vi.fn(() => ({ data: undefined })),
  useContractWrite: vi.fn(() => ({ mutateAsync: vi.fn() })),
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

const mockRegistry = () => {
  const rows: Record<number, unknown[]> = {
    1: [1n, 'Acxiom', 'https://acxiom.test', 'https://acxiom.test/optout', 'privacy@acxiom.test', 300n, true, 2n, 0n],
    2: [2n, 'LexisNexis', 'https://lexis.test', 'https://lexis.test/optout', 'privacy@lexis.test', 200n, true, 1n, 0n],
    3: [3n, 'Spokeo', 'https://spokeo.test', 'https://spokeo.test/optout', 'privacy@spokeo.test', 100n, false, 0n, 0n],
  };
  const contract = { call: vi.fn(async (_method: string, [id]: number[]) => rows[id]) };
  (compat.useContract as any).mockReturnValue({ contract });
  (compat.useContractRead as any).mockImplementation((_contract: unknown, method: string) => ({
    data: method === 'nextBrokerId' ? 4n : method === 'getStats' ? [3n, 2n] : undefined,
  }));
  return contract;
};

describe('DataBrokers Page', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    const { useContract, useContractRead, useContractWrite } = (compat as any);
    useContract.mockReturnValue({ contract: { call: vi.fn() } });
    useContractRead.mockReturnValue({ data: undefined });
    useContractWrite.mockReturnValue({ mutateAsync: vi.fn() });
  });

  test('renders page title and description', () => {
    const { useAddress } = (compat as any);
    useAddress.mockReturnValue(null);

    renderWithProviders(<DataBrokers />);
    
    expect(screen.getByText('Data Brokers')).toBeInTheDocument();
    expect(screen.getByText(/Community-sourced database of data brokers/)).toBeInTheDocument();
  });

  test('loads active brokers from the contract', async () => {
    const { useAddress } = (compat as any);
    useAddress.mockReturnValue(null);
    const contract = mockRegistry();

    renderWithProviders(<DataBrokers />);

    expect(await screen.findByText('Acxiom')).toBeInTheDocument();
    expect(screen.getByText('LexisNexis')).toBeInTheDocument();
    expect(screen.queryByText('Spokeo')).not.toBeInTheDocument();
    expect(contract.call).toHaveBeenCalledTimes(3);
  });

  test('shows submit button when wallet is connected', () => {
    const { useAddress } = (compat as any);
    useAddress.mockReturnValue('0x1234567890123456789012345678901234567890');

    renderWithProviders(<DataBrokers />);
    
    expect(screen.getByText('Submit New Broker')).toBeInTheDocument();
  });

  test('shows connect wallet message when disconnected', () => {
    const { useAddress } = (compat as any);
    useAddress.mockReturnValue(null);

    renderWithProviders(<DataBrokers />);
    
    expect(screen.getByText(/Connect your wallet to submit new data brokers/)).toBeInTheDocument();
  });

  test('can open and close submission form', async () => {
    const { useAddress } = (compat as any);
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

  test('displays platform statistics returned by the contract', () => {
    const { useAddress } = (compat as any);
    useAddress.mockReturnValue(null);
    mockRegistry();

    renderWithProviders(<DataBrokers />);

    expect(screen.getByText('Total Brokers')).toBeInTheDocument();
    expect(screen.getByText('Total Brokers').previousElementSibling).toHaveTextContent('3');
    expect(screen.getByText('Active').previousElementSibling).toHaveTextContent('2');
    expect(screen.getByText('RN Reward Base').previousElementSibling).toHaveTextContent('100');
  });

  test('shows active status for returned brokers', async () => {
    const { useAddress } = (compat as any);
    useAddress.mockReturnValue(null);
    mockRegistry();

    renderWithProviders(<DataBrokers />);

    await screen.findByText('Acxiom');
    const activeBadges = screen
      .getAllByText('Active')
      .filter((element: HTMLElement) => element.tagName.toLowerCase() === 'span');
    expect(activeBadges).toHaveLength(2);
    expect(screen.queryByText('Inactive')).not.toBeInTheDocument();
  });
});
