import '@nomiclabs/hardhat-ethers';
import { BigNumberish, Bytes, logger, utils, BigNumber, Contract } from 'ethers';
import {
  eventsLib,
  helper,
  lensHub,
  LENS_HUB_NFT_NAME,
  peripheryDataProvider,
  PERIPHERY_DATA_PROVIDER_NAME,
  testWallet,
} from '../__setup.spec';
import { expect } from 'chai';
import { HARDHAT_CHAINID, MAX_UINT256 } from './constants';
import { hexlify, keccak256, RLP, toUtf8Bytes } from 'ethers/lib/utils';
import { LensHub__factory } from '../../typechain-types';
import { TransactionReceipt, TransactionResponse } from '@ethersproject/providers';
import hre, { ethers } from 'hardhat';

export enum ProtocolState {
  Unpaused,
  PublishingPaused,
  Paused,
}

export function matchEvent(
  receipt: TransactionReceipt,
  name: string,
  expectedArgs?: any[],
  eventContract: Contract = eventsLib,
  emitterAddress?: string
) {
  const events = receipt.logs;

  if (events != undefined) {
    // match name from list of events in eventContract, when found, compute the sigHash
    let sigHash: string | undefined;
    for (let contractEvent of Object.keys(eventContract.interface.events)) {
      if (contractEvent.startsWith(name) && contractEvent.charAt(name.length) == '(') {
        sigHash = keccak256(toUtf8Bytes(contractEvent));
        break;
      }
    }
    // Throw if the sigHash was not found
    if (!sigHash) {
      logger.throwError(
        `Event "${name}" not found in provided contract (default: Events libary). \nAre you sure you're using the right contract?`
      );
    }

    // Find the given event in the emitted logs
    let invalidParamsButExists = false;
    for (let emittedEvent of events) {
      // If we find one with the correct sighash, check if it is the one we're looking for
      if (emittedEvent.topics[0] == sigHash) {
        // If an emitter address is passed, validate that this is indeed the correct emitter, if not, continue
        if (emitterAddress) {
          if (emittedEvent.address != emitterAddress) continue;
        }
        const event = eventContract.interface.parseLog(emittedEvent);
        // If there are expected arguments, validate them, otherwise, return here
        if (expectedArgs) {
          if (expectedArgs.length != event.args.length) {
            logger.throwError(
              `Event "${name}" emitted with correct signature, but expected args are of invalid length`
            );
          }
          invalidParamsButExists = false;
          // Iterate through arguments and check them, if there is a mismatch, continue with the loop
          for (let i = 0; i < expectedArgs.length; i++) {
            // Parse empty arrays as empty bytes
            if (expectedArgs[i].constructor == Array && expectedArgs[i].length == 0) {
              expectedArgs[i] = '0x';
            }

            // Break out of the expected args loop if there is a mismatch, this will continue the emitted event loop
            if (BigNumber.isBigNumber(event.args[i])) {
              if (!event.args[i].eq(BigNumber.from(expectedArgs[i]))) {
                invalidParamsButExists = true;
                break;
              }
            } else if (event.args[i].constructor == Array) {
              let params = event.args[i];
              let expected = expectedArgs[i];
              for (let j = 0; j < params.length; j++) {
                if (BigNumber.isBigNumber(params[j])) {
                  if (!params[j].eq(BigNumber.from(expected[j]))) {
                    invalidParamsButExists = true;
                    break;
                  }
                } else if (params[j] != expected[j]) {
                  invalidParamsButExists = true;
                  break;
                }
              }
              if (invalidParamsButExists) break;
            } else if (event.args[i] != expectedArgs[i]) {
              invalidParamsButExists = true;
              break;
            }
          }
          // Return if the for loop did not cause a break, so a match has been found, otherwise proceed with the event loop
          if (!invalidParamsButExists) {
            return;
          }
        } else {
          return;
        }
      }
    }
    // Throw if the event args were not expected or the event was not found in the logs
    if (invalidParamsButExists) {
      logger.throwError(`Event "${name}" found in logs but with unexpected args`);
    } else {
      logger.throwError(
        `Event "${name}" not found emitted by "${emitterAddress}" in given transaction log`
      );
    }
  } else {
    logger.throwError('No events were emitted');
  }
}

export function computeContractAddress(deployerAddress: string, nonce: number): string {
  const hexNonce = hexlify(nonce);
  return '0x' + keccak256(RLP.encode([deployerAddress, hexNonce])).substr(26);
}

export function getChainId(): number {
  return hre.network.config.chainId || HARDHAT_CHAINID;
}

export function getAbbreviation(handle: string) {
  let slice = handle.substr(0, 4);
  if (slice.charAt(3) == ' ') {
    slice = slice.substr(0, 3);
  }
  return slice;
}

export async function waitForTx(
  tx: Promise<TransactionResponse> | TransactionResponse,
  skipCheck = false
): Promise<TransactionReceipt> {
  if (!skipCheck) await expect(tx).to.not.be.reverted;
  return await (await tx).wait();
}

export async function getBlockNumber(): Promise<number> {
  return (await helper.getBlockNumber()).toNumber();
}

export async function resetFork(): Promise<void> {
  await hre.network.provider.request({
    method: 'hardhat_reset',
    params: [
      {
        forking: {
          jsonRpcUrl: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
          blockNumber: 12012081,
        },
      },
    ],
  });
  console.log('\t> Fork reset');

  await hre.network.provider.request({
    method: 'evm_setNextBlockTimestamp',
    params: [1614290545], // Original block timestamp + 1
  });

  console.log('\t> Timestamp reset to 1614290545');
}

export async function getTimestamp(): Promise<any> {
  const blockNumber = await hre.ethers.provider.send('eth_blockNumber', []);
  const block = await hre.ethers.provider.send('eth_getBlockByNumber', [blockNumber, false]);
  return block.timestamp;
}

export async function setNextBlockTimestamp(timestamp: number): Promise<void> {
  await hre.ethers.provider.send('evm_setNextBlockTimestamp', [timestamp]);
}

export async function mine(blocks: number): Promise<void> {
  for (let i = 0; i < blocks; i++) {
    await hre.ethers.provider.send('evm_mine', []);
  }
}

let snapshotId: string = '0x1';
export async function takeSnapshot() {
  snapshotId = await hre.ethers.provider.send('evm_snapshot', []);
}

export async function revertToSnapshot() {
  await hre.ethers.provider.send('evm_revert', [snapshotId]);
}

export async function cancelWithPermitForAll(nft: string = lensHub.address) {
  const nftContract = LensHub__factory.connect(nft, testWallet);
  const name = await nftContract.name();
  const nonce = (await nftContract.sigNonces(testWallet.address)).toNumber();
  const { v, r, s } = await getPermitForAllParts(
    nft,
    name,
    testWallet.address,
    testWallet.address,
    false,
    nonce,
    MAX_UINT256
  );
  await nftContract.permitForAll(testWallet.address, testWallet.address, false, {
    v,
    r,
    s,
    deadline: MAX_UINT256,
  });
}

export async function getPermitParts(
  nft: string,
  name: string,
  spender: string,
  tokenId: BigNumberish,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildPermitParams(nft, name, spender, tokenId, nonce, deadline);
  return await getSig(msgParams);
}

export async function getPermitForAllParts(
  nft: string,
  name: string,
  owner: string,
  operator: string,
  approved: boolean,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildPermitForAllParams(nft, name, owner, operator, approved, nonce, deadline);
  return await getSig(msgParams);
}

export async function getBurnWithSigparts(
  nft: string,
  name: string,
  tokenId: BigNumberish,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildBurnWithSigParams(nft, name, tokenId, nonce, deadline);
  return await getSig(msgParams);
}

export async function getDelegateBySigParts(
  nft: string,
  name: string,
  delegator: string,
  delegatee: string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildDelegateBySigParams(nft, name, delegator, delegatee, nonce, deadline);
  return await getSig(msgParams);
}

const buildDelegateBySigParams = (
  nft: string,
  name: string,
  delegator: string,
  delegatee: string,
  nonce: number,
  deadline: string
) => ({
  types: {
    DelegateBySig: [
      { name: 'delegator', type: 'address' },
      { name: 'delegatee', type: 'address' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: nft,
  },
  value: {
    delegator: delegator,
    delegatee: delegatee,
    nonce: nonce,
    deadline: deadline,
  },
});

export async function getSetFollowModuleWithSigParts(
  profileId: BigNumberish,
  followModule: string,
  followModuleData: Bytes | string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetFollowModuleWithSigParams(
    profileId,
    followModule,
    followModuleData,
    nonce,
    deadline
  );
  return await getSig(msgParams);
}

export async function getSetDispatcherWithSigParts(
  profileId: BigNumberish,
  dispatcher: string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetDispatcherWithSigParams(profileId, dispatcher, nonce, deadline);
  return await getSig(msgParams);
}

export async function getSetProfileImageURIWithSigParts(
  profileId: BigNumberish,
  imageURI: string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetProfileImageURIWithSigParams(profileId, imageURI, nonce, deadline);
  return await getSig(msgParams);
}

export async function getSetDefaultProfileWithSigParts(
  wallet: string,
  profileId: BigNumberish,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetDefaultProfileWithSigParams(profileId, wallet, nonce, deadline);
  return await getSig(msgParams);
}

export async function getSetFollowNFTURIWithSigParts(
  profileId: BigNumberish,
  followNFTURI: string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetFollowNFTURIWithSigParams(profileId, followNFTURI, nonce, deadline);
  return await getSig(msgParams);
}

export async function getPostWithSigParts(
  profileId: BigNumberish,
  contentURI: string,
  collectModule: string,
  collectModuleData: Bytes | string,
  referenceModule: string,
  referenceModuleData: Bytes | string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildPostWithSigParams(
    profileId,
    contentURI,
    collectModule,
    collectModuleData,
    referenceModule,
    referenceModuleData,
    nonce,
    deadline
  );
  return await getSig(msgParams);
}

export async function getCommentWithSigParts(
  profileId: BigNumberish,
  contentURI: string,
  profileIdPointed: BigNumberish,
  pubIdPointed: string,
  collectModule: string,
  collectModuleData: Bytes | string,
  referenceModule: string,
  referenceModuleData: Bytes | string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildCommentWithSigParams(
    profileId,
    contentURI,
    profileIdPointed,
    pubIdPointed,
    collectModule,
    collectModuleData,
    referenceModule,
    referenceModuleData,
    nonce,
    deadline
  );
  return await getSig(msgParams);
}

export async function getMirrorWithSigParts(
  profileId: BigNumberish,
  profileIdPointed: BigNumberish,
  pubIdPointed: string,
  referenceModule: string,
  referenceModuleData: Bytes | string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildMirrorWithSigParams(
    profileId,
    profileIdPointed,
    pubIdPointed,
    referenceModule,
    referenceModuleData,
    nonce,
    deadline
  );
  return await getSig(msgParams);
}

export async function getFollowWithSigParts(
  profileIds: string[] | number[],
  datas: Bytes[] | string[],
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildFollowWithSigParams(profileIds, datas, nonce, deadline);
  return await getSig(msgParams);
}

export async function getToggleFollowWithSigParts(
  profileIds: string[] | number[],
  enables: boolean[],
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildToggleFollowWithSigParams(profileIds, enables, nonce, deadline);
  return await getSig(msgParams);
}

export async function getCollectWithSigParts(
  profileId: BigNumberish,
  pubId: string,
  data: Bytes | string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildCollectWithSigParams(profileId, pubId, data, nonce, deadline);
  return await getSig(msgParams);
}

export async function getJsonMetadataFromBase64TokenUri(tokenUri: string) {
  const splittedTokenUri = tokenUri.split('data:application/json;base64,');
  if (splittedTokenUri.length != 2) {
    logger.throwError('Wrong or unrecognized token URI format');
  } else {
    const jsonMetadataBase64String = splittedTokenUri[1];
    const jsonMetadataBytes = ethers.utils.base64.decode(jsonMetadataBase64String);
    const jsonMetadataString = ethers.utils.toUtf8String(jsonMetadataBytes);
    return JSON.parse(jsonMetadataString);
  }
}

// Modified from AaveTokenV2 repo
const buildPermitParams = (
  nft: string,
  name: string,
  spender: string,
  tokenId: BigNumberish,
  nonce: number,
  deadline: string
) => ({
  types: {
    Permit: [
      { name: 'spender', type: 'address' },
      { name: 'tokenId', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: nft,
  },
  value: {
    spender: spender,
    tokenId: tokenId,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildPermitForAllParams = (
  nft: string,
  name: string,
  owner: string,
  operator: string,
  approved: boolean,
  nonce: number,
  deadline: string
) => ({
  types: {
    PermitForAll: [
      { name: 'owner', type: 'address' },
      { name: 'operator', type: 'address' },
      { name: 'approved', type: 'bool' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: nft,
  },
  value: {
    owner: owner,
    operator: operator,
    approved: approved,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildBurnWithSigParams = (
  nft: string,
  name: string,
  tokenId: BigNumberish,
  nonce: number,
  deadline: string
) => ({
  types: {
    BurnWithSig: [
      { name: 'tokenId', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: nft,
  },
  value: {
    tokenId: tokenId,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildSetFollowModuleWithSigParams = (
  profileId: BigNumberish,
  followModule: string,
  followModuleData: Bytes | string,
  nonce: number,
  deadline: string
) => ({
  types: {
    SetFollowModuleWithSig: [
      { name: 'profileId', type: 'uint256' },
      { name: 'followModule', type: 'address' },
      { name: 'followModuleData', type: 'bytes' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: domain(),
  value: {
    profileId: profileId,
    followModule: followModule,
    followModuleData: followModuleData,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildSetDispatcherWithSigParams = (
  profileId: BigNumberish,
  dispatcher: string,
  nonce: number,
  deadline: string
) => ({
  types: {
    SetDispatcherWithSig: [
      { name: 'profileId', type: 'uint256' },
      { name: 'dispatcher', type: 'address' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: domain(),
  value: {
    profileId: profileId,
    dispatcher: dispatcher,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildSetProfileImageURIWithSigParams = (
  profileId: BigNumberish,
  imageURI: string,
  nonce: number,
  deadline: string
) => ({
  types: {
    SetProfileImageURIWithSig: [
      { name: 'profileId', type: 'uint256' },
      { name: 'imageURI', type: 'string' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: domain(),
  value: {
    profileId: profileId,
    imageURI: imageURI,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildSetDefaultProfileWithSigParams = (
  profileId: BigNumberish,
  wallet: string,
  nonce: number,
  deadline: string
) => ({
  types: {
    SetDefaultProfileWithSig: [
      { name: 'wallet', type: 'address' },
      { name: 'profileId', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: domain(),
  value: {
    wallet: wallet,
    profileId: profileId,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildSetFollowNFTURIWithSigParams = (
  profileId: BigNumberish,
  followNFTURI: string,
  nonce: number,
  deadline: string
) => ({
  types: {
    SetFollowNFTURIWithSig: [
      { name: 'profileId', type: 'uint256' },
      { name: 'followNFTURI', type: 'string' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: domain(),
  value: {
    profileId: profileId,
    followNFTURI: followNFTURI,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildPostWithSigParams = (
  profileId: BigNumberish,
  contentURI: string,
  collectModule: string,
  collectModuleData: Bytes | string,
  referenceModule: string,
  referenceModuleData: Bytes | string,
  nonce: number,
  deadline: string
) => ({
  types: {
    PostWithSig: [
      { name: 'profileId', type: 'uint256' },
      { name: 'contentURI', type: 'string' },
      { name: 'collectModule', type: 'address' },
      { name: 'collectModuleData', type: 'bytes' },
      { name: 'referenceModule', type: 'address' },
      { name: 'referenceModuleData', type: 'bytes' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: domain(),
  value: {
    profileId: profileId,
    contentURI: contentURI,
    collectModule: collectModule,
    collectModuleData: collectModuleData,
    referenceModule: referenceModule,
    referenceModuleData: referenceModuleData,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildCommentWithSigParams = (
  profileId: BigNumberish,
  contentURI: string,
  profileIdPointed: BigNumberish,
  pubIdPointed: string,
  collectModule: string,
  collectModuleData: Bytes | string,
  referenceModule: string,
  referenceModuleData: Bytes | string,
  nonce: number,
  deadline: string
) => ({
  types: {
    CommentWithSig: [
      { name: 'profileId', type: 'uint256' },
      { name: 'contentURI', type: 'string' },
      { name: 'profileIdPointed', type: 'uint256' },
      { name: 'pubIdPointed', type: 'uint256' },
      { name: 'collectModule', type: 'address' },
      { name: 'collectModuleData', type: 'bytes' },
      { name: 'referenceModule', type: 'address' },
      { name: 'referenceModuleData', type: 'bytes' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: domain(),
  value: {
    profileId: profileId,
    contentURI: contentURI,
    profileIdPointed: profileIdPointed,
    pubIdPointed: pubIdPointed,
    collectModule: collectModule,
    collectModuleData: collectModuleData,
    referenceModule: referenceModule,
    referenceModuleData: referenceModuleData,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildMirrorWithSigParams = (
  profileId: BigNumberish,
  profileIdPointed: BigNumberish,
  pubIdPointed: string,
  referenceModule: string,
  referenceModuleData: Bytes | string,
  nonce: number,
  deadline: string
) => ({
  types: {
    MirrorWithSig: [
      { name: 'profileId', type: 'uint256' },
      { name: 'profileIdPointed', type: 'uint256' },
      { name: 'pubIdPointed', type: 'uint256' },
      { name: 'referenceModule', type: 'address' },
      { name: 'referenceModuleData', type: 'bytes' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: domain(),
  value: {
    profileId: profileId,
    profileIdPointed: profileIdPointed,
    pubIdPointed: pubIdPointed,
    referenceModule: referenceModule,
    referenceModuleData: referenceModuleData,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildFollowWithSigParams = (
  profileIds: string[] | number[],
  datas: Bytes[] | string[],
  nonce: number,
  deadline: string
) => ({
  types: {
    FollowWithSig: [
      { name: 'profileIds', type: 'uint256[]' },
      { name: 'datas', type: 'bytes[]' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: domain(),
  value: {
    profileIds: profileIds,
    datas: datas,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildToggleFollowWithSigParams = (
  profileIds: string[] | number[],
  enables: boolean[],
  nonce: number,
  deadline: string
) => ({
  types: {
    ToggleFollowWithSig: [
      { name: 'profileIds', type: 'uint256[]' },
      { name: 'enables', type: 'bool[]' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: {
    name: PERIPHERY_DATA_PROVIDER_NAME,
    version: '1',
    chainId: getChainId(),
    verifyingContract: peripheryDataProvider.address,
  },
  value: {
    profileIds: profileIds,
    enables: enables,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildCollectWithSigParams = (
  profileId: BigNumberish,
  pubId: string,
  data: Bytes | string,
  nonce: number,
  deadline: string
) => ({
  types: {
    CollectWithSig: [
      { name: 'profileId', type: 'uint256' },
      { name: 'pubId', type: 'uint256' },
      { name: 'data', type: 'bytes' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: domain(),
  value: {
    profileId: profileId,
    pubId: pubId,
    data: data,
    nonce: nonce,
    deadline: deadline,
  },
});

async function getSig(msgParams: {
  domain: any;
  types: any;
  value: any;
}): Promise<{ v: number; r: string; s: string }> {
  const sig = await testWallet._signTypedData(msgParams.domain, msgParams.types, msgParams.value);
  return utils.splitSignature(sig);
}

function domain(): { name: string; version: string; chainId: number; verifyingContract: string } {
  return {
    name: LENS_HUB_NFT_NAME,
    version: '1',
    chainId: getChainId(),
    verifyingContract: lensHub.address,
  };
}
