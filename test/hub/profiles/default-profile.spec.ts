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
      it('UserTwo should fail to set the default profile on profile owned by user 1', async function () {
        await expect(
          lensHub.connect(userTwo).setDefaultProfile(FIRST_PROFILE_ID, userTwoAddress)
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER_OR_DISPATCHER);
      });

      it('UserOne should fail to change the default profile for address that doesnt own the profile', async function () {
        await expect(
          lensHub.setDefaultProfile(FIRST_PROFILE_ID, userTwoAddress)
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER);
      });
    });

    context('Scenarios', function () {
      it('User should set the default profile', async function () {
        await expect(lensHub.setDefaultProfile(FIRST_PROFILE_ID, userAddress)).to.not.be.reverted;
        expect((await lensHub.defaultProfile(userAddress)).toNumber()).to.eq(FIRST_PROFILE_ID);
      });

      it('User should set the default profile and then be able to unset it', async function () {
        await expect(lensHub.setDefaultProfile(FIRST_PROFILE_ID, userAddress)).to.not.be.reverted;
        expect((await lensHub.defaultProfile(userAddress)).toNumber()).to.eq(FIRST_PROFILE_ID);

        await expect(lensHub.setDefaultProfile(FIRST_PROFILE_ID, ZERO_ADDRESS)).to.not.be.reverted;
        expect((await lensHub.defaultProfile(userAddress)).toNumber()).to.eq(0);
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
          FIRST_PROFILE_ID,
          testWallet.address,
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
          FIRST_PROFILE_ID,
          testWallet.address,
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
          FIRST_PROFILE_ID,
          testWallet.address,
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
          FIRST_PROFILE_ID,
          testWallet.address,
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
          FIRST_PROFILE_ID,
          testWallet.address,
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

        expect(defaultProfileBeforeUse.toNumber()).to.eq(0);
        expect(defaultProfileAfter.toNumber()).to.eq(FIRST_PROFILE_ID);
      });
    });
  });
});
