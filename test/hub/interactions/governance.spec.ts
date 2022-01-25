import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ERRORS } from '../../helpers/errors';
import { governance, lensHub, makeSuiteCleanRoom, userAddress } from '../../__setup.spec';

makeSuiteCleanRoom('Governance Functions', function () {
  context('Negatives', function () {
    it('User should not be able to call governance functions', async function () {
      await expect(lensHub.setGovernance(userAddress)).to.be.revertedWith(ERRORS.NOT_GOVERNANCE);
      await expect(lensHub.whitelistFollowModule(userAddress, true)).to.be.revertedWith(
        ERRORS.NOT_GOVERNANCE
      );
      await expect(lensHub.whitelistReferenceModule(userAddress, true)).to.be.revertedWith(
        ERRORS.NOT_GOVERNANCE
      );
      await expect(lensHub.whitelistCollectModule(userAddress, true)).to.be.revertedWith(
        ERRORS.NOT_GOVERNANCE
      );
    });
  });

  context('Scenarios', function () {
    it('Governance should successfully whitelist and unwhitelist modules', async function () {
      await expect(
        lensHub.connect(governance).whitelistFollowModule(userAddress, true)
      ).to.not.be.reverted;
      await expect(
        lensHub.connect(governance).whitelistReferenceModule(userAddress, true)
      ).to.not.be.reverted;
      await expect(
        lensHub.connect(governance).whitelistCollectModule(userAddress, true)
      ).to.not.be.reverted;
      expect(await lensHub.isFollowModuleWhitelisted(userAddress)).to.eq(true);
      expect(await lensHub.isReferenceModuleWhitelisted(userAddress)).to.eq(true);
      expect(await lensHub.isCollectModuleWhitelisted(userAddress)).to.eq(true);

      await expect(
        lensHub.connect(governance).whitelistFollowModule(userAddress, false)
      ).to.not.be.reverted;
      await expect(
        lensHub.connect(governance).whitelistReferenceModule(userAddress, false)
      ).to.not.be.reverted;
      await expect(
        lensHub.connect(governance).whitelistCollectModule(userAddress, false)
      ).to.not.be.reverted;
      expect(await lensHub.isFollowModuleWhitelisted(userAddress)).to.eq(false);
      expect(await lensHub.isReferenceModuleWhitelisted(userAddress)).to.eq(false);
      expect(await lensHub.isCollectModuleWhitelisted(userAddress)).to.eq(false);
    });

    it('Governance should successfully change the governance address', async function () {
      await expect(lensHub.connect(governance).setGovernance(userAddress)).to.not.be.reverted;
    });
  });
});
