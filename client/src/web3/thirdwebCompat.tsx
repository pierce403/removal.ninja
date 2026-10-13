import React, { useMemo } from 'react';
import { createThirdwebClient, getContract, prepareContractCall, readContract } from 'thirdweb';
import { baseSepolia } from 'thirdweb/chains';
import {
  ConnectButton,
  useActiveAccount,
  useActiveWallet,
  useDisconnect as useThirdwebDisconnect,
  useReadContract,
  useSendAndConfirmTransaction,
} from 'thirdweb/react';
import { createWallet } from 'thirdweb/wallets';
import { THIRDWEB_CLIENT_ID } from '../config/contracts';

export const client = createThirdwebClient({ clientId: THIRDWEB_CLIENT_ID });

type ContractHandle = {
  sdk: ReturnType<typeof getContract>;
  abi: readonly string[];
  call: (method: string, args?: unknown[]) => Promise<any>;
};

const methodSignature = (abi: readonly string[], name: string): `function ${string}` => {
  const signature = abi.find((item) => new RegExp(`^function\\s+${name}\\s*\\(`).test(item));
  if (!signature) throw new Error(`Missing contract method: ${name}`);
  return signature.replace(/\s+(external|public|calldata|memory)\b/g, '') as `function ${string}`;
};

const contractParams = (signature: string, args: unknown[] = []): any[] => {
  const fields = signature.slice(signature.indexOf('(') + 1, signature.indexOf(')')).split(',');
  return args.map((arg, index) => {
    const type = fields[index]?.trim().split(/\s+/)[0];
    return type && /^u?int\d*$/.test(type) ? BigInt(arg as string | number | bigint) : arg;
  });
};

export const useAddress = () => useActiveAccount()?.address;

export const useDisconnect = () => {
  const wallet = useActiveWallet();
  const { disconnect } = useThirdwebDisconnect();
  return () => {
    if (wallet) disconnect(wallet);
  };
};

export const ConnectWallet = ({ btnTitle = 'Connect Wallet' }: { btnTitle?: string; theme?: string; className?: string }) => (
  <ConnectButton
    client={client}
    chain={baseSepolia}
    connectButton={{ label: btnTitle }}
    wallets={[
      createWallet('io.metamask'),
      createWallet('com.coinbase.wallet'),
      createWallet('me.rainbow'),
      createWallet('walletConnect'),
    ]}
  />
);

export const useContract = (address: string, abi: readonly string[]): { contract: ContractHandle } => {
  const sdk = useMemo(() => getContract({ client, chain: baseSepolia, address }), [address]);
  const contract = useMemo<ContractHandle>(() => ({
    sdk,
    abi,
    call: (method, args = []) => {
      const signature = methodSignature(abi, method);
      return (readContract as any)({ contract: sdk, method: signature, params: contractParams(signature, args) });
    },
  }), [sdk, abi]);
  return { contract };
};

export const useContractRead = (contract: ContractHandle, method: string, args: unknown[] = []) => {
  const signature = methodSignature(contract.abi, method);
  return (useReadContract as any)({
    contract: contract.sdk,
    method: signature,
    params: contractParams(signature, args),
    queryOptions: { enabled: !args.some((arg) => arg == null) },
  });
};

export const useContractWrite = (contract: ContractHandle, method: string) => {
  const mutation = useSendAndConfirmTransaction({ payModal: false });
  return {
    mutateAsync: ({ args = [], overrides }: { args?: unknown[]; overrides?: { value?: string } }) => {
      const signature = methodSignature(contract.abi, method);
      const tx = (prepareContractCall as any)({
        contract: contract.sdk,
        method: signature,
        params: contractParams(signature, args),
        value: overrides?.value === undefined ? undefined : BigInt(overrides.value),
      });
      return mutation.mutateAsync(tx);
    },
    isLoading: mutation.isPending,
  };
};
