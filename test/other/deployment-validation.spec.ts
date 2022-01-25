import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
  FeeFollowModule__factory,
  LensHub__factory,
  ModuleGlobals__factory,
  TimedFeeCollectModule__factory,
  TransparentUpgradeableProxy__factory,
} from '../../typechain-types';
import { ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import {
  BPS_MAX,
  deployer,
  deployerAddress,
  governanceAddress,
  hubLibs,
  lensHub,
  lensHubImpl,
  LENS_HUB_NFT_NAME,
  LENS_HUB_NFT_SYMBOL,
  makeSuiteCleanRoom,
  moduleGlobals,
  treasuryAddress,
  TREASURY_FEE_BPS,
  user,
  userAddress,
} from '../__setup.spec';

makeSuiteCleanRoom('deployment validation', () => {
  it('Deployer should not be able to initialize implementation due to address(this) check', async function () {
    await expect(
      lensHubImpl.initialize(LENS_HUB_NFT_NAME, LENS_HUB_NFT_SYMBOL, governanceAddress)
    ).to.be.revertedWith(ERRORS.CANNOT_INIT_IMPL);
  });

  it("User should fail to initialize lensHub proxy after it's already been initialized via the proxy constructor", async function () {
    // Initialization happens in __setup.spec.ts
    await expect(
      lensHub.connect(user).initialize('name', 'symbol', userAddress)
    ).to.be.revertedWith(ERRORS.INITIALIZED);
  });

  it('Deployer should deploy an LensHub implementation, a proxy, initialize it, and fail to initialize it again', async function () {
    const newImpl = await new LensHub__factory(hubLibs, deployer).deploy(
      ZERO_ADDRESS,
      ZERO_ADDRESS
    );

    let data = newImpl.interface.encodeFunctionData('initialize', [
      LENS_HUB_NFT_NAME,
      LENS_HUB_NFT_SYMBOL,
      governanceAddress,
    ]);

    const proxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
      newImpl.address,
      deployerAddress,
      data
    );

    await expect(
      LensHub__factory.connect(proxy.address, user).initialize('name', 'symbol', userAddress)
    ).to.be.revertedWith(ERRORS.INITIALIZED);
  });

  it('User should not be able to call admin-only functions on proxy (should fallback) since deployer is admin', async function () {
    const proxy = TransparentUpgradeableProxy__factory.connect(lensHub.address, user);
    await expect(proxy.upgradeTo(userAddress)).to.be.revertedWith(ERRORS.NO_SELECTOR);
    await expect(proxy.upgradeToAndCall(userAddress, [])).to.be.revertedWith(ERRORS.NO_SELECTOR);
  });

  it('Deployer should be able to call admin-only functions on proxy', async function () {
    const proxy = TransparentUpgradeableProxy__factory.connect(lensHub.address, deployer);
    const newImpl = await new LensHub__factory(hubLibs, deployer).deploy(
      ZERO_ADDRESS,
      ZERO_ADDRESS
    );
    await expect(proxy.upgradeTo(newImpl.address)).to.not.be.reverted;
  });

  it('Deployer should transfer admin to user, deployer should fail to call admin-only functions, user should call admin-only functions', async function () {
    const proxy = TransparentUpgradeableProxy__factory.connect(lensHub.address, deployer);

    await expect(proxy.changeAdmin(userAddress)).to.not.be.reverted;

    await expect(proxy.upgradeTo(userAddress)).to.be.revertedWith(ERRORS.NO_SELECTOR);
    await expect(proxy.upgradeToAndCall(userAddress, [])).to.be.revertedWith(ERRORS.NO_SELECTOR);

    const newImpl = await new LensHub__factory(hubLibs, deployer).deploy(
      ZERO_ADDRESS,
      ZERO_ADDRESS
    );

    await expect(proxy.connect(user).upgradeTo(newImpl.address)).to.not.be.reverted;
  });

  it('Should fail to deploy a fee collect module with zero address hub', async function () {
    await expect(
      new TimedFeeCollectModule__factory(deployer).deploy(ZERO_ADDRESS, moduleGlobals.address)
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy a fee collect module with zero address module globals', async function () {
    await expect(
      new TimedFeeCollectModule__factory(deployer).deploy(lensHub.address, ZERO_ADDRESS)
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy a fee follow module with zero address hub', async function () {
    await expect(
      new FeeFollowModule__factory(deployer).deploy(ZERO_ADDRESS, moduleGlobals.address)
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy a fee follow module with zero address module globals', async function () {
    await expect(
      new FeeFollowModule__factory(deployer).deploy(lensHub.address, ZERO_ADDRESS)
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy module globals with zero address governance', async function () {
    await expect(
      new ModuleGlobals__factory(deployer).deploy(ZERO_ADDRESS, treasuryAddress, TREASURY_FEE_BPS)
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy module globals with zero address treasury', async function () {
    await expect(
      new ModuleGlobals__factory(deployer).deploy(governanceAddress, ZERO_ADDRESS, TREASURY_FEE_BPS)
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy module globals with treausury fee > BPS_MAX / 2', async function () {
    await expect(
      new ModuleGlobals__factory(deployer).deploy(governanceAddress, treasuryAddress, 5001)
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy a fee module with treasury fee equal to or higher than maximum BPS', async function () {
    await expect(
      new ModuleGlobals__factory(deployer).deploy(ZERO_ADDRESS, treasuryAddress, BPS_MAX)
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);

    await expect(
      new ModuleGlobals__factory(deployer).deploy(ZERO_ADDRESS, treasuryAddress, BPS_MAX + 1)
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Validates LensHub name & symbol', async function () {
    const name = LENS_HUB_NFT_NAME;
    const symbol = await lensHub.symbol();

    expect(name).to.eq(LENS_HUB_NFT_NAME);
    expect(symbol).to.eq(LENS_HUB_NFT_SYMBOL);
  });
});
