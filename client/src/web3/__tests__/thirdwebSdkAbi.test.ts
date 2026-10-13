import { createThirdwebClient, encode, getContract, prepareContractCall } from 'thirdweb';
import { baseSepolia } from 'thirdweb/chains';

test('Thirdweb v5 encodes the app\'s integer approval call offline', async () => {
  const contract = getContract({
    client: createThirdwebClient({ clientId: 'offline-test' }),
    chain: baseSepolia,
    address: '0xA7b02F76D863b9467eCd80Eab3b9fd6aCe18200A',
  });
  const transaction = prepareContractCall({
    contract,
    method: 'function approve(address spender, uint256 amount) returns (bool)',
    params: ['0x6e7eF8A7B0219C0acE923dc9a0f76bBa65273Ef7', 1000000000000000000n],
  });
  const data = await encode(transaction);
  expect(data).toMatch(/^0x095ea7b3[0-9a-f]+$/);
  expect(data).toContain('0de0b6b3a7640000');
});
