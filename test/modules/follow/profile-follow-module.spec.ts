import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import {
  abiCoder,
  FIRST_PROFILE_ID,
  governance,
  lensHub,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  profileFollowModule,
  userTwoAddress,
} from '../../__setup.spec';

makeSuiteCleanRoom('Profile Follow Module', function () {
  let DEFAULT_INIT_DATA;
  let DEFAULT_FOLLOW_DATA;

  beforeEach(async function () {
    DEFAULT_INIT_DATA = abiCoder.encode(['uint256'], [0]);
    DEFAULT_FOLLOW_DATA = abiCoder.encode(['uint256'], [1]);
    await expect(
      lensHub.createProfile({
        to: userTwoAddress,
        handle: MOCK_PROFILE_HANDLE,
        imageURI: MOCK_PROFILE_URI,
        followModule: ZERO_ADDRESS,
        followModuleData: [],
        followNFTURI: MOCK_FOLLOW_NFT_URI,
      })
    ).to.not.be.reverted;
    await expect(
      lensHub.connect(governance).whitelistFollowModule(profileFollowModule.address, true)
    ).to.not.be.reverted;
  });

  context('Negatives', function () {
    context.only('Initialization', function () {
      it('Initialize call should fail when sender is not the hub', async function () {
        await expect(
          profileFollowModule.initializeFollowModule(FIRST_PROFILE_ID, DEFAULT_INIT_DATA)
        ).to.be.revertedWith(ERRORS.NOT_HUB);
      });

      it('Initialize call should fail when data is not holding the revision number encoded', async function () {
        await expect(
          profileFollowModule.connect(lensHub.address).initializeFollowModule(FIRST_PROFILE_ID, [])
        ).to.be.reverted;
      });
    });

    context('Following', function () {
      it('Process follow call should fail when sender is not the hub', async function () {
        // TODO
      });

      it('Follow should fail when data is not holding the follower profile id encoded', async function () {
        // TODO
      });

      it('Follow should fail when the passed follower profile does not exist because has never been minted', async function () {
        // TODO
      });

      it('Follow should fail when the passed follower profile does not exist because has been burned', async function () {
        // TODO
      });

      it('Follow should fail when follower address is not the owner of the passed follower profile', async function () {
        // TODO
      });

      it('Follow should fail when the passed follower profile has already followed the profile in the current revision', async function () {
        // TODO
      });

      it('Follow should fail when switching to an old revision where the passed follower profile has alraedy followed the profile', async function () {
        // TODO
      });

      it('Follow should fail when the passed follower profile has already followed the profile in the current revision even after the profile nft has been transfered', async function () {
        // TODO
      });
    });
  });

  context('Scenarios', function () {
    context('Initialization', function () {
      it('Initialize call should succeed returning passed data if it is holding the revision number encoded', async function () {
        // TODO
      });
    });

    context('Processing follow', function () {
      it('Follow call should work when follower profile exists, is owned by the follower address and has not already followed the profile in the current revision', async function () {
        // TODO
      });

      it('Follow call should work after changing current revision when if it was already followed before by same profile in other revision', async function () {
        // TODO
      });

      it('Follow call should work with each of your profiles when you have more than one', async function () {
        // TODO
      });
    });
  });
});
