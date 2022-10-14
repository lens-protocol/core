import '@nomiclabs/hardhat-ethers';
import { formatEther } from 'ethers/lib/utils';
import fs from 'fs';
import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TransparentUpgradeableProxy__factory, ProfileAccess__factory } from '../typechain-types';
import { deployWithVerify } from './helpers/utils';

const LENS_HUB_SANDBOX = '0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5';
const LENS_HUB_MUMBAI = '0x60Ae865ee4C725cd04353b5AAb364553f56ceF82';
const LENS_HUB_POLYGON = '0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d';

export let runtimeHRE: HardhatRuntimeEnvironment;

task('deploy-profile-access', 'deploys the Profile Access contract with explorer verification')
  .addOptionalParam('lensHubAddress')
  .setAction(async ({ lensHubAddress }, hre) => {
    // Note that the use of these signers is a placeholder and is not meant to be used in
    // production.
    runtimeHRE = hre;
    const ethers = hre.ethers;
    const accounts = await ethers.getSigners();
    const deployer = accounts[0];
    const governance = accounts[1];
    const proxyAdminAddress = deployer.address;

    // Setting Lens Hub address if left undefined
    if (!lensHubAddress)
      switch (hre.network.name) {
        case 'matic':
          lensHubAddress = LENS_HUB_POLYGON;
          break;
        case 'mumbai':
          lensHubAddress = LENS_HUB_MUMBAI;
          break;
        case 'sandbox':
          lensHubAddress = LENS_HUB_SANDBOX;
          break;
        default:
          console.log(
            '\n\tUnsupported network:',
            hre.network.name,
            '\n\t === HALTING DEPLOYMENT ==='
          );
          process.exit();
      }

    console.log(`\n\tNetwork: ${hre.network.name}`);
    console.log(`\n\tDeployer:`, deployer.address);
    console.log(
      `\n\tDeployer balance:`,
      formatEther(await ethers.provider.getBalance(deployer.address))
    );
    console.log(`\n\tGovernance:`, governance.address);
    console.log(`\n\tproxyAdminAddress:`, proxyAdminAddress);
    console.log(`\n\tlensHubAddress:`, lensHubAddress);

    console.log('\n\t-- Deploying Profile Access Implementation --');

    const profileAccessImpl = await deployWithVerify(
      new ProfileAccess__factory(deployer).deploy(lensHubAddress),
      [lensHubAddress],
      'contracts/misc/ProfileAccess.sol:ProfileAccess'
    );

    const data = profileAccessImpl.interface.encodeFunctionData('initialize', []);

    console.log('\n\t-- Deploying Profile Access Proxy --');
    const proxy = await deployWithVerify(
      new TransparentUpgradeableProxy__factory(deployer).deploy(
        profileAccessImpl.address,
        proxyAdminAddress,
        data
      ),
      [profileAccessImpl.address, deployer.address, data],
      'contracts/upgradeability/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy'
    );

    // Connect the profileAccess proxy to the ProfileAccess factory and the governance for ease of use.
    const profileAccess = ProfileAccess__factory.connect(proxy.address, governance);

    // Save and log the addresses
    const addrs = {
      'profileAccess proxy': profileAccess.address,
      'profileAccess impl': profileAccessImpl.address,
    };
    const json = JSON.stringify(addrs, null, 2);
    console.log(json);

    fs.writeFileSync('addresses.json', json, 'utf-8');
  });
