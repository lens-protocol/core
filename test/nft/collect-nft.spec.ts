import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { CollectNFT, CollectNFT__factory } from '../../typechain-types';
import { ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import {
  freeCollectModule,
  FIRST_PROFILE_ID,
  governance,
  lensHub,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  MOCK_URI,
  user,
  userAddress,
  userTwo,
  abiCoder,
  userTwoAddress,
} from '../__setup.spec';

makeSuiteCleanRoom('Collect NFT', function () {
  let collectNFT: CollectNFT;
  beforeEach(async function () {
    await expect(
      lensHub.connect(governance).whitelistCollectModule(freeCollectModule.address, true)
    ).to.not.be.reverted;
    await expect(
      lensHub.createProfile({
        to: userAddress,
        handle: MOCK_PROFILE_HANDLE,
        imageURI: MOCK_PROFILE_URI,
        followModule: ZERO_ADDRESS,
        followModuleInitData: [],
        followNFTURI: MOCK_FOLLOW_NFT_URI,
      })
    ).to.not.be.reverted;
    await expect(
      lensHub.post({
        profileId: FIRST_PROFILE_ID,
        contentURI: MOCK_URI,
        collectModule: freeCollectModule.address,
        collectModuleInitData: abiCoder.encode(['bool'], [true]),
        referenceModule: ZERO_ADDRESS,
        referenceModuleInitData: [],
      })
    ).to.not.be.reverted;
    await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
    await expect(lensHub.collect(FIRST_PROFILE_ID, 1, [])).to.not.be.reverted;
    collectNFT = CollectNFT__factory.connect(
      await lensHub.getCollectNFT(FIRST_PROFILE_ID, 1),
      user
    );
  });

  context('Negatives', function () {
    it('User should fail to reinitialize the collect NFT', async function () {
      await expect(collectNFT.initialize(FIRST_PROFILE_ID, 1, 'name', 'symbol')).to.be.revertedWith(
        ERRORS.INITIALIZED
      );
    });

    it('User should fail to mint on the collect NFT', async function () {
      await expect(collectNFT.mint(userAddress)).to.be.revertedWith(ERRORS.NOT_HUB);
    });

    it("UserTwo should fail to burn user's collect NFT", async function () {
      await expect(collectNFT.connect(userTwo).burn(1)).to.be.revertedWith(
        ERRORS.NOT_OWNER_OR_APPROVED
      );
    });

    it('User should fail to get the URI for a token that does not exist', async function () {
      await expect(collectNFT.tokenURI(2)).to.be.revertedWith(ERRORS.TOKEN_DOES_NOT_EXIST);
    });

    it('User should fail to change the royalty percentage if he is not the owner of the publication', async function () {
      await expect(collectNFT.connect(userTwo).setRoyalty(100)).to.be.revertedWith(
        ERRORS.NOT_PROFILE_OWNER
      );
    });

    it('User should fail to change the royalty percentage if the value passed exceeds the royalty basis points', async function () {
      const royaltyBasisPoints = 10000;
      const newRoyalty = royaltyBasisPoints + 1;
      expect(newRoyalty).to.be.greaterThan(royaltyBasisPoints);
      await expect(collectNFT.setRoyalty(newRoyalty)).to.be.revertedWith(ERRORS.INVALID_PARAMETER);
    });
  });

  context('Scenarios', function () {
    it('Collect NFT URI should be valid', async function () {
      expect(await collectNFT.tokenURI(1)).to.eq(MOCK_URI);
    });

    it('Collect NFT source publication pointer should be accurate', async function () {
      const pointer = await collectNFT.getSourcePublicationPointer();
      expect(pointer[0]).to.eq(FIRST_PROFILE_ID);
      expect(pointer[1]).to.eq(1);
    });

    it('User should burn their collect NFT', async function () {
      await expect(collectNFT.burn(1)).to.not.be.reverted;
    });

    it('Default royalties are set to 10%', async function () {
      const royaltyInfo = await collectNFT.royaltyInfo(1, 6900);
      expect(royaltyInfo[0]).to.eq(userAddress);
      expect(royaltyInfo[1]).to.eq(BigNumber.from(690));
    });

    it('User should be able to change the royalties if owns the profile and passes a valid royalty percentage in basis points', async function () {
      await expect(collectNFT.setRoyalty(5000)).to.not.be.reverted;
      const royaltyInfo = await collectNFT.royaltyInfo(1, 3000);
      expect(royaltyInfo[0]).to.eq(userAddress);
      expect(royaltyInfo[1]).to.eq(BigNumber.from(1500));
    });

    it('User should be able to get the royalty info even over a token that does not exist yet', async function () {
      const unexistentTokenId = 69;
      await expect(collectNFT.tokenURI(unexistentTokenId)).to.be.revertedWith(
        ERRORS.TOKEN_DOES_NOT_EXIST
      );
      const royaltyInfo = await collectNFT.royaltyInfo(unexistentTokenId, 3000);
      expect(royaltyInfo[0]).to.eq(userAddress);
      expect(royaltyInfo[1]).to.eq(BigNumber.from(300));
    });

    it('Publication owner should be able to remove royalties by setting them as zero', async function () {
      await expect(collectNFT.setRoyalty(0)).to.not.be.reverted;
      const royaltyInfo = await collectNFT.royaltyInfo(1, 3000);
      expect(royaltyInfo[0]).to.eq(userAddress);
      expect(royaltyInfo[1]).to.eq(BigNumber.from(0));
    });

    it('If the profile authoring the publication is transferred the royalty info now returns the new owner as recipient', async function () {
      let royaltyInfo = await collectNFT.royaltyInfo(1, 69);
      expect(royaltyInfo[0]).to.eq(userAddress);
      await expect(
        lensHub.transferFrom(userAddress, userTwoAddress, FIRST_PROFILE_ID)
      ).to.not.be.reverted;
      royaltyInfo = await collectNFT.royaltyInfo(1, 69);
      expect(royaltyInfo[0]).to.eq(userTwoAddress);
    });
  });
});
