import '@nomiclabs/hardhat-ethers';
import { BigNumber } from 'ethers';
import { formatEther } from 'ethers/lib/utils';
import fs from 'fs';
import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TransparentUpgradeableProxy__factory, AccessControlV2__factory } from '../typechain-types';
import { deployContract, deployWithVerify } from './helpers/utils';

const LENS_HUB_SANDBOX = '0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5';
const LENS_HUB_MUMBAI = '0x60Ae865ee4C725cd04353b5AAb364553f56ceF82';
const LENS_HUB_POLYGON = '0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d';

export let runtimeHRE: HardhatRuntimeEnvironment;

task('deploy-access-control', 'deploys the Access Control contract with explorer verification')
  .addOptionalParam('lenshubaddress', 'Address of the LensHub proxy')
  .addOptionalParam('proxyadmin', 'Address of the Access Control proxy admin to set')
  .addOptionalParam('networkfork', 'Network to mimic on local fork')
  .addFlag('broadcast', 'Submit transactions on-chain (will run a dry-run without this flag)')
  .addFlag('onlyimpl', 'Deploy only the implementation, without proxy (for upgrades)')
  .addFlag('upgrade', 'Perform an upgrade instead of deploying from scratch')
  .setAction(
    async ({ lenshubaddress, proxyadmin, networkfork, broadcast, onlyimpl, upgrade }, hre) => {
      // Note that the use of these signers is a placeholder and is not meant to be used in
      // production.
      runtimeHRE = hre;
      const ethers = hre.ethers;
      const accounts = await ethers.getSigners();
      const deployer = accounts[0];
      // const governance = accounts[1];
      const proxyAdminAddress = proxyadmin ?? deployer.address;

      // Setting Lens Hub address if left undefined
      if (!lenshubaddress)
        switch (hre.network.name) {
          case 'matic':
            lenshubaddress = LENS_HUB_POLYGON;
            break;
          case 'mumbai':
            lenshubaddress = LENS_HUB_MUMBAI;
            break;
          case 'sandbox':
            lenshubaddress = LENS_HUB_SANDBOX;
            break;
          case 'local':
            switch (networkfork) {
              case 'matic':
                lenshubaddress = LENS_HUB_POLYGON;
                break;
              case 'mumbai':
                lenshubaddress = LENS_HUB_MUMBAI;
                break;
              case 'sandbox':
                lenshubaddress = LENS_HUB_SANDBOX;
                break;
              default:
                console.log(
                  '\n\tWhen testing on local fork you need to specify networkFork argument (matic/mumbai/sandbox)',
                  '\n\t === HALTING DEPLOYMENT ==='
                );
                process.exit();
            }
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
      console.log(`\n\tproxyAdminAddress:`, proxyAdminAddress);
      console.log(`\n\tlenshubaddress:`, lenshubaddress);

      let proxyAddress;
      let addresses;
      if (!upgrade && !onlyimpl) {
        console.log(`\n\n\t Deployment mode: Proxy + Implementation`);
      } else {
        try {
          addresses = JSON.parse(fs.readFileSync('addresses.json', 'utf-8'));
        } catch (err) {
          console.error(
            '\nERROR: No addresses.json found. It is required to fetch existing Proxy address'
          );
          process.exit();
        }
        proxyAddress = addresses['accessControl proxy'];
        if (proxyAddress == undefined || proxyAddress.length != 42) {
          console.error('\nERROR: Proxy address not found or invalid');
          process.exit();
        }
        if (
          (await ethers.provider.getCode(proxyAddress)).length <= 2 ||
          (await ethers.provider.getCode(proxyAddress)) == '0x'
        ) {
          console.error('\nERROR Proxy address is not a contract (doesnt have code)');
          process.exit();
        }
        console.log('\n\tAccess Control Proxy found:', proxyAddress);
      }

      if (broadcast) {
        console.log('\n\t-- Deploying Access Control Implementation --');
        const accessControlImpl =
          hre.network.name == 'local'
            ? await deployContract(new AccessControlV2__factory(deployer).deploy(lenshubaddress))
            : await deployWithVerify(
                new AccessControlV2__factory(deployer).deploy(lenshubaddress),
                [lenshubaddress],
                'contracts/misc/AccessControlV2.sol:AccessControlV2'
              );

        const data = accessControlImpl.interface.encodeFunctionData('initialize', []);

        let proxy;
        if (!upgrade && !onlyimpl) {
          console.log('\n\t-- Deploying Access Control Proxy --');
          proxy =
            hre.network.name == 'local'
              ? await deployContract(
                  new TransparentUpgradeableProxy__factory(deployer).deploy(
                    accessControlImpl.address,
                    proxyAdminAddress,
                    data
                  )
                )
              : await deployWithVerify(
                  new TransparentUpgradeableProxy__factory(deployer).deploy(
                    accessControlImpl.address,
                    proxyAdminAddress,
                    data
                  ),
                  [accessControlImpl.address, deployer.address, data],
                  'contracts/upgradeability/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy'
                );
        }

        const accessControl = AccessControlV2__factory.connect(
          proxy ? proxy.address : proxyAddress,
          deployer
        );

        // Save and log the addresses
        const addrs = addresses ?? {};
        addrs['accessControl proxy'] = accessControl.address;
        addrs['accessControl impl'] = accessControlImpl.address;
        const json = JSON.stringify(addrs, null, 2);
        console.log(json);

        fs.writeFileSync('addresses.json', json, 'utf-8');

        if (upgrade) {
          const currentAdminRaw = await ethers.provider.getStorageAt(
            proxyAddress,
            '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103'
          );

          const currentAdmin = '0x' + currentAdminRaw.slice(-40);

          if (currentAdmin.toLowerCase() != deployer.address.toLowerCase()) {
            console.log('\n\t-- Current Proxy Admin is different than deployer --');
            console.log('\tCurrent admin:', currentAdmin.toLowerCase());
            console.log('\tDeployer:', deployer.address.toLowerCase());
          }

          console.log('\n\t-- Trying to perform an upgrade (with the deployer) --');

          console.log(
            'Previous revision:',
            BigNumber.from(await ethers.provider.getStorageAt(accessControl.address, 0)).toString()
          );

          proxy = TransparentUpgradeableProxy__factory.connect(proxyAddress, deployer);
          const tx = await proxy.upgradeToAndCall(accessControlImpl.address, data);
          await tx.wait(3);

          console.log('\n\t Looks like the upgrade succeeded!');

          console.log(
            'Revision after upgrade:',
            BigNumber.from(await ethers.provider.getStorageAt(accessControl.address, 0)).toString()
          );
        }
      } else {
        console.log('\n--- To broadcast transactions on-chain: add --broadcast flag\n');
      }
    }
  );
