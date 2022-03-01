import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import {
  FIRST_PROFILE_ID,
  lensHub,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  userAddress,
  userTwo,
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
          lensHub.connect(userTwo).setDefaultProfile(FIRST_PROFILE_ID)
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER);
      });

      it('UserTwo should fail to change the default profile for profile one', async function () {
        await expect(
          lensHub.connect(userTwo).setDefaultProfile(FIRST_PROFILE_ID)
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER);
      });
    });

    context('Scenarios', function () {
      it('User should set the default profile', async function () {
        await expect(lensHub.setDefaultProfile(FIRST_PROFILE_ID)).to.not.be.reverted;
        expect(await lensHub.defaultProfile(lensHub.address)).to.eq(FIRST_PROFILE_ID);
      });
    });
  });
});
