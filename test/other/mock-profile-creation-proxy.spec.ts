import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import { MockProfileCreationProxy, MockProfileCreationProxy__factory } from '../../typechain-types';
import {
  deployer,
  FIRST_PROFILE_ID,
  governance,
  lensHub,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_URI,
  user,
  userAddress,
  governanceAddress,
} from '../__setup.spec';
import { BigNumber } from 'ethers';
import { TokenDataStructOutput } from '../../typechain-types/LensHub';
import { getTimestamp } from '../helpers/utils';

makeSuiteCleanRoom('Mock Profile Creation Proxy', function () {
  let mockProfileCreationProxy: MockProfileCreationProxy;
  let requiredSuffix = '.lens';
  let invalidChars = '.';
  let requiredMinHandleLengthBeforeSuffix = 4;
  beforeEach(async function () {
    mockProfileCreationProxy = await new MockProfileCreationProxy__factory(deployer).deploy(
      requiredMinHandleLengthBeforeSuffix,
      requiredSuffix,
      invalidChars,
      governanceAddress,
      lensHub.address
    );
    await expect(
      lensHub.connect(governance).whitelistProfileCreator(mockProfileCreationProxy.address, true)
    ).to.not.be.reverted;
  });

  context('Negatives', function () {
    it('User should fail to create profile if handle length before suffix does not reach minimum length', async function () {
      await expect(
        mockProfileCreationProxy.connect(user).proxyCreateProfile({
          to: userAddress,
          handle: '69',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.be.revertedWith(ERRORS.INVALID_HANDLE_LENGTH);
    });

    it('User should fail to create profile if handle contains an invalid character before the suffix', async function () {
      await expect(
        mockProfileCreationProxy.connect(user).proxyCreateProfile({
          to: userAddress,
          handle: 'dots.are.invalid',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.be.revertedWith(ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS);
    });

    it('User should fail to create profile if handle length before suffix does not reach new minimum length', async function () {
      await expect(
        mockProfileCreationProxy.connect(user).proxyCreateProfile({
          to: userAddress,
          handle: 'validhandle',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.not.be.reverted;
      await mockProfileCreationProxy.connect(governance).setRequiredMinHandleLengthBeforeSuffix(15);
      await expect(
        mockProfileCreationProxy.connect(user).proxyCreateProfile({
          to: userAddress,
          handle: 'validhandletoo',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.be.revertedWith(ERRORS.INVALID_HANDLE_LENGTH);
    });

    it('User should fail to create profile if handle contains a new invalid character before the suffix', async function () {
      await expect(
        mockProfileCreationProxy.connect(user).proxyCreateProfile({
          to: userAddress,
          handle: 'validhandle',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.not.be.reverted;
      // Sets 'h' character (0x68 in UTF-8) as invalid
      await mockProfileCreationProxy.connect(governance).setCharacterValidity('0x68', false);
      await expect(
        mockProfileCreationProxy.connect(user).proxyCreateProfile({
          to: userAddress,
          handle: 'validhandletoo',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.be.revertedWith(ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS);
    });

    it('User should fail to change min handle length before suffix if it is not the governance address', async function () {
      await expect(
        mockProfileCreationProxy.connect(user).setRequiredMinHandleLengthBeforeSuffix(15)
      ).to.be.revertedWith(ERRORS.NOT_GOVERNANCE);
    });

    it('User should fail to change suffix if it is not the governance address', async function () {
      await expect(
        mockProfileCreationProxy.connect(user).setRequiredHandleSuffix('.user')
      ).to.be.revertedWith(ERRORS.NOT_GOVERNANCE);
    });

    it('User should fail to change character validity if it is not the governance address', async function () {
      await expect(
        mockProfileCreationProxy.connect(user).setCharacterValidity('0x68', true)
      ).to.be.revertedWith(ERRORS.NOT_GOVERNANCE);
    });

    it('User should fail to change governance if it is not the governance address', async function () {
      await expect(
        mockProfileCreationProxy.connect(user).setGovernance(userAddress)
      ).to.be.revertedWith(ERRORS.NOT_GOVERNANCE);
    });
  });

  it('User should be able to create a profile using the whitelisted proxy, received NFT should be valid', async function () {
    let timestamp: any;
    let owner: string;
    let totalSupply: BigNumber;
    let profileId: BigNumber;
    let mintTimestamp: BigNumber;
    let tokenData: TokenDataStructOutput;
    const validHandleBeforeSuffix = 'validhandle';
    const expectedHandle = 'validhandle'.concat(requiredSuffix);

    await expect(
      mockProfileCreationProxy.connect(user).proxyCreateProfile({
        to: userAddress,
        handle: validHandleBeforeSuffix,
        imageURI: MOCK_PROFILE_URI,
        followModule: ZERO_ADDRESS,
        followModuleInitData: [],
        followNFTURI: MOCK_FOLLOW_NFT_URI,
      })
    ).to.not.be.reverted;

    timestamp = await getTimestamp();
    owner = await lensHub.ownerOf(FIRST_PROFILE_ID);
    totalSupply = await lensHub.totalSupply();
    profileId = await lensHub.getProfileIdByHandle(expectedHandle);
    mintTimestamp = await lensHub.mintTimestampOf(FIRST_PROFILE_ID);
    tokenData = await lensHub.tokenDataOf(FIRST_PROFILE_ID);
    expect(owner).to.eq(userAddress);
    expect(totalSupply).to.eq(FIRST_PROFILE_ID);
    expect(profileId).to.eq(FIRST_PROFILE_ID);
    expect(mintTimestamp).to.eq(timestamp);
    expect(tokenData.owner).to.eq(userAddress);
    expect(tokenData.mintTimestamp).to.eq(timestamp);
  });

  it('User should get the expected handle after governance update the required suffix', async function () {
    const handleBeforeSuffix = 'validhandle';
    await expect(
      mockProfileCreationProxy.connect(user).proxyCreateProfile({
        to: userAddress,
        handle: handleBeforeSuffix,
        imageURI: MOCK_PROFILE_URI,
        followModule: ZERO_ADDRESS,
        followModuleInitData: [],
        followNFTURI: MOCK_FOLLOW_NFT_URI,
      })
    ).to.not.be.reverted;
    expect(await lensHub.getHandle(1)).to.eq(handleBeforeSuffix.concat(requiredSuffix));

    const newSuffix = '.test';
    await mockProfileCreationProxy.connect(governance).setRequiredHandleSuffix(newSuffix);

    await expect(
      mockProfileCreationProxy.connect(user).proxyCreateProfile({
        to: userAddress,
        handle: handleBeforeSuffix,
        imageURI: MOCK_PROFILE_URI,
        followModule: ZERO_ADDRESS,
        followModuleInitData: [],
        followNFTURI: MOCK_FOLLOW_NFT_URI,
      })
    ).to.not.be.reverted;
    expect(await lensHub.getHandle(2)).to.eq(handleBeforeSuffix.concat(newSuffix));
  });

  it('User should succeed making a onlyGov call after setting him as governance address', async function () {
    await mockProfileCreationProxy.connect(governance).setGovernance(userAddress);
    await expect(
      mockProfileCreationProxy.connect(user).setRequiredHandleSuffix('.user')
    ).to.not.be.reverted;
  });
});
