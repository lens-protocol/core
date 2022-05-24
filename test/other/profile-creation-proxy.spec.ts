import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import { ProfileCreationProxy, ProfileCreationProxy__factory } from '../../typechain-types';
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
  deployerAddress,
} from '../__setup.spec';
import { BigNumber } from 'ethers';
import { TokenDataStructOutput } from '../../typechain-types/LensHub';
import { getTimestamp } from '../helpers/utils';

makeSuiteCleanRoom('Profile Creation Proxy', function () {
  const REQUIRED_SUFFIX = '.lens';
  const MINIMUM_LENGTH = 5;

  let profileCreationProxy: ProfileCreationProxy;
  beforeEach(async function () {
    profileCreationProxy = await new ProfileCreationProxy__factory(deployer).deploy(
      deployerAddress,
      lensHub.address
    );
    await expect(
      lensHub.connect(governance).whitelistProfileCreator(profileCreationProxy.address, true)
    ).to.not.be.reverted;
  });

  context('Negatives', function () {
    it('Should fail to create profile if handle length before suffix does not reach minimum length', async function () {
      const handle = 'a'.repeat(MINIMUM_LENGTH - 1);
      await expect(
        profileCreationProxy.proxyCreateProfile({
          to: userAddress,
          handle: handle,
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.be.revertedWith(ERRORS.INVALID_HANDLE_LENGTH);
    });

    it('Should fail to create profile if handle contains an invalid character before the suffix', async function () {
      await expect(
        profileCreationProxy.proxyCreateProfile({
          to: userAddress,
          handle: 'dots.are.invalid',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.be.revertedWith(ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS);
    });

    it('Should fail to create profile if handle starts with a dash, underscore or period', async function () {
      await expect(
        profileCreationProxy.proxyCreateProfile({
          to: userAddress,
          handle: '.abcdef',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.be.revertedWith(ERRORS.HANDLE_FIRST_CHARACTER_INVALID);

      await expect(
        profileCreationProxy.proxyCreateProfile({
          to: userAddress,
          handle: '-abcdef',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.be.revertedWith(ERRORS.HANDLE_FIRST_CHARACTER_INVALID);

      await expect(
        profileCreationProxy.proxyCreateProfile({
          to: userAddress,
          handle: '_abcdef',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.be.revertedWith(ERRORS.HANDLE_FIRST_CHARACTER_INVALID);
    });
  });

  context('Scenarios', function () {
    it('Should be able to create a profile using the whitelisted proxy, received NFT should be valid', async function () {
      let timestamp: any;
      let owner: string;
      let totalSupply: BigNumber;
      let profileId: BigNumber;
      let mintTimestamp: BigNumber;
      let tokenData: TokenDataStructOutput;
      const validHandleBeforeSuffix = 'v_al-id';
      const expectedHandle = 'v_al-id'.concat(REQUIRED_SUFFIX);

      await expect(
        profileCreationProxy.proxyCreateProfile({
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
  });
});
