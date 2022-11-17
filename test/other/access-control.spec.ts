import hre, { ethers } from 'hardhat';
import fs from 'fs';
import { expect } from 'chai';
import {
  FollowNFT__factory,
  CollectNFT__factory,
  AccessControl__factory,
  AccessControlV2__factory,
  FeeFollowModule__factory,
  TransparentUpgradeableProxy__factory,
  LensHub__factory,
  MockProfileCreationProxy__factory,
  ModuleGlobals__factory,
  FreeCollectModule__factory,
} from '../../typechain-types';
import { MAX_UINT256, ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import { findEvent, getTimestamp, matchEvent, waitForTx } from '../helpers/utils';
import {
  deployer,
  freeCollectModule as freeCollectModuleImported,
  FIRST_PROFILE_ID,
  governance as governanceImported,
  lensHub as lensHubImported,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  MOCK_URI,
  moduleGlobals as moduleGlobalsImported,
  user,
  userAddress,
  userTwo,
  userTwoAddress,
  userThreeAddress,
  abiCoder,
  feeFollowModule as feeFollowModuleImported,
  currency,
} from '../__setup.spec';
import { formatEther } from 'ethers/lib/utils';

const fork = process.env.FORK;

/**
 * @dev Some of these tests may be redundant, but are still present to ensure an isolated environment,
 * in particular if other test files are changed.
 */
makeSuiteCleanRoom('AccessControlV2', function () {
  let accessControl, accessControlImpl, accessControlV2Impl, accessControlProxy;
  let lensHub, mockProfileCreationProxy, feeFollowModule, moduleGlobals, freeCollectModule;
  let profileId = FIRST_PROFILE_ID;
  let governance;

  before(async function () {
    if (fork) {
      console.log(
        'BALANCE:',
        formatEther(await ethers.provider.getBalance(await deployer.getAddress()))
      );
      await ethers.provider.send('hardhat_setBalance', [
        await deployer.getAddress(),
        '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
      ]);
      const addresses = JSON.parse(fs.readFileSync('addresses.json', 'utf-8'));
      accessControl = AccessControlV2__factory.connect(addresses['accessControl proxy'], user);
      lensHub = LensHub__factory.connect(addresses['lensHub'], deployer);
      mockProfileCreationProxy = MockProfileCreationProxy__factory.connect(
        addresses['MockProfileCreationProxy'],
        deployer
      );
      feeFollowModule = FeeFollowModule__factory.connect(addresses['FeeFollowModule'], deployer);
      moduleGlobals = ModuleGlobals__factory.connect(addresses['ModuleGlobals'], deployer);
      freeCollectModule = FreeCollectModule__factory.connect(
        addresses['FreeCollectModule'],
        deployer
      );
      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [await lensHub.getGovernance()],
      });
      governance = await ethers.getSigner(await lensHub.getGovernance());
    } else {
      lensHub = lensHubImported;
      feeFollowModule = feeFollowModuleImported;
      moduleGlobals = moduleGlobalsImported;
      freeCollectModule = freeCollectModuleImported;
      governance = governanceImported;
      accessControlImpl = await new AccessControl__factory(deployer).deploy(lensHub.address);

      const data = accessControlImpl.interface.encodeFunctionData('initialize', []);

      accessControlProxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
        accessControlImpl.address,
        await deployer.getAddress(),
        data
      );

      accessControlV2Impl = await new AccessControlV2__factory(deployer).deploy(lensHub.address);

      await expect(accessControlProxy.upgradeToAndCall(accessControlV2Impl.address, data)).to.not.be
        .reverted;

      accessControl = AccessControlV2__factory.connect(accessControlProxy.address, user);
      await expect(accessControl.initialize()).to.be.revertedWith(ERRORS.INITIALIZED);
    }
  });

  beforeEach(async function () {
    const receipt = await waitForTx(
      fork
        ? mockProfileCreationProxy.proxyCreateProfile({
            to: userAddress,
            handle: 'mocktest' + (Math.random() * 100000000000000000).toFixed(0), //MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        : lensHub.createProfile({
            to: userAddress,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
    );

    expect(receipt.logs.length).to.eq(2, `Expected 2 events, got ${receipt.logs.length}`);

    if (fork) {
      const event = findEvent(receipt, 'ProfileCreated');
      profileId = event.args.profileId;
    } else {
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
    }
  });

  context('Has Access', function () {
    it('hasAccess should return true if user owns the profile', async function () {
      expect(await lensHub.ownerOf(profileId)).to.be.eq(userAddress);
      expect(await accessControl.hasAccess(userAddress, profileId, [])).to.be.true;
    });

    it('hasAccess should return false if user does not own the profile', async function () {
      expect(await lensHub.ownerOf(profileId)).to.not.be.eq(userTwoAddress);
      expect(await accessControl.hasAccess(userTwoAddress, profileId, [])).to.be.false;
    });
  });

  context('Is Following', function () {
    before(async function () {
      await lensHub.connect(governance).whitelistFollowModule(feeFollowModule.address, true);

      expect(await lensHub.isFollowModuleWhitelisted(feeFollowModule.address)).to.be.true;

      await moduleGlobals.connect(governance).whitelistCurrency(currency.address, true);

      expect(await moduleGlobals.isCurrencyWhitelisted(currency.address)).to.be.true;
    });

    it('isFollowing should return true if user follows the profile (without follow module, by holding a followNFT)', async function () {
      await lensHub.connect(userTwo).follow([profileId], [[]]);
      const followNFTAddress = await lensHub.getFollowNFT(profileId);
      const followNFT = FollowNFT__factory.connect(followNFTAddress, user);
      expect(await followNFT.balanceOf(userTwoAddress)).is.gt(0);

      expect(await accessControl.isFollowing(userTwoAddress, profileId, 0, [])).to.be.true;
    });

    it('isFollowing should return false if user does not follow the profile (without follow module, not holding a followNFT)', async function () {
      await lensHub.connect(userTwo).follow([profileId], [[]]);
      const followNFTAddress = await lensHub.getFollowNFT(profileId);
      const followNFT = FollowNFT__factory.connect(followNFTAddress, user);
      expect(await followNFT.balanceOf(userThreeAddress)).is.eq(0);
      expect(await accessControl.isFollowing(userThreeAddress, profileId, 0, [])).to.be.false;
    });

    it('isFollowing should return true if user follows the profile (with followModule, querying it)', async function () {
      const followModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address'],
        [1, currency.address, userAddress]
      );
      await lensHub
        .connect(user)
        .setFollowModule(profileId, feeFollowModule.address, followModuleInitData);
      await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
      await expect(
        currency.connect(userTwo).approve(feeFollowModule.address, MAX_UINT256)
      ).to.not.be.reverted;
      const data = abiCoder.encode(['address', 'uint256'], [currency.address, 1]);
      await expect(lensHub.connect(userTwo).follow([profileId], [data])).to.not.be.reverted;
      const followModuleAddress = await lensHub.getFollowModule(profileId);
      const followModule = FeeFollowModule__factory.connect(followModuleAddress, user);
      expect(await followModule.isFollowing(profileId, userTwoAddress, 0)).to.be.true;
      expect(await accessControl.isFollowing(userTwoAddress, profileId, 0, [])).to.be.true;
    });

    it('isFollowing should return false if user doesnt follow the profile (with followModule, querying it)', async function () {
      const followModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address'],
        [1, currency.address, userAddress]
      );
      await lensHub
        .connect(user)
        .setFollowModule(profileId, feeFollowModule.address, followModuleInitData);

      await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
      await expect(
        currency.connect(userTwo).approve(feeFollowModule.address, MAX_UINT256)
      ).to.not.be.reverted;
      const data = abiCoder.encode(['address', 'uint256'], [currency.address, 1]);
      await expect(lensHub.connect(userTwo).follow([profileId], [data])).to.not.be.reverted;

      const followModuleAddress = await lensHub.getFollowModule(profileId);
      const followModule = FeeFollowModule__factory.connect(followModuleAddress, user);
      expect(await followModule.isFollowing(profileId, userThreeAddress, 0)).to.be.false;
      expect(await accessControl.isFollowing(userThreeAddress, profileId, 0, [])).to.be.false;
    });

    it('isFollowing should return true if user is the owner of the profile', async function () {
      expect(await lensHub.ownerOf(profileId)).to.be.eq(userAddress);
      expect(await accessControl.isFollowing(userAddress, profileId, 0, [])).to.be.true;
    });
  });

  context('Has Collected', function () {
    before(async function () {
      await lensHub.connect(governance).whitelistCollectModule(freeCollectModule.address, true);
    });

    beforeEach(async function () {
      const tx = lensHub.connect(user).post({
        profileId: profileId,
        contentURI: MOCK_URI,
        collectModule: freeCollectModule.address,
        collectModuleInitData: abiCoder.encode(['bool'], [false]),
        referenceModule: ZERO_ADDRESS,
        referenceModuleInitData: [],
      });
      const receipt = await waitForTx(tx);
      expect(receipt.logs.length).to.eq(1);
      matchEvent(receipt, 'PostCreated', [
        profileId,
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
      await lensHub.connect(userTwo).collect(profileId, 1, []);
      const collectNFTAddress = await lensHub.getCollectNFT(profileId, 1);
      const collectNFT = CollectNFT__factory.connect(collectNFTAddress, user);
      expect(await collectNFT.balanceOf(userTwoAddress)).is.gt(0);

      expect(await accessControl.hasCollected(userTwoAddress, profileId, 1, 0, [])).to.be.true;
    });

    it('hasCollected should return false if user does not hold the CollectNFT of publication', async function () {
      await lensHub.connect(userTwo).collect(profileId, 1, []);
      const collectNFTAddress = await lensHub.getCollectNFT(profileId, 1);
      const collectNFT = CollectNFT__factory.connect(collectNFTAddress, user);
      expect(await collectNFT.balanceOf(userThreeAddress)).is.eq(0);

      expect(await accessControl.hasCollected(userThreeAddress, profileId, 1, 0, [])).to.be.false;
    });
  });
});
