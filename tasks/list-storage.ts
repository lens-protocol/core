import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';

task('list-storage', '').setAction(async ({}, hre) => {
  const ethers = hre.ethers;
  const addr = '0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d';
  for (let i = 0; i < 100; ++i) {
    const storageSlot = await ethers.provider.getStorageAt(addr, i);
    console.log(`Hub proxy storage at slot ${i}: ${storageSlot}`);
  }
});
