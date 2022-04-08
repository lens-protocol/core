import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { BytesLike } from 'ethers';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import { getTimestamp, matchEvent, waitForTx } from '../../helpers/utils';
import {
  abiCoder,
  FIRST_PROFILE_ID,
  governance,
  lensHub,
  lensHubImpl,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  profileFollowModule,
  userAddress,
  userThreeAddress,
  userTwo,
  userTwoAddress,
} from '../../__setup.spec';

makeSuiteCleanRoom('Profile Follow Module', function () {
  let DEFAULT_INIT_DATA: BytesLike;
  let DEFAULT_FOLLOW_DATA: BytesLike;

  before(async function () {
    DEFAULT_INIT_DATA = abiCoder.encode(['uint256'], [0]);
    DEFAULT_FOLLOW_DATA = abiCoder.encode(['uint256'], [FIRST_PROFILE_ID + 1]);
    await expect(
      lensHub.connect(governance).whitelistFollowModule(profileFollowModule.address, true)
    ).to.not.be.reverted;
  });

  context('Negatives', function () {
    context('Initialization', function () {
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
      beforeEach(async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: profileFollowModule.address,
            followModuleInitData: DEFAULT_INIT_DATA,
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
      });

      it('UserTwo should fail to process follow without being the hub', async function () {
        await expect(
          profileFollowModule.connect(userTwo).processFollow(userTwoAddress, FIRST_PROFILE_ID, [])
        ).to.be.revertedWith(ERRORS.NOT_HUB);
      });

      it('Follow should fail when data is not holding the follower profile id encoded', async function () {
        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [])).to.be.revertedWith(
          ERRORS.ARRAY_MISMATCH
        );
      });

      it('Follow should fail when the passed follower profile does not exist because has never been minted', async function () {
        const data = abiCoder.encode(['uint256'], [FIRST_PROFILE_ID + 1]);
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [data])
        ).to.be.revertedWith(ERRORS.ERC721_QUERY_FOR_NONEXISTENT_TOKEN);
      });

      it('Follow should fail when the passed follower profile does not exist because has been burned', async function () {
        const secondProfileId = FIRST_PROFILE_ID + 1;
        await expect(
          lensHub.createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(lensHub.connect(userTwo).burn(secondProfileId)).to.not.be.reverted;

        const data = abiCoder.encode(['uint256'], [secondProfileId]);
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [data])
        ).to.be.revertedWith(ERRORS.ERC721_QUERY_FOR_NONEXISTENT_TOKEN);
      });

      it('Follow should fail when follower address is not the owner of the passed follower profile', async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: 'user',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;

        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER);
      });

      it('Follow should fail when the passed follower profile has already followed the profile in the current revision', async function () {
        await expect(
          lensHub.createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.be.revertedWith(ERRORS.FOLLOW_INVALID);
      });

      it('Follow should fail when switching to an old revision where the passed follower profile has already followed the profile', async function () {
        await expect(
          lensHub.createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.not.be.reverted;

        // Update the revision
        const data = abiCoder.encode(['uint256'], [1]);
        await expect(
          lensHub.setFollowModule(FIRST_PROFILE_ID, profileFollowModule.address, data)
        ).to.not.be.reverted;
        // We check that profile can be followed again but through callStatic to avoid state-changes
        await expect(
          lensHub.connect(userTwo).callStatic.follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.not.be.reverted;

        // Return the revision to the original, follow should be invalid
        await expect(
          lensHub.setFollowModule(FIRST_PROFILE_ID, profileFollowModule.address, DEFAULT_INIT_DATA)
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.be.revertedWith(ERRORS.FOLLOW_INVALID);
      });

      it('Follow should fail when the passed follower profile has already followed the profile in the current revision even after the profile nft has been transfered', async function () {
        await expect(
          lensHub.createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.not.be.reverted;

        await expect(
          lensHub.transferFrom(userAddress, userThreeAddress, FIRST_PROFILE_ID)
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.be.revertedWith(ERRORS.FOLLOW_INVALID);
      });
    });
  });

  context('Scenarios', function () {
    context('Initialization', function () {
      it('Initialize call should succeed returning passed data if it is holding the revision number encoded', async function () {
        expect(
          await profileFollowModule
            .connect(lensHub.address)
            .callStatic.initializeFollowModule(FIRST_PROFILE_ID, DEFAULT_INIT_DATA)
        ).to.eq(DEFAULT_INIT_DATA);
      });

      it('Profile creation using profile follow module should succeed and emit expected event', async function () {
        const tx = lensHub.createProfile({
          to: userAddress,
          handle: MOCK_PROFILE_HANDLE,
          imageURI: MOCK_PROFILE_URI,
          followModule: profileFollowModule.address,
          followModuleInitData: DEFAULT_INIT_DATA,
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        });

        const receipt = await waitForTx(tx);

        expect(receipt.logs.length).to.eq(2);
        matchEvent(receipt, 'Transfer', [ZERO_ADDRESS, userAddress, FIRST_PROFILE_ID], lensHubImpl);
        matchEvent(receipt, 'ProfileCreated', [
          FIRST_PROFILE_ID,
          userAddress,
          userAddress,
          MOCK_PROFILE_HANDLE,
          MOCK_PROFILE_URI,
          profileFollowModule.address,
          DEFAULT_INIT_DATA,
          MOCK_FOLLOW_NFT_URI,
          await getTimestamp(),
        ]);
      });

      it('User should create a profile then set the profile follow module as the follow module, correct event should be emitted', async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;

        const tx = lensHub.setFollowModule(
          FIRST_PROFILE_ID,
          profileFollowModule.address,
          DEFAULT_INIT_DATA
        );

        const receipt = await waitForTx(tx);

        expect(receipt.logs.length).to.eq(1);
        matchEvent(receipt, 'FollowModuleSet', [
          FIRST_PROFILE_ID,
          profileFollowModule.address,
          DEFAULT_INIT_DATA,
          await getTimestamp(),
        ]);
      });
    });

    context('Processing follow', function () {
      beforeEach(async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: profileFollowModule.address,
            followModuleInitData: DEFAULT_INIT_DATA,
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
      });

      it('Follow call should work when follower profile exists, is owned by the follower address and has not already followed the profile in the current revision', async function () {
        await expect(
          lensHub.createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.not.be.reverted;
      });

      it('Follow call should work after changing current revision when if it was already followed before by same profile in other revision', async function () {
        await expect(
          lensHub.createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.not.be.reverted;

        const data = abiCoder.encode(['uint256'], [1]);
        await expect(
          lensHub.setFollowModule(FIRST_PROFILE_ID, profileFollowModule.address, data)
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.not.be.reverted;
      });

      it('Follow call should work with each of your profiles when you have more than one', async function () {
        await expect(
          lensHub.createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.createProfile({
            to: userTwoAddress,
            handle: 'usertwo2',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;

        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [DEFAULT_FOLLOW_DATA])
        ).to.not.be.reverted;
        const data = abiCoder.encode(['uint256'], [FIRST_PROFILE_ID + 2]);
        await expect(
          lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [data])
        ).to.not.be.reverted;
      });
    });
  });
});
