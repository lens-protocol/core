import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ERRORS } from '../../helpers/errors';
import { governance, makeSuiteCleanRoom, userAddress, whitelist } from '../../__setup.spec';

makeSuiteCleanRoom('Governance Functions', function () {
  context('Negatives', function () {
    it('User should not be able to call governance functions', async function () {
      await expect(whitelist.setGovernance(userAddress)).to.be.revertedWith(ERRORS.NOT_GOVERNANCE);
      console.log(await whitelist._governance);
      await expect(whitelist.whitelistFollowModule(userAddress, true)).to.be.revertedWith(
        ERRORS.NOT_GOVERNANCE
      );
      await expect(whitelist.whitelistReferenceModule(userAddress, true)).to.be.revertedWith(
        ERRORS.NOT_GOVERNANCE
      );
      await expect(whitelist.whitelistCollectModule(userAddress, true)).to.be.revertedWith(
        ERRORS.NOT_GOVERNANCE
      );
    });
  });

  context('Scenarios', function () {
    it('Governance should successfully whitelist and unwhitelist modules', async function () {
      await expect(
        whitelist.connect(governance).whitelistFollowModule(userAddress, true)
      ).to.not.be.reverted;
      await expect(
        whitelist.connect(governance).whitelistReferenceModule(userAddress, true)
      ).to.not.be.reverted;
      await expect(
        whitelist.connect(governance).whitelistCollectModule(userAddress, true)
      ).to.not.be.reverted;
      expect(await whitelist.isFollowModuleWhitelisted(userAddress)).to.eq(true);
      expect(await whitelist.isReferenceModuleWhitelisted(userAddress)).to.eq(true);
      expect(await whitelist.isCollectModuleWhitelisted(userAddress)).to.eq(true);

      await expect(
        whitelist.connect(governance).whitelistFollowModule(userAddress, false)
      ).to.not.be.reverted;
      await expect(
        whitelist.connect(governance).whitelistReferenceModule(userAddress, false)
      ).to.not.be.reverted;
      await expect(
        whitelist.connect(governance).whitelistCollectModule(userAddress, false)
      ).to.not.be.reverted;
      expect(await whitelist.isFollowModuleWhitelisted(userAddress)).to.eq(false);
      expect(await whitelist.isReferenceModuleWhitelisted(userAddress)).to.eq(false);
      expect(await whitelist.isCollectModuleWhitelisted(userAddress)).to.eq(false);
    });

    it('Governance should successfully change the governance address', async function () {
      await expect(whitelist.connect(governance).setGovernance(userAddress)).to.not.be.reverted;
    });
  });
});
