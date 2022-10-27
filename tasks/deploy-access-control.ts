import '@nomiclabs/hardhat-ethers';
import { formatEther } from 'ethers/lib/utils';
import fs from 'fs';
import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TransparentUpgradeableProxy__factory, AccessControl__factory } from '../typechain-types';
import { deployWithVerify } from './helpers/utils';

const LENS_HUB_SANDBOX = '0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5';
const LENS_HUB_MUMBAI = '0x60Ae865ee4C725cd04353b5AAb364553f56ceF82';
const LENS_HUB_POLYGON = '0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d';

export let runtimeHRE: HardhatRuntimeEnvironment;

task('deploy-access-control', 'deploys the Access Control contract with explorer verification')
  .addOptionalParam('lensHubAddress', 'Address of the LensHub proxy')
  .addFlag('broadcast', 'Submit transactions on-chain (will run a dry-run without this flag)')
  .setAction(async ({ lensHubAddress, broadcast }, hre) => {
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

    if (broadcast) {
      console.log('\n\t-- Deploying Access Control Implementation --');
      const accessControlImpl = await deployWithVerify(
        new AccessControl__factory(deployer).deploy(lensHubAddress),
        [lensHubAddress],
        'contracts/misc/AccessControl.sol:AccessControl'
      );

      const data = accessControlImpl.interface.encodeFunctionData('initialize', []);

      console.log('\n\t-- Deploying Access Control Proxy --');
      const proxy = await deployWithVerify(
        new TransparentUpgradeableProxy__factory(deployer).deploy(
          accessControlImpl.address,
          proxyAdminAddress,
          data
        ),
        [accessControlImpl.address, deployer.address, data],
        'contracts/upgradeability/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy'
      );

      // Connect the accessControl proxy to the AccessControl factory and the governance for ease of use.
      const accessControl = AccessControl__factory.connect(proxy.address, governance);

      // Save and log the addresses
      const addrs = {
        'accessControl proxy': accessControl.address,
        'accessControl impl': accessControlImpl.address,
      };
      const json = JSON.stringify(addrs, null, 2);
      console.log(json);

      fs.writeFileSync('addresses.json', json, 'utf-8');
    } else {
      console.log('\n--- To broadcast transactions on-chain: add --broadcast flag\n');
    }
  });
