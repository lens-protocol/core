import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import {
  MockLensHubV2BadRevision__factory,
  MockLensHubV2__factory,
  MockAccessControlV2BadRevision__factory,
  AccessControlV2__factory,
  AccessControl__factory,
  TransparentUpgradeableProxy__factory,
} from '../../typechain-types';
import { ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import {
  abiCoder,
  deployer,
  deployerAddress,
  FIRST_PROFILE_ID,
  lensHub,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  user,
  userAddress,
  userTwoAddress,
} from '../__setup.spec';

makeSuiteCleanRoom('Upgradeability', function () {
  const valueToSet = 123;

  it('Should fail to initialize an implementation with the same revision', async function () {
    const newImpl = await new MockLensHubV2BadRevision__factory(deployer).deploy();
    const proxyHub = TransparentUpgradeableProxy__factory.connect(lensHub.address, deployer);
    const hub = MockLensHubV2BadRevision__factory.connect(proxyHub.address, user);
    await expect(proxyHub.upgradeTo(newImpl.address)).to.not.be.reverted;
    await expect(hub.initialize(valueToSet)).to.be.revertedWith(ERRORS.INITIALIZED);
  });

  // The LensHub contract's last storage variable by default is at the 23nd slot (index 22) and contains the emergency admin
  // We're going to validate the first 23 slots and the 24rd slot before and after the change
  it("Should upgrade and set a new variable's value, previous storage is unchanged, new value is accurate", async function () {
    const newImpl = await new MockLensHubV2__factory(deployer).deploy();
    const proxyHub = TransparentUpgradeableProxy__factory.connect(lensHub.address, deployer);

    const prevStorage: string[] = [];
    for (let i = 0; i < 24; i++) {
      const valueAt = await ethers.provider.getStorageAt(proxyHub.address, i);
      prevStorage.push(valueAt);
    }

    const prevNextSlot = await ethers.provider.getStorageAt(proxyHub.address, 24);
    const formattedZero = abiCoder.encode(['uint256'], [0]);
    expect(prevNextSlot).to.eq(formattedZero);

    await proxyHub.upgradeTo(newImpl.address);
    await expect(
      MockLensHubV2__factory.connect(proxyHub.address, user).setAdditionalValue(valueToSet)
    ).to.not.be.reverted;

    for (let i = 0; i < 24; i++) {
      const valueAt = await ethers.provider.getStorageAt(proxyHub.address, i);
      expect(valueAt).to.eq(prevStorage[i]);
    }

    const newNextSlot = await ethers.provider.getStorageAt(proxyHub.address, 24);
    const formattedValue = abiCoder.encode(['uint256'], [valueToSet]);
    expect(newNextSlot).to.eq(formattedValue);
  });

  context('AccessControl Upgradability', function () {
    let accessControl, accessControlImpl, accessControlProxy;
    before(async function () {
      accessControlImpl = await new AccessControl__factory(deployer).deploy(lensHub.address);

      const data = accessControlImpl.interface.encodeFunctionData('initialize', []);

      accessControlProxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
        accessControlImpl.address,
        deployerAddress,
        data
      );

      accessControl = AccessControl__factory.connect(accessControlProxy.address, user);
    });

    beforeEach(async function () {
      await lensHub.createProfile({
        to: userAddress,
        handle: MOCK_PROFILE_HANDLE,
        imageURI: MOCK_PROFILE_URI,
        followModule: ZERO_ADDRESS,
        followModuleInitData: [],
        followNFTURI: MOCK_FOLLOW_NFT_URI,
      });
    });

    it('AccessControl upgrade should fail to initialize an implementation with the same revision', async function () {
      const newImpl = await new MockAccessControlV2BadRevision__factory(deployer).deploy(
        lensHub.address
      );
      await expect(accessControlProxy.upgradeTo(newImpl.address)).to.not.be.reverted;
      await expect(accessControl.initialize()).to.be.revertedWith(ERRORS.INITIALIZED);
    });

    it('AccessControl upgrade should behave as expected before and after being upgraded', async function () {
      expect(await lensHub.ownerOf(FIRST_PROFILE_ID)).to.be.eq(userAddress);
      expect(await accessControl.hasAccess(userAddress, FIRST_PROFILE_ID, [])).to.be.true;
      expect(await accessControl.hasAccess(userTwoAddress, FIRST_PROFILE_ID, [])).to.be.false;

      const newImpl = await new AccessControlV2__factory(deployer).deploy(lensHub.address);
      const data = accessControlImpl.interface.encodeFunctionData('initialize', []);
      await expect(accessControlProxy.upgradeToAndCall(newImpl.address, data)).to.not.be.reverted;
      await expect(accessControl.initialize()).to.be.revertedWith(ERRORS.INITIALIZED);

      expect(await lensHub.ownerOf(FIRST_PROFILE_ID)).to.be.eq(userAddress);
      expect(await accessControl.hasAccess(userAddress, FIRST_PROFILE_ID, [])).to.be.true;
      expect(await accessControl.hasAccess(userTwoAddress, FIRST_PROFILE_ID, [])).to.be.false;

      // See access-control.spec.ts tests for thorough upgrade testing.
    });
  });
});
