import '@nomiclabs/hardhat-ethers';
import hre from 'hardhat';
import { expect } from 'chai';
import { BigNumber, BigNumberish } from 'ethers';
import { ethers } from 'hardhat';
import {
  MockLensHubV2BadRevision__factory,
  MockLensHubV2__factory,
  TransparentUpgradeableProxy__factory,
} from '../../typechain-types';
import { ERRORS } from '../helpers/errors';
import { abiCoder, deployer, lensHub, makeSuiteCleanRoom, user } from '../__setup.spec';

makeSuiteCleanRoom('Upgradeability', function () {
  const valueToSet = 123;
  const totalSlotsUsed = 25; // Slots 0-24 are used.

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

    let prevStorage: string[] = [];
    for (let i = 0; i < totalSlotsUsed; ++i) {
      const valueAt = await getStorageAt(proxyHub.address, i);
      prevStorage.push(valueAt);
    }
    let prevNextSlot = await getStorageAt(proxyHub.address, totalSlotsUsed);
    expect(prevNextSlot).to.eq(encodeUint(0));

    await proxyHub.upgradeTo(newImpl.address);
    await expect(
      MockLensHubV2__factory.connect(proxyHub.address, user).setAdditionalValue(valueToSet)
    ).to.not.be.reverted;

    console.log('1');
    for (let i = 0; i < totalSlotsUsed; ++i) {
      const valueAt = await getStorageAt(proxyHub.address, i);
      expect(valueAt).to.eq(prevStorage[i]);
    }

    const newNextSlot = await getStorageAt(proxyHub.address, totalSlotsUsed);

    expect(newNextSlot).to.eq(encodeUint(valueToSet));
  });

  async function getStorageAt(address: string, slot: number): Promise<any> {
    return await hre.network.provider.request({
      method: 'eth_getStorageAt',
      params: [address, abiCoder.encode(['uint256'], [slot])],
    });
  }

  function encodeUint(num: BigNumberish): string {
    return abiCoder.encode(['uint256'], [num]);
  }
});
