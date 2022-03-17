import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { FollowNFT__factory } from '../../../typechain-types';
import { MAX_UINT256, ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import {
  getAbbreviation,
  getFollowWithSigParts,
  getTimestamp,
  getToggleFollowWithSigParts,
  matchEvent,
  waitForTx,
} from '../../helpers/utils';
import {
  lensHub,
  peripheryDataProvider,
  FIRST_PROFILE_ID,
  makeSuiteCleanRoom,
  MOCK_PROFILE_HANDLE,
  testWallet,
  user,
  userTwo,
  userThree,
  userTwoAddress,
  userThreeAddress,
  MOCK_PROFILE_URI,
  userAddress,
  MOCK_FOLLOW_NFT_URI,
  OTHER_MOCK_URI,
} from '../../__setup.spec';

makeSuiteCleanRoom('ToggleFollowing', function () {
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
    await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
    await expect(lensHub.connect(userThree).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
    await expect(lensHub.connect(testWallet).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
  });
  context('Generic', function () {
    context('Negatives', function () {
      it('UserTwo should fail to toggle follow with an incorrect profileId', async function () {
        await expect(
          peripheryDataProvider.connect(userTwo).toggleFollow([FIRST_PROFILE_ID + 1], [true])
        ).to.be.revertedWith(ERRORS.FOLLOW_INVALID);
      });

      it('UserTwo should fail to toggle follow with array mismatch', async function () {
        await expect(
          peripheryDataProvider.connect(userTwo).toggleFollow([FIRST_PROFILE_ID, FIRST_PROFILE_ID], [])
        ).to.be.revertedWith(ERRORS.ARRAY_MISMATCH);
      });

      it('UserTwo should fail to toggle follow from a profile that has been burned', async function () {
        await expect(lensHub.burn(FIRST_PROFILE_ID)).to.not.be.reverted;
        await expect(
          peripheryDataProvider.connect(userTwo).toggleFollow([FIRST_PROFILE_ID], [true])
        ).to.be.revertedWith(ERRORS.TOKEN_DOES_NOT_EXIST);
      });

      it('UserTwo should fail to toggle follow for a followNFT that is not owned by them', async function () {
        const followNFTAddress = await lensHub.getFollowNFT(FIRST_PROFILE_ID);
        const followNFT = FollowNFT__factory.connect(followNFTAddress, user);

        await expect(
          followNFT.connect(userTwo).transferFrom(userTwoAddress, userAddress, 1)
        ).to.not.be.reverted;

        await expect(
          peripheryDataProvider.connect(userTwo).toggleFollow([FIRST_PROFILE_ID], [true])
        ).to.be.revertedWith(ERRORS.FOLLOW_INVALID);
      });
    });

    context('Scenarios', function () {
      it('UserTwo should toggle follow with true value, correct event should be emitted', async function () {
        const tx = peripheryDataProvider.connect(userTwo).toggleFollow([FIRST_PROFILE_ID], [true]);

        const receipt = await waitForTx(tx);

        expect(receipt.logs.length).to.eq(1);
        matchEvent(receipt, 'FollowsToggled', [
          userTwoAddress,
          [FIRST_PROFILE_ID],
          [true],
          await getTimestamp(),
        ]);
      });

      it('User should create another profile, userTwo follows, then toggles both, one true, one false, correct event should be emitted', async function () {
        await expect(
          lensHub.createProfile({
            to: userAddress,
            handle: 'otherhandle',
            imageURI: OTHER_MOCK_URI,
            followModule: ZERO_ADDRESS,
            followModuleData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID + 1], [[]])).to.not.be.reverted;

        const tx = peripheryDataProvider
          .connect(userTwo)
          .toggleFollow([FIRST_PROFILE_ID, FIRST_PROFILE_ID + 1], [true, false]);

        const receipt = await waitForTx(tx);

        expect(receipt.logs.length).to.eq(1);
        matchEvent(receipt, 'FollowsToggled', [
          userTwoAddress,
          [FIRST_PROFILE_ID, FIRST_PROFILE_ID + 1],
          [true, false],
          await getTimestamp(),
        ]);
      });

      it('UserTwo should toggle follow with false value, correct event should be emitted', async function () {
        const tx = peripheryDataProvider.connect(userTwo).toggleFollow([FIRST_PROFILE_ID], [false]);

        const receipt = await waitForTx(tx);

        expect(receipt.logs.length).to.eq(1);
        matchEvent(receipt, 'FollowsToggled', [
          userTwoAddress,
          [FIRST_PROFILE_ID],
          [false],
          await getTimestamp(),
        ]);
      });
    });
  });

  context('Meta-tx', function () {
    context('Negatives', function () {
      it('TestWallet should fail to toggle follow with sig with signature deadline mismatch', async function () {
        const nonce = (await peripheryDataProvider.sigNonces(testWallet.address)).toNumber();

        const { v, r, s } = await getToggleFollowWithSigParts(
          [FIRST_PROFILE_ID],
          [true],
          nonce,
          '0'
        );
        await expect(
          peripheryDataProvider.toggleFollowWithSig({
            follower: testWallet.address,
            profileIds: [FIRST_PROFILE_ID],
            enables: [true],
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should fail to toggle follow with sig with invalid deadline', async function () {
        const nonce = (await peripheryDataProvider.sigNonces(testWallet.address)).toNumber();

        const { v, r, s } = await getToggleFollowWithSigParts(
          [FIRST_PROFILE_ID],
          [true],
          nonce,
          '0'
        );
        await expect(
          peripheryDataProvider.toggleFollowWithSig({
            follower: testWallet.address,
            profileIds: [FIRST_PROFILE_ID],
            enables: [true],
            sig: {
              v,
              r,
              s,
              deadline: '0',
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_EXPIRED);
      });

      it('TestWallet should fail to toggle follow with sig with invalid nonce', async function () {
        const nonce = (await peripheryDataProvider.sigNonces(testWallet.address)).toNumber();

        const { v, r, s } = await getToggleFollowWithSigParts(
          [FIRST_PROFILE_ID],
          [true],
          nonce + 1,
          MAX_UINT256
        );

        await expect(
          peripheryDataProvider.toggleFollowWithSig({
            follower: testWallet.address,
            profileIds: [FIRST_PROFILE_ID],
            enables: [true],
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should fail to toggle follow a nonexistent profile with sig', async function () {
        const nonce = (await peripheryDataProvider.sigNonces(testWallet.address)).toNumber();
        const INVALID_PROFILE = FIRST_PROFILE_ID + 1;
        const { v, r, s } = await getToggleFollowWithSigParts(
          [INVALID_PROFILE],
          [true],
          nonce,
          MAX_UINT256
        );
        await expect(
          peripheryDataProvider.toggleFollowWithSig({
            follower: testWallet.address,
            profileIds: [INVALID_PROFILE],
            enables: [true],
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.FOLLOW_INVALID);
      });
    });

    context('Scenarios', function () {
      it('TestWallet should toggle follow profile 1 to true with sig, correct event should be emitted ', async function () {
        const nonce = (await peripheryDataProvider.sigNonces(testWallet.address)).toNumber();

        const { v, r, s } = await getToggleFollowWithSigParts(
          [FIRST_PROFILE_ID],
          [true],
          nonce,
          MAX_UINT256
        );

        const tx = peripheryDataProvider.toggleFollowWithSig({
          follower: testWallet.address,
          profileIds: [FIRST_PROFILE_ID],
          enables: [true],
          sig: {
            v,
            r,
            s,
            deadline: MAX_UINT256,
          },
        });

        const receipt = await waitForTx(tx);

        expect(receipt.logs.length).to.eq(1);
        matchEvent(receipt, 'FollowsToggled', [
          testWallet.address,
          [FIRST_PROFILE_ID],
          [true],
          await getTimestamp(),
        ]);
      });

      it('TestWallet should toggle follow profile 1 to false with sig, correct event should be emitted ', async function () {
        const nonce = (await peripheryDataProvider.sigNonces(testWallet.address)).toNumber();

        const enabled = false;
        const { v, r, s } = await getToggleFollowWithSigParts(
          [FIRST_PROFILE_ID],
          [enabled],
          nonce,
          MAX_UINT256
        );

        const tx = peripheryDataProvider.toggleFollowWithSig({
          follower: testWallet.address,
          profileIds: [FIRST_PROFILE_ID],
          enables: [enabled],
          sig: {
            v,
            r,
            s,
            deadline: MAX_UINT256,
          },
        });

        const receipt = await waitForTx(tx);

        expect(receipt.logs.length).to.eq(1);
        matchEvent(receipt, 'FollowsToggled', [
          testWallet.address,
          [FIRST_PROFILE_ID],
          [enabled],
          await getTimestamp(),
        ]);
      });
    });
  });
});
