import { Wallet, Signer } from 'ethers';
import { DefenderRelaySigner, DefenderRelayProvider } from 'defender-relay-client/lib/ethers';
import { MNEMONIC, DEFENDER_API_KEY, DEFENDER_SECRET_KEY, PRIVATE_KEY } from '../env';

export const getPrivateKeyWallet = (): Signer => new Wallet(PRIVATE_KEY);

export const getMnemonicWallet = (): Signer => Wallet.fromMnemonic(MNEMONIC);

export const getDefenderSigner = (): Signer => {
  const credentials = { apiKey: DEFENDER_API_KEY, apiSecret: DEFENDER_SECRET_KEY };
  const provider = new DefenderRelayProvider(credentials);
  return new DefenderRelaySigner(credentials, provider, { speed: 'fast' });
};
