import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { TokenDataStructOutput } from '../../../typechain-types/LensHub';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import { createProfileReturningTokenId, getTimestamp, waitForTx } from '../../helpers/utils';
import {
  FIRST_PROFILE_ID,
  governance,
  lensHub,
  makeSuiteCleanRoom,
  MAX_PROFILE_IMAGE_URI_LENGTH,
  mockFollowModule,
  mockModuleData,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  userAddress,
  userTwo,
  userTwoAddress,
} from '../../__setup.spec';

makeSuiteCleanRoom('Profile Creation', function () {
  context('Generic', function () {
    context('Negatives', function () {
      it('User should fail to create a profile with a handle longer than 31 bytes', async function () {
        const val = '11111111111111111111111111111111';
        expect(val.length).to.eq(32);
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: val,
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.be.revertedWith(ERRORS.INVALID_HANDLE_LENGTH);
      });

      it('User should fail to create a profile with an empty handle (0 length bytes)', async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: '',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.be.revertedWith(ERRORS.INVALID_HANDLE_LENGTH);
      });

      it('User should fail to create a profile with a handle with a capital letter', async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: 'Egg',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.be.revertedWith(ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS);
      });

      it('User should fail to create a profile with a handle with an invalid character', async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: 'egg?',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.be.revertedWith(ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS);
      });

      it('User should fail to create a profile with a unwhitelisted follow module', async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: userAddress,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.be.revertedWith(ERRORS.FOLLOW_MODULE_NOT_WHITELISTED);
      });

      it('User should fail to create a profile with with invalid follow module data format', async function () {
        await expect(
          lensHub.connect(governance).whitelistFollowModule(mockFollowModule.address, true)
        ).to.not.be.reverted;

        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: mockFollowModule.address,
            followModuleInitData: [0x12, 0x34],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.be.revertedWith(ERRORS.NO_REASON_ABI_DECODE);
      });

      it('User should fail to create a profile when they are not a whitelisted profile creator', async function () {
        await expect(
          lensHub.connect(governance).whitelistProfileCreator(userAddress, false)
        ).to.not.be.reverted;

        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.be.revertedWith(ERRORS.PROFILE_CREATOR_NOT_WHITELISTED);
      });

      it('User should fail to create a profile with invalid image URI length', async function () {
        const profileURITooLong = MOCK_PROFILE_URI.repeat(500);
        expect(profileURITooLong.length).to.be.greaterThan(MAX_PROFILE_IMAGE_URI_LENGTH);

        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: profileURITooLong,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.be.revertedWith(ERRORS.INVALID_IMAGE_URI_LENGTH);
      });
    });

    context('Scenarios', function () {
      it('User should be able to create a profile with a handle, receive an NFT and the handle should resolve to the NFT ID, userTwo should do the same', async function () {
        let timestamp: any;
        let owner: string;
        let totalSupply: BigNumber;
        let profileId: BigNumber;
        let mintTimestamp: BigNumber;
        let tokenData: TokenDataStructOutput;

        expect(
          await createProfileReturningTokenId({
            vars: {
              to: userAddress,
              handle: MOCK_PROFILE_HANDLE,
              imageURI: MOCK_PROFILE_URI,
              followModule: ZERO_ADDRESS,
              followModuleInitData: [],
              followNFTURI: MOCK_FOLLOW_NFT_URI,
            },
          })
        ).to.eq(FIRST_PROFILE_ID);

        timestamp = await getTimestamp();
        owner = await lensHub.ownerOf(FIRST_PROFILE_ID);
        totalSupply = await lensHub.totalSupply();
        profileId = await lensHub.getProfileIdByHandle(MOCK_PROFILE_HANDLE);
        mintTimestamp = await lensHub.mintTimestampOf(FIRST_PROFILE_ID);
        tokenData = await lensHub.tokenDataOf(FIRST_PROFILE_ID);
        expect(owner).to.eq(userAddress);
        expect(totalSupply).to.eq(FIRST_PROFILE_ID);
        expect(profileId).to.eq(FIRST_PROFILE_ID);
        expect(mintTimestamp).to.eq(timestamp);
        expect(tokenData.owner).to.eq(userAddress);
        expect(tokenData.mintTimestamp).to.eq(timestamp);

        const secondProfileId = FIRST_PROFILE_ID + 1;
        const secondProfileHandle = '2nd_profile';
        expect(
          await createProfileReturningTokenId({
            sender: userTwo,
            vars: {
              to: userTwoAddress,
              handle: secondProfileHandle,
              imageURI: MOCK_PROFILE_URI,
              followModule: ZERO_ADDRESS,
              followModuleInitData: [],
              followNFTURI: MOCK_FOLLOW_NFT_URI,
            },
          })
        ).to.eq(secondProfileId);

        timestamp = await getTimestamp();
        owner = await lensHub.ownerOf(secondProfileId);
        totalSupply = await lensHub.totalSupply();
        profileId = await lensHub.getProfileIdByHandle(secondProfileHandle);
        mintTimestamp = await lensHub.mintTimestampOf(secondProfileId);
        tokenData = await lensHub.tokenDataOf(secondProfileId);
        expect(owner).to.eq(userTwoAddress);
        expect(totalSupply).to.eq(secondProfileId);
        expect(profileId).to.eq(secondProfileId);
        expect(mintTimestamp).to.eq(timestamp);
        expect(tokenData.owner).to.eq(userTwoAddress);
        expect(tokenData.mintTimestamp).to.eq(timestamp);
      });

      it('Should return the expected token IDs when creating profiles', async function () {
        expect(
          await createProfileReturningTokenId({
            vars: {
              to: userAddress,
              handle: 'token.id_1',
              imageURI: MOCK_PROFILE_URI,
              followModule: ZERO_ADDRESS,
              followModuleInitData: [],
              followNFTURI: MOCK_FOLLOW_NFT_URI,
            },
          })
        ).to.eq(FIRST_PROFILE_ID);

        const secondProfileId = FIRST_PROFILE_ID + 1;
        expect(
          await createProfileReturningTokenId({
            sender: userTwo,
            vars: {
              to: userTwoAddress,
              handle: 'token.id_2',
              imageURI: MOCK_PROFILE_URI,
              followModule: ZERO_ADDRESS,
              followModuleInitData: [],
              followNFTURI: MOCK_FOLLOW_NFT_URI,
            },
          })
        ).to.eq(secondProfileId);

        const thirdProfileId = secondProfileId + 1;
        expect(
          await createProfileReturningTokenId({
            vars: {
              to: userAddress,
              handle: 'token.id_3',
              imageURI: MOCK_PROFILE_URI,
              followModule: ZERO_ADDRESS,
              followModuleInitData: [],
              followNFTURI: MOCK_FOLLOW_NFT_URI,
            },
          })
        ).to.eq(thirdProfileId);
      });

      it('User should be able to create a profile with a handle including "-" and "_" characters', async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: 'morse--__-_--code',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
      });

      it('User should be able to create a profile with a handle 16 bytes long, then fail to create with the same handle, and create again with a different handle', async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: '123456789012345',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: '123456789012345',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.be.revertedWith(ERRORS.PROFILE_HANDLE_TAKEN);
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: 'abcdefghijklmno',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
      });

      it('User should be able to create a profile with a whitelisted follow module', async function () {
        await expect(
          lensHub.connect(governance).whitelistFollowModule(mockFollowModule.address, true)
        ).to.not.be.reverted;

        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: mockFollowModule.address,
            followModuleInitData: mockModuleData,
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
      });

      it('User should create a profile for userTwo', async function () {
        await expect(
          lensHub.createProfile({
            to: userTwoAddress,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        expect(await lensHub.ownerOf(FIRST_PROFILE_ID)).to.eq(userTwoAddress);
      });
    });
  });
});
