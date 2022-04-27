import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { FollowNFT, FollowNFT__factory } from '../../typechain-types';
import { MAX_UINT256, ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import {
  cancelWithPermitForAll,
  getBlockNumber,
  getDelegateBySigParts,
  mine,
} from '../helpers/utils';
import {
  FIRST_PROFILE_ID,
  governanceAddress,
  helper,
  lensHub,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  OTHER_MOCK_URI,
  testWallet,
  user,
  userAddress,
  userTwo,
  userTwoAddress,
} from '../__setup.spec';

makeSuiteCleanRoom('Follow NFT', function () {
  beforeEach(async function () {
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
  });

  context('generic', function () {
    context('Negatives', function () {
      it('User should follow, and fail to re-initialize the follow NFT', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );

        await expect(followNFT.initialize(FIRST_PROFILE_ID)).to.be.revertedWith(
          ERRORS.INITIALIZED
        );
      });

      it("User should follow, userTwo should fail to burn user's follow NFT", async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          userTwo
        );

        await expect(followNFT.burn(1)).to.be.revertedWith(ERRORS.NOT_OWNER_OR_APPROVED);
      });

      it('User should follow, then fail to mint a follow NFT directly', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );

        await expect(followNFT.mint(userAddress)).to.be.revertedWith(ERRORS.NOT_HUB);
      });

      it('User should follow, then fail to get the power at a future block', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );

        const blockNumber = await getBlockNumber();

        await expect(
          followNFT.getPowerByBlockNumber(userAddress, blockNumber + 1)
        ).to.be.revertedWith(ERRORS.BLOCK_NUMBER_INVALID);
        await expect(followNFT.getDelegatedSupplyByBlockNumber(blockNumber + 1)).to.be.revertedWith(
          ERRORS.BLOCK_NUMBER_INVALID
        );
      });

      it('user should follow, then fail to get the URI for a token that does not exist', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );
        await expect(followNFT.tokenURI(2)).to.be.revertedWith(ERRORS.TOKEN_DOES_NOT_EXIST);
      });
    });

    context('Scenarios', function () {
      it('User should follow, then burn their follow NFT, governance power is zero before and after', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );
        const firstCheckpointBlock = await getBlockNumber();

        await expect(followNFT.burn(1)).to.not.be.reverted;

        const secondCheckpointBlock = await getBlockNumber();

        expect(await followNFT.getPowerByBlockNumber(userAddress, firstCheckpointBlock)).to.eq(0);
        expect(await followNFT.getDelegatedSupplyByBlockNumber(firstCheckpointBlock)).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(userAddress, secondCheckpointBlock)).to.eq(0);
        expect(await followNFT.getDelegatedSupplyByBlockNumber(secondCheckpointBlock)).to.eq(0);
      });

      it('User should follow, delegate to themself, governance power should be zero before the last block, and 1 at the current block', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );

        await expect(followNFT.delegate(userAddress)).to.not.be.reverted;

        const blockNumber = await getBlockNumber();

        expect(await followNFT.getPowerByBlockNumber(userAddress, blockNumber - 1)).to.eq(0);
        expect(await followNFT.getDelegatedSupplyByBlockNumber(blockNumber - 1)).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(userAddress, blockNumber)).to.eq(1);
        expect(await followNFT.getDelegatedSupplyByBlockNumber(blockNumber)).to.eq(1);
      });

      it('User and userTwo should follow, governance power should be zero, then users delegate multiple times, governance power should be accurate throughout', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );

        const firstCheckpointBlock = await getBlockNumber();

        // First, users delegate to themselves
        await expect(followNFT.delegate(userAddress)).to.not.be.reverted;
        await expect(followNFT.connect(userTwo).delegate(userTwoAddress)).to.not.be.reverted;
        const secondCheckpointBlock = await getBlockNumber();

        // Second, userTWo delegates to user
        await expect(followNFT.connect(userTwo).delegate(userAddress)).to.not.be.reverted;
        const thirdCheckpointBlock = await getBlockNumber();

        // Third, user delegates to userTwo
        await expect(followNFT.delegate(userTwoAddress)).to.not.be.reverted;
        const fourthCheckpointBlock = await getBlockNumber();

        // Fourth, users delegate to governance
        await expect(followNFT.delegate(governanceAddress)).to.not.be.reverted;
        await expect(followNFT.connect(userTwo).delegate(governanceAddress)).to.not.be.reverted;
        const fifthCheckpointBlock = await getBlockNumber();

        // Fifth, users delegate to zero (remove delegation)
        await expect(followNFT.delegate(ZERO_ADDRESS)).to.not.be.reverted;
        await expect(followNFT.connect(userTwo).delegate(ZERO_ADDRESS)).to.not.be.reverted;
        const sixthCheckpointBlock = await getBlockNumber();

        // Sixth, users delegate to user
        await expect(followNFT.delegate(userAddress)).to.not.be.reverted;
        await expect(followNFT.connect(userTwo).delegate(userAddress)).to.not.be.reverted;
        const seventhCheckpointBlock = await getBlockNumber();

        // First validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, firstCheckpointBlock)).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, firstCheckpointBlock)).to.eq(
          0
        );
        expect(await followNFT.getDelegatedSupplyByBlockNumber(firstCheckpointBlock)).to.eq(0);

        // Second validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, secondCheckpointBlock)).to.eq(1);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, secondCheckpointBlock)).to.eq(
          1
        );
        expect(await followNFT.getDelegatedSupplyByBlockNumber(secondCheckpointBlock)).to.eq(2);

        // Third validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, thirdCheckpointBlock)).to.eq(2);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, thirdCheckpointBlock)).to.eq(
          0
        );
        expect(await followNFT.getDelegatedSupplyByBlockNumber(thirdCheckpointBlock)).to.eq(2);

        // Fourth validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, fourthCheckpointBlock)).to.eq(1);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, fourthCheckpointBlock)).to.eq(
          1
        );
        expect(await followNFT.getDelegatedSupplyByBlockNumber(fourthCheckpointBlock)).to.eq(2);

        // Fifth validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, fifthCheckpointBlock)).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, fifthCheckpointBlock)).to.eq(
          0
        );
        expect(
          await followNFT.getPowerByBlockNumber(governanceAddress, fifthCheckpointBlock)
        ).to.eq(2);
        expect(await followNFT.getDelegatedSupplyByBlockNumber(fifthCheckpointBlock)).to.eq(2);

        // Sixth validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, sixthCheckpointBlock)).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, sixthCheckpointBlock)).to.eq(
          0
        );
        expect(
          await followNFT.getPowerByBlockNumber(governanceAddress, sixthCheckpointBlock)
        ).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(ZERO_ADDRESS, sixthCheckpointBlock)).to.eq(0);
        expect(await followNFT.getDelegatedSupplyByBlockNumber(sixthCheckpointBlock)).to.eq(0);

        // Seventh validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, seventhCheckpointBlock)).to.eq(2);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, seventhCheckpointBlock)).to.eq(
          0
        );
        expect(await followNFT.getDelegatedSupplyByBlockNumber(seventhCheckpointBlock)).to.eq(2);
      });

      it('User and userTwo should follow, delegate to themselves, 10 blocks later user delegates to userTwo, 10 blocks later both delegate to user, governance power should be accurate throughout', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );

        await expect(followNFT.delegate(userAddress)).to.not.be.reverted;
        await expect(followNFT.connect(userTwo).delegate(userTwoAddress)).to.not.be.reverted;
        const firstCheckpointBlock = await getBlockNumber();

        await mine(10);

        await expect(followNFT.delegate(userTwoAddress)).to.not.be.reverted;
        const secondCheckpointBlock = await getBlockNumber();

        await mine(10);

        await expect(followNFT.delegate(userAddress)).to.not.be.reverted;
        await expect(followNFT.connect(userTwo).delegate(userAddress)).to.not.be.reverted;
        const thirdCheckpointBlock = await getBlockNumber();

        // First validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, firstCheckpointBlock)).to.eq(1);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, firstCheckpointBlock)).to.eq(
          1
        );
        expect(await followNFT.getDelegatedSupplyByBlockNumber(firstCheckpointBlock)).to.eq(2);

        // Second validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, secondCheckpointBlock)).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, secondCheckpointBlock)).to.eq(
          2
        );
        expect(await followNFT.getDelegatedSupplyByBlockNumber(secondCheckpointBlock)).to.eq(2);

        // Last validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, thirdCheckpointBlock)).to.eq(2);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, thirdCheckpointBlock)).to.eq(
          0
        );
        expect(await followNFT.getDelegatedSupplyByBlockNumber(secondCheckpointBlock)).to.eq(2);
      });

      it('user and userTwo should follow, user delegates to userTwo twice, governance power should be accurate', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );

        await expect(followNFT.delegate(userTwoAddress)).to.not.be.reverted;
        await expect(followNFT.delegate(userTwoAddress)).to.not.be.reverted;

        const blockNumber = await getBlockNumber();
        expect(await followNFT.getPowerByBlockNumber(userAddress, blockNumber)).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, blockNumber)).to.eq(1);
        expect(await followNFT.getDelegatedSupplyByBlockNumber(blockNumber)).to.eq(1);
      });

      it('User and userTwo should follow, then transfer their NFTs to the helper contract, then the helper contract batch delegates to user one, then user two, governance power should be accurate', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );

        await expect(followNFT.transferFrom(userAddress, helper.address, 1)).to.not.be.reverted;
        await expect(
          followNFT.connect(userTwo).transferFrom(userTwoAddress, helper.address, 2)
        ).to.not.be.reverted;

        const firstCheckpointBlock = await getBlockNumber();
        await expect(
          helper.batchDelegate(followNFT.address, userAddress, userTwoAddress)
        ).to.not.be.reverted;

        const secondCheckpointBlock = await getBlockNumber();

        // First validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, firstCheckpointBlock)).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, firstCheckpointBlock)).to.eq(
          0
        );
        expect(await followNFT.getPowerByBlockNumber(helper.address, firstCheckpointBlock)).to.eq(
          0
        );
        expect(await followNFT.getDelegatedSupplyByBlockNumber(firstCheckpointBlock)).to.eq(0);

        // Second validation
        expect(await followNFT.getPowerByBlockNumber(userAddress, secondCheckpointBlock)).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(userTwoAddress, secondCheckpointBlock)).to.eq(
          2
        );
        expect(await followNFT.getPowerByBlockNumber(helper.address, secondCheckpointBlock)).to.eq(
          0
        );
        expect(await followNFT.getDelegatedSupplyByBlockNumber(secondCheckpointBlock)).to.eq(2);
      });

      it('user should follow, then get the URI for their token, URI should be accurate', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFT = FollowNFT__factory.connect(
          await lensHub.getFollowNFT(FIRST_PROFILE_ID),
          user
        );
        expect(await followNFT.tokenURI(1)).to.eq(MOCK_FOLLOW_NFT_URI);
      });
    });
  });

  context('meta-tx', function () {
    let followNFT: FollowNFT;
    beforeEach(async function () {
      await expect(lensHub.connect(testWallet).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
      followNFT = FollowNFT__factory.connect(await lensHub.getFollowNFT(FIRST_PROFILE_ID), user);
    });

    context('negatives', function () {
      it('TestWallet should fail to delegate with sig with signature deadline mismatch', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();

        const { v, r, s } = await getDelegateBySigParts(
          followNFT.address,
          await followNFT.name(),
          testWallet.address,
          userAddress,
          nonce,
          '0'
        );

        await expect(
          followNFT.delegateBySig(testWallet.address, userAddress, {
            v,
            r,
            s,
            deadline: MAX_UINT256,
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should fail to delegate with sig with invalid deadline', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();

        const { v, r, s } = await getDelegateBySigParts(
          followNFT.address,
          await followNFT.name(),
          testWallet.address,
          userAddress,
          nonce,
          '0'
        );

        await expect(
          followNFT.delegateBySig(testWallet.address, userAddress, {
            v,
            r,
            s,
            deadline: '0',
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_EXPIRED);
      });

      it('TestWallet should fail to delegate with sig with invalid nonce', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();

        const { v, r, s } = await getDelegateBySigParts(
          followNFT.address,
          await followNFT.name(),
          testWallet.address,
          userAddress,
          nonce + 1,
          MAX_UINT256
        );

        await expect(
          followNFT.delegateBySig(testWallet.address, userAddress, {
            v,
            r,
            s,
            deadline: MAX_UINT256,
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should sign attempt to delegate by sig, cancel with empty permitForAll, then fail to delegate by sig', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();

        const { v, r, s } = await getDelegateBySigParts(
          followNFT.address,
          await followNFT.name(),
          testWallet.address,
          userAddress,
          nonce,
          MAX_UINT256
        );

        await cancelWithPermitForAll(followNFT.address);

        await expect(
          followNFT.delegateBySig(testWallet.address, userAddress, {
            v,
            r,
            s,
            deadline: MAX_UINT256,
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });
    });

    context('Scenarios', function () {
      it('TestWallet should delegate by sig to user, governance power should be accurate before and after', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();

        const { v, r, s } = await getDelegateBySigParts(
          followNFT.address,
          await followNFT.name(),
          testWallet.address,
          userAddress,
          nonce,
          MAX_UINT256
        );

        let blockNumber = await getBlockNumber();
        expect(await followNFT.getPowerByBlockNumber(userAddress, blockNumber)).to.eq(0);
        expect(await followNFT.getPowerByBlockNumber(testWallet.address, blockNumber)).to.eq(0);
        expect(await followNFT.getDelegatedSupplyByBlockNumber(blockNumber)).to.eq(0);

        await expect(
          followNFT.delegateBySig(testWallet.address, userAddress, {
            v,
            r,
            s,
            deadline: MAX_UINT256,
          })
        ).to.not.be.reverted;

        blockNumber = await getBlockNumber();
        expect(await followNFT.getPowerByBlockNumber(userAddress, blockNumber)).to.eq(1);
        expect(await followNFT.getPowerByBlockNumber(testWallet.address, blockNumber)).to.eq(0);
        expect(await followNFT.getDelegatedSupplyByBlockNumber(blockNumber)).to.eq(1);
      });
    });
  });
});
