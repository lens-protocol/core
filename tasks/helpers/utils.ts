import '@nomiclabs/hardhat-ethers';
import { BytesLike, Signer, Wallet, ContractTransaction, BaseContract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { LensHub__factory } from '../../typechain-types';
import fs from 'fs';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

export enum ProtocolState {
  Unpaused,
  PublishingPaused,
  Paused,
}

export function getAddrs(): any {
  const json = fs.readFileSync('addresses.json', 'utf8');
  const addrs = JSON.parse(json);
  return addrs;
}

export async function waitForTx(tx: Promise<ContractTransaction>) {
  await (await tx).wait();
}

export async function deployContract(tx: any): Promise<any> {
  const result = await tx;
  await result.deployTransaction.wait();
  return result;
}

export async function initEnv(hre: HardhatRuntimeEnvironment): Promise<SignerWithAddress[]> {
  const ethers = hre.ethers; // This allows us to access the hre (Hardhat runtime environment)'s injected ethers instance easily

  const accounts = await ethers.getSigners(); // This returns an array of the default signers connected to the hre's ethers instance
  const governance = accounts[1];
  const treasury = accounts[2];
  const user = accounts[3];

  return [governance, treasury, user];
}
