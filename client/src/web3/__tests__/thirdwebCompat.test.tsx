import React from 'react';
import { act, render, renderHook, screen } from '@testing-library/react';

const sdk = vi.hoisted(() => {
  const contract = { address: '0xA7b02F76D863b9467eCd80Eab3b9fd6aCe18200A' };
  const wallet = { id: 'io.metamask' };
  return {
    contract,
    wallet,
    createThirdwebClient: vi.fn(() => ({ clientId: 'test-client' })),
    getContract: vi.fn(() => contract),
    readContract: vi.fn(async () => 42n),
    prepareContractCall: vi.fn((input: unknown) => ({ prepared: input })),
    disconnect: vi.fn(),
    useReadContract: vi.fn(() => ({ data: 42n })),
    mutateAsync: vi.fn(async () => ({ transactionHash: '0x123' })),
    createWallet: vi.fn((id: string) => ({ id })),
  };
});

vi.mock('thirdweb', () => ({
  createThirdwebClient: sdk.createThirdwebClient,
  getContract: sdk.getContract,
  readContract: sdk.readContract,
  prepareContractCall: sdk.prepareContractCall,
}));
vi.mock('thirdweb/chains', () => ({ baseSepolia: { id: 84532 } }));
vi.mock('thirdweb/wallets', () => ({ createWallet: sdk.createWallet }));
vi.mock('thirdweb/react', () => ({
  ConnectButton: (props: { connectButton: { label: string }; wallets: unknown[] }) => (
    <button data-testid="connect-wallet">{props.connectButton.label} ({props.wallets.length})</button>
  ),
  useActiveAccount: () => ({ address: sdk.contract.address }),
  useActiveWallet: () => sdk.wallet,
  useDisconnect: () => ({ disconnect: sdk.disconnect }),
  useReadContract: sdk.useReadContract,
  useSendAndConfirmTransaction: () => ({ mutateAsync: sdk.mutateAsync, isPending: false }),
}));

import { ConnectWallet, useAddress, useContract, useContractRead, useContractWrite, useDisconnect } from '../thirdwebCompat';

const tokenAbi = [
  'function balanceOf(address owner) external view returns (uint256)',
  'function approve(address spender, uint256 amount) external returns (bool)',
];

beforeEach(() => vi.clearAllMocks());

test('connects the configured wallet UI and disconnects the active wallet', () => {
  render(<ConnectWallet btnTitle="Connect to removal.ninja" />);
  expect(screen.getByTestId('connect-wallet')).toHaveTextContent('Connect to removal.ninja (4)');
  expect(sdk.createWallet).toHaveBeenCalledWith('io.metamask');
  expect(sdk.createWallet).toHaveBeenCalledWith('walletConnect');
  const { result } = renderHook(() => ({ address: useAddress(), disconnect: useDisconnect() }));
  expect(result.current.address).toBe(sdk.contract.address);
  act(() => result.current.disconnect());
  expect(sdk.disconnect).toHaveBeenCalledWith(sdk.wallet);
});

test('reads a contract method with the v5 ABI signature and parameters', async () => {
  const { result: handle } = renderHook(() => useContract(sdk.contract.address, tokenAbi));
  const { result: read } = renderHook(() => useContractRead(handle.current.contract, 'balanceOf', [sdk.contract.address]));
  expect(read.current.data).toBe(42n);
  expect(sdk.useReadContract).toHaveBeenCalledWith(expect.objectContaining({
    contract: sdk.contract,
    method: 'function balanceOf(address owner) view returns (uint256)',
    params: [sdk.contract.address],
  }));
  expect(await handle.current.contract.call('balanceOf', [sdk.contract.address])).toBe(42n);
  expect(sdk.readContract).toHaveBeenCalledWith(expect.objectContaining({
    contract: sdk.contract,
    params: [sdk.contract.address],
  }));
});

test('does not query account-specific data before a wallet address exists', () => {
  const { result: handle } = renderHook(() => useContract(sdk.contract.address, tokenAbi));
  renderHook(() => useContractRead(handle.current.contract, 'balanceOf', [undefined]));
  expect(sdk.useReadContract).toHaveBeenCalledWith(expect.objectContaining({
    queryOptions: { enabled: false },
  }));
});

test('prepares integer contract writes and awaits the confirmed receipt', async () => {
  const { result: handle } = renderHook(() => useContract(sdk.contract.address, tokenAbi));
  const { result: write } = renderHook(() => useContractWrite(handle.current.contract, 'approve'));
  let receipt: unknown;
  await act(async () => {
    receipt = await write.current.mutateAsync({ args: [sdk.contract.address, '1000000000000000000'] });
  });
  expect(sdk.prepareContractCall).toHaveBeenCalledWith(expect.objectContaining({
    contract: sdk.contract,
    method: 'function approve(address spender, uint256 amount) returns (bool)',
    params: [sdk.contract.address, 1000000000000000000n],
  }));
  expect(sdk.mutateAsync).toHaveBeenCalledWith({ prepared: expect.any(Object) });
  expect(receipt).toEqual({ transactionHash: '0x123' });
});

test('converts payable ETH value to bigint for token purchases', async () => {
  const { result: handle } = renderHook(() => useContract(sdk.contract.address, [
    'function buyTokens() payable',
  ]));
  const { result: write } = renderHook(() => useContractWrite(handle.current.contract, 'buyTokens'));
  await act(async () => {
    await write.current.mutateAsync({ overrides: { value: '5000000000000000' } });
  });
  expect(sdk.prepareContractCall).toHaveBeenCalledWith(expect.objectContaining({
    method: 'function buyTokens() payable',
    params: [],
    value: 5000000000000000n,
  }));
});
