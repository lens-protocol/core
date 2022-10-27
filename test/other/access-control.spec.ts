import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
  FollowNFT__factory,
  CollectNFT__factory,
  AccessControl__factory,
  FeeFollowModule__factory,
} from '../../typechain-types';
import { MAX_UINT256, ZERO_ADDRESS } from '../helpers/constants';
import { getTimestamp, matchEvent, waitForTx } from '../helpers/utils';
import {
  deployer,
  freeCollectModule,
  FIRST_PROFILE_ID,
  governance,
  lensHub,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  MOCK_URI,
  moduleGlobals,
  user,
  userAddress,
  userTwo,
  userTwoAddress,
  userThreeAddress,
  abiCoder,
  feeFollowModule,
  currency,
} from '../__setup.spec';

/**
 * @dev Some of these tests may be redundant, but are still present to ensure an isolated environment,
 * in particular if other test files are changed.
 */
makeSuiteCleanRoom('AccessControl', function () {
  let accessControl;
  before(async function () {
    accessControl = await new AccessControl__factory(deployer).deploy(lensHub.address);
  });

  beforeEach(async function () {
    const receipt = await waitForTx(
      lensHub.createProfile({
        to: userAddress,
        handle: MOCK_PROFILE_HANDLE,
        imageURI: MOCK_PROFILE_URI,
        followModule: ZERO_ADDRESS,
        followModuleInitData: [],
        followNFTURI: MOCK_FOLLOW_NFT_URI,
      })
    );

    expect(receipt.logs.length).to.eq(2);
    matchEvent(receipt, 'ProfileCreated', [
      FIRST_PROFILE_ID,
      userAddress,
      userAddress,
      MOCK_PROFILE_HANDLE,
      MOCK_PROFILE_URI,
      ZERO_ADDRESS,
      [],
      MOCK_FOLLOW_NFT_URI,
      await getTimestamp(),
    ]);
  });

  context('Has Access', function () {
    it('hasAccess should return true if user owns the profile', async function () {
      expect(await lensHub.ownerOf(FIRST_PROFILE_ID)).to.be.eq(userAddress);
      expect(await accessControl.hasAccess(userAddress, FIRST_PROFILE_ID, [])).to.be.true;
    });

    it('hasAccess should return false if user does not own the profile', async function () {
      expect(await lensHub.ownerOf(FIRST_PROFILE_ID)).to.not.be.eq(userTwoAddress);
      expect(await accessControl.hasAccess(userTwoAddress, FIRST_PROFILE_ID, [])).to.be.false;
    });
  });

  context('Is Following', function () {
    before(async function () {
      await expect(
        lensHub.connect(governance).whitelistFollowModule(feeFollowModule.address, true)
      ).to.not.be.reverted;
      await expect(
        moduleGlobals.connect(governance).whitelistCurrency(currency.address, true)
      ).to.not.be.reverted;
    });

    it('isFollowing should return true if user follows the profile (without follow module, by holding a followNFT)', async function () {
      await lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]]);
      const followNFTAddress = await lensHub.getFollowNFT(FIRST_PROFILE_ID);
      const followNFT = FollowNFT__factory.connect(followNFTAddress, user);
      expect(await followNFT.balanceOf(userTwoAddress)).is.gt(0);

      expect(await accessControl.isFollowing(userTwoAddress, FIRST_PROFILE_ID, 0, [])).to.be.true;
    });

    it('isFollowing should return false if user does not follow the profile (without follow module, not holding a followNFT)', async function () {
      await lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]]);
      const followNFTAddress = await lensHub.getFollowNFT(FIRST_PROFILE_ID);
      const followNFT = FollowNFT__factory.connect(followNFTAddress, user);
      expect(await followNFT.balanceOf(userThreeAddress)).is.eq(0);
      expect(
        await accessControl.isFollowing(userThreeAddress, FIRST_PROFILE_ID, 0, [])
      ).to.be.false;
    });

    it('isFollowing should return true if user follows the profile (with followModule, querying it)', async function () {
      const followModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address'],
        [1, currency.address, userAddress]
      );
      await lensHub
        .connect(user)
        .setFollowModule(FIRST_PROFILE_ID, feeFollowModule.address, followModuleInitData);

      await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
      await expect(
        currency.connect(userTwo).approve(feeFollowModule.address, MAX_UINT256)
      ).to.not.be.reverted;
      const data = abiCoder.encode(['address', 'uint256'], [currency.address, 1]);
      await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [data])).to.not.be.reverted;

      const followModuleAddress = await lensHub.getFollowModule(FIRST_PROFILE_ID);
      const followModule = FeeFollowModule__factory.connect(followModuleAddress, user);
      expect(await followModule.isFollowing(FIRST_PROFILE_ID, userTwoAddress, 0)).to.be.true;
      expect(await accessControl.isFollowing(userTwoAddress, FIRST_PROFILE_ID, 0, [])).to.be.true;
    });

    it('isFollowing should return false if user doesnt follow the profile (with followModule, querying it)', async function () {
      const followModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address'],
        [1, currency.address, userAddress]
      );
      await lensHub
        .connect(user)
        .setFollowModule(FIRST_PROFILE_ID, feeFollowModule.address, followModuleInitData);

      await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
      await expect(
        currency.connect(userTwo).approve(feeFollowModule.address, MAX_UINT256)
      ).to.not.be.reverted;
      const data = abiCoder.encode(['address', 'uint256'], [currency.address, 1]);
      await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [data])).to.not.be.reverted;

      const followModuleAddress = await lensHub.getFollowModule(FIRST_PROFILE_ID);
      const followModule = FeeFollowModule__factory.connect(followModuleAddress, user);
      expect(await followModule.isFollowing(FIRST_PROFILE_ID, userThreeAddress, 0)).to.be.false;
      expect(
        await accessControl.isFollowing(userThreeAddress, FIRST_PROFILE_ID, 0, [])
      ).to.be.false;
    });

    it('isFollowing should return true if user is the owner of the profile', async function () {
      expect(await lensHub.ownerOf(FIRST_PROFILE_ID)).to.be.eq(userAddress);
      expect(await accessControl.isFollowing(userAddress, FIRST_PROFILE_ID, 0, [])).to.be.true;
    });
  });

  context('Has Collected', function () {
    before(async function () {
      await expect(
        lensHub.connect(governance).whitelistCollectModule(freeCollectModule.address, true)
      ).to.not.be.reverted;
    });

    beforeEach(async function () {
      const tx = lensHub.connect(user).post({
        profileId: FIRST_PROFILE_ID,
        contentURI: MOCK_URI,
        collectModule: freeCollectModule.address,
        collectModuleInitData: abiCoder.encode(['bool'], [false]),
        referenceModule: ZERO_ADDRESS,
        referenceModuleInitData: [],
      });
      const receipt = await waitForTx(tx);
      expect(receipt.logs.length).to.eq(1);
      matchEvent(receipt, 'PostCreated', [
        FIRST_PROFILE_ID,
        1,
        MOCK_URI,
        freeCollectModule.address,
        abiCoder.encode(['bool'], [false]),
        ZERO_ADDRESS,
        [],
        await getTimestamp(),
      ]);
    });

    it('hasCollected should return true if user holds the CollectNFT of publication', async function () {
      await lensHub.connect(userTwo).collect(FIRST_PROFILE_ID, 1, []);
      const collectNFTAddress = await lensHub.getCollectNFT(FIRST_PROFILE_ID, 1);
      const collectNFT = CollectNFT__factory.connect(collectNFTAddress, user);
      expect(await collectNFT.balanceOf(userTwoAddress)).is.gt(0);

      expect(
        await accessControl.hasCollected(userTwoAddress, FIRST_PROFILE_ID, 1, 0, [])
      ).to.be.true;
    });

    it('hasCollected should return false if user does not hold the CollectNFT of publication', async function () {
      await lensHub.connect(userTwo).collect(FIRST_PROFILE_ID, 1, []);
      const collectNFTAddress = await lensHub.getCollectNFT(FIRST_PROFILE_ID, 1);
      const collectNFT = CollectNFT__factory.connect(collectNFTAddress, user);
      expect(await collectNFT.balanceOf(userThreeAddress)).is.eq(0);

      expect(
        await accessControl.hasCollected(userThreeAddress, FIRST_PROFILE_ID, 1, 0, [])
      ).to.be.false;
    });
  });
});
