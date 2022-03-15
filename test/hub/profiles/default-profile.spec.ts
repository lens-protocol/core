import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { MAX_UINT256, ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import { cancelWithPermitForAll, getSetDefaultProfileWithSigParts } from '../../helpers/utils';
import {
  FIRST_PROFILE_ID,
  lensHub,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  testWallet,
  userAddress,
  userTwo,
  userTwoAddress,
} from '../../__setup.spec';

makeSuiteCleanRoom('Default profile Functionality', function () {
  context('Generic', function () {
    beforeEach(async function () {
      await expect(
        lensHub.createProfile({
          to: userAddress,
          handle: MOCK_PROFILE_HANDLE,
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.not.be.reverted;
    });

    context('Negatives', function () {
      it('UserTwo should fail to set the default profile as a profile owned by user 1', async function () {
        await expect(
          lensHub.connect(userTwo).setDefaultProfile(FIRST_PROFILE_ID)
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER);
      });
    });

    context('Scenarios', function () {
      it('User should set the default profile', async function () {
        await expect(lensHub.setDefaultProfile(FIRST_PROFILE_ID)).to.not.be.reverted;
        expect(await lensHub.defaultProfile(userAddress)).to.eq(FIRST_PROFILE_ID);
      });

      it('User should set the default profile and then be able to unset it', async function () {
        await expect(lensHub.setDefaultProfile(FIRST_PROFILE_ID)).to.not.be.reverted;
        expect(await lensHub.defaultProfile(userAddress)).to.eq(FIRST_PROFILE_ID);

        await expect(lensHub.setDefaultProfile(0)).to.not.be.reverted;
        expect(await lensHub.defaultProfile(userAddress)).to.eq(0);
      });

      it('User should set the default profile and then be able to change it to another', async function () {
        await expect(lensHub.setDefaultProfile(FIRST_PROFILE_ID)).to.not.be.reverted;
        expect(await lensHub.defaultProfile(userAddress)).to.eq(FIRST_PROFILE_ID);

        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: new Date().getTime().toString(),
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;

        await expect(lensHub.setDefaultProfile(2)).to.not.be.reverted;
        expect(await lensHub.defaultProfile(userAddress)).to.eq(2);
      });

      it('User should set the default profile and then transfer it, their default profile should be unset', async function () {
        await expect(lensHub.setDefaultProfile(FIRST_PROFILE_ID)).to.not.be.reverted;
        expect(await lensHub.defaultProfile(userAddress)).to.eq(FIRST_PROFILE_ID);

        await expect(
          lensHub.transferFrom(userAddress, userTwoAddress, FIRST_PROFILE_ID)
        ).to.not.be.reverted;
        expect(await lensHub.defaultProfile(userAddress)).to.eq(0);
      });
    });
  });

  context('Meta-tx', function () {
    beforeEach(async function () {
      await expect(
        lensHub.connect(testWallet).createProfile({
          to: testWallet.address,
          handle: MOCK_PROFILE_HANDLE,
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.not.be.reverted;
    });

    context('Negatives', function () {
      it('TestWallet should fail to set default profile with sig with signature deadline mismatch', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDefaultProfileWithSigParts(
          testWallet.address,
          FIRST_PROFILE_ID,
          nonce,
          '0'
        );

        await expect(
          lensHub.setDefaultProfileWithSig({
            profileId: FIRST_PROFILE_ID,
            wallet: testWallet.address,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should fail to set default profile with sig with invalid deadline', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDefaultProfileWithSigParts(
          testWallet.address,
          FIRST_PROFILE_ID,
          nonce,
          '0'
        );

        await expect(
          lensHub.setDefaultProfileWithSig({
            profileId: FIRST_PROFILE_ID,
            wallet: testWallet.address,
            sig: {
              v,
              r,
              s,
              deadline: '0',
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_EXPIRED);
      });

      it('TestWallet should fail to set default profile with sig with invalid nonce', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDefaultProfileWithSigParts(
          testWallet.address,
          FIRST_PROFILE_ID,
          nonce + 1,
          MAX_UINT256
        );

        await expect(
          lensHub.setDefaultProfileWithSig({
            profileId: FIRST_PROFILE_ID,
            wallet: testWallet.address,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should sign attempt to set default profile with sig, cancel with empty permitForAll, then fail to set default profile with sig', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDefaultProfileWithSigParts(
          testWallet.address,
          FIRST_PROFILE_ID,
          nonce,
          MAX_UINT256
        );

        await cancelWithPermitForAll();

        await expect(
          lensHub.setDefaultProfileWithSig({
            profileId: FIRST_PROFILE_ID,
            wallet: testWallet.address,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });
    });

    context('Scenarios', function () {
      it('TestWallet should set the default profile with sig', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDefaultProfileWithSigParts(
          testWallet.address,
          FIRST_PROFILE_ID,
          nonce,
          MAX_UINT256
        );

        const defaultProfileBeforeUse = await lensHub.defaultProfile(testWallet.address);

        await expect(
          lensHub.setDefaultProfileWithSig({
            profileId: FIRST_PROFILE_ID,
            wallet: testWallet.address,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.not.be.reverted;

        const defaultProfileAfter = await lensHub.defaultProfile(testWallet.address);

        expect(defaultProfileBeforeUse).to.eq(0);
        expect(defaultProfileAfter).to.eq(FIRST_PROFILE_ID);
      });

      it('TestWallet should set the default profile with sig and then be able to unset it', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDefaultProfileWithSigParts(
          testWallet.address,
          FIRST_PROFILE_ID,
          nonce,
          MAX_UINT256
        );

        const defaultProfileBeforeUse = await lensHub.defaultProfile(testWallet.address);

        await expect(
          lensHub.setDefaultProfileWithSig({
            wallet: testWallet.address,
            profileId: FIRST_PROFILE_ID,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.not.be.reverted;

        const defaultProfileAfter = await lensHub.defaultProfile(testWallet.address);

        expect(defaultProfileBeforeUse).to.eq(0);
        expect(defaultProfileAfter).to.eq(FIRST_PROFILE_ID);

        const nonce2 = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const signature2 = await getSetDefaultProfileWithSigParts(
          testWallet.address,
          0,
          nonce2,
          MAX_UINT256
        );

        const defaultProfileBeforeUse2 = await lensHub.defaultProfile(testWallet.address);

        await expect(
          lensHub.setDefaultProfileWithSig({
            wallet: testWallet.address,
            profileId: 0,
            sig: {
              v: signature2.v,
              r: signature2.r,
              s: signature2.s,
              deadline: MAX_UINT256,
            },
          })
        ).to.not.be.reverted;

        const defaultProfileAfter2 = await lensHub.defaultProfile(testWallet.address);

        expect(defaultProfileBeforeUse2).to.eq(FIRST_PROFILE_ID);
        expect(defaultProfileAfter2).to.eq(0);
      });

      it('TestWallet should set the default profile and then be able to change it to another', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDefaultProfileWithSigParts(
          testWallet.address,
          FIRST_PROFILE_ID,
          nonce,
          MAX_UINT256
        );

        const defaultProfileBeforeUse = await lensHub.defaultProfile(testWallet.address);

        await expect(
          lensHub.setDefaultProfileWithSig({
            profileId: FIRST_PROFILE_ID,
            wallet: testWallet.address,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.not.be.reverted;

        const defaultProfileAfter = await lensHub.defaultProfile(testWallet.address);

        expect(defaultProfileBeforeUse).to.eq(0);
        expect(defaultProfileAfter).to.eq(FIRST_PROFILE_ID);

        await expect(
          lensHub.createProfile({
            to: testWallet.address,
            handle: new Date().getTime().toString(),
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;

        const nonce2 = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const signature2 = await getSetDefaultProfileWithSigParts(
          testWallet.address,
          FIRST_PROFILE_ID + 1,
          nonce2,
          MAX_UINT256
        );

        const defaultProfileBeforeUse2 = await lensHub.defaultProfile(testWallet.address);

        await expect(
          lensHub.setDefaultProfileWithSig({
            profileId: 2,
            wallet: testWallet.address,
            sig: {
              v: signature2.v,
              r: signature2.r,
              s: signature2.s,
              deadline: MAX_UINT256,
            },
          })
        ).to.not.be.reverted;

        const defaultProfileAfter2 = await lensHub.defaultProfile(testWallet.address);

        expect(defaultProfileBeforeUse2).to.eq(1);
        expect(defaultProfileAfter2).to.eq(2);
      });
    });
  });
});
