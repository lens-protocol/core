import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { keccak256, toUtf8Bytes } from 'ethers/lib/utils';
import { FollowNFT__factory } from '../../../typechain-types';
import { MAX_UINT256, ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import {
  cancelWithPermitForAll,
  getJsonMetadataFromBase64TokenUri,
  getSetFollowNFTURIWithSigParts,
  getSetProfileImageURIWithSigParts,
} from '../../helpers/utils';
import {
  FIRST_PROFILE_ID,
  lensHub,
  makeSuiteCleanRoom,
  MAX_PROFILE_IMAGE_URI_LENGTH,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  MOCK_URI,
  OTHER_MOCK_URI,
  testWallet,
  user,
  userAddress,
  userTwo,
  userTwoAddress,
} from '../../__setup.spec';

makeSuiteCleanRoom('Profile URI Functionality', function () {
  context('Generic', function () {
    beforeEach(async function () {
      await expect(
        lensHub.createProfile({
          to: userAddress,
          handle: MOCK_PROFILE_HANDLE,
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.not.be.reverted;
    });

    context('Negatives', function () {
      it('UserTwo should fail to set the profile URI on profile owned by user 1', async function () {
        await expect(
          lensHub.connect(userTwo).setProfileImageURI(FIRST_PROFILE_ID, MOCK_URI)
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER_OR_DISPATCHER);
      });

      it('UserTwo should fail to set the profile URI on profile owned by user 1', async function () {
        const profileURITooLong = MOCK_URI.repeat(500);
        expect(profileURITooLong.length).to.be.greaterThan(MAX_PROFILE_IMAGE_URI_LENGTH);
        await expect(
          lensHub.setProfileImageURI(FIRST_PROFILE_ID, profileURITooLong)
        ).to.be.revertedWith(ERRORS.INVALID_IMAGE_URI_LENGTH);
      });

      it('UserTwo should fail to change the follow NFT URI for profile one', async function () {
        await expect(
          lensHub.connect(userTwo).setFollowNFTURI(FIRST_PROFILE_ID, OTHER_MOCK_URI)
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER_OR_DISPATCHER);
      });
    });

    context('Scenarios', function () {
      it('User should have a custom picture tokenURI after setting the profile imageURI', async function () {
        await expect(lensHub.setProfileImageURI(FIRST_PROFILE_ID, MOCK_URI)).to.not.be.reverted;
        const tokenURI = await lensHub.tokenURI(FIRST_PROFILE_ID);
        const jsonMetadata = await getJsonMetadataFromBase64TokenUri(tokenURI);
        expect(jsonMetadata.name).to.eq(`@${MOCK_PROFILE_HANDLE}`);
        expect(jsonMetadata.description).to.eq(`@${MOCK_PROFILE_HANDLE} - Lens profile`);
        const expectedAttributes = [
          { trait_type: 'id', value: `#${FIRST_PROFILE_ID.toString()}` },
          { trait_type: 'followers', value: '0' },
          { trait_type: 'owner', value: userAddress.toLowerCase() },
          { trait_type: 'handle', value: `@${MOCK_PROFILE_HANDLE}` },
        ];
        expect(jsonMetadata.attributes).to.eql(expectedAttributes);
        expect(keccak256(toUtf8Bytes(tokenURI))).to.eq(
          '0xe1731460db6ce5fa9f3a9f2bd778a8af49e623dceb531df6b1a5c162b7c2d79a'
        );
      });

      it('Default image should be used when no imageURI set', async function () {
        await expect(lensHub.setProfileImageURI(FIRST_PROFILE_ID, '')).to.not.be.reverted;
        const tokenURI = await lensHub.tokenURI(FIRST_PROFILE_ID);
        const jsonMetadata = await getJsonMetadataFromBase64TokenUri(tokenURI);
        expect(jsonMetadata.name).to.eq(`@${MOCK_PROFILE_HANDLE}`);
        expect(jsonMetadata.description).to.eq(`@${MOCK_PROFILE_HANDLE} - Lens profile`);
        const expectedAttributes = [
          { trait_type: 'id', value: `#${FIRST_PROFILE_ID.toString()}` },
          { trait_type: 'followers', value: '0' },
          { trait_type: 'owner', value: userAddress.toLowerCase() },
          { trait_type: 'handle', value: `@${MOCK_PROFILE_HANDLE}` },
        ];
        expect(jsonMetadata.attributes).to.eql(expectedAttributes);
        expect(keccak256(toUtf8Bytes(tokenURI))).to.eq(
          '0xa21f2a3aa9300a248d3a7acd3f4ff309291653121df87ffe3be545fa1dbd65e5'
        );
      });

      it('Default image should be used when imageURI contains double-quotes', async function () {
        const imageURI =
          'https://ipfs.io/ipfs/QmbWqxBEKC3P8tqsKc98xmWNzrztRLMiMPL8wBuTGsMnR" <rect x="10" y="10" fill="red';
        await expect(lensHub.setProfileImageURI(FIRST_PROFILE_ID, imageURI)).to.not.be.reverted;
        const tokenURI = await lensHub.tokenURI(FIRST_PROFILE_ID);
        const jsonMetadata = await getJsonMetadataFromBase64TokenUri(tokenURI);
        expect(jsonMetadata.name).to.eq(`@${MOCK_PROFILE_HANDLE}`);
        expect(jsonMetadata.description).to.eq(`@${MOCK_PROFILE_HANDLE} - Lens profile`);
        const expectedAttributes = [
          { trait_type: 'id', value: `#${FIRST_PROFILE_ID.toString()}` },
          { trait_type: 'followers', value: '0' },
          { trait_type: 'owner', value: userAddress.toLowerCase() },
          { trait_type: 'handle', value: `@${MOCK_PROFILE_HANDLE}` },
        ];
        expect(jsonMetadata.attributes).to.eql(expectedAttributes);
        expect(keccak256(toUtf8Bytes(tokenURI))).to.eq(
          '0xa21f2a3aa9300a248d3a7acd3f4ff309291653121df87ffe3be545fa1dbd65e5'
        );
      });

      it('Should return the correct tokenURI after transfer', async function () {
        const tokenURIBeforeTransfer = await lensHub.tokenURI(FIRST_PROFILE_ID);
        const jsonMetadataBeforeTransfer = await getJsonMetadataFromBase64TokenUri(
          tokenURIBeforeTransfer
        );
        expect(jsonMetadataBeforeTransfer.name).to.eq(`@${MOCK_PROFILE_HANDLE}`);
        expect(jsonMetadataBeforeTransfer.description).to.eq(
          `@${MOCK_PROFILE_HANDLE} - Lens profile`
        );
        const expectedAttributesBeforeTransfer = [
          { trait_type: 'id', value: `#${FIRST_PROFILE_ID.toString()}` },
          { trait_type: 'followers', value: '0' },
          { trait_type: 'owner', value: userAddress.toLowerCase() },
          { trait_type: 'handle', value: `@${MOCK_PROFILE_HANDLE}` },
        ];
        expect(jsonMetadataBeforeTransfer.attributes).to.eql(expectedAttributesBeforeTransfer);

        await expect(
          lensHub.transferFrom(userAddress, userTwoAddress, FIRST_PROFILE_ID)
        ).to.not.be.reverted;

        const tokenURIAfterTransfer = await lensHub.tokenURI(FIRST_PROFILE_ID);
        const jsonMetadataAfterTransfer = await getJsonMetadataFromBase64TokenUri(
          tokenURIAfterTransfer
        );
        expect(jsonMetadataAfterTransfer.name).to.eq(`@${MOCK_PROFILE_HANDLE}`);
        expect(jsonMetadataAfterTransfer.description).to.eq(
          `@${MOCK_PROFILE_HANDLE} - Lens profile`
        );
        const expectedAttributesAfterTransfer = [
          { trait_type: 'id', value: `#${FIRST_PROFILE_ID.toString()}` },
          { trait_type: 'followers', value: '0' },
          { trait_type: 'owner', value: userTwoAddress.toLowerCase() },
          { trait_type: 'handle', value: `@${MOCK_PROFILE_HANDLE}` },
        ];
        expect(jsonMetadataAfterTransfer.attributes).to.eql(expectedAttributesAfterTransfer);
      });

      it('Should return the correct tokenURI after a follow', async function () {
        const tokenURIBeforeTransfer = await lensHub.tokenURI(FIRST_PROFILE_ID);
        const jsonMetadataBeforeTransfer = await getJsonMetadataFromBase64TokenUri(
          tokenURIBeforeTransfer
        );
        expect(jsonMetadataBeforeTransfer.name).to.eq(`@${MOCK_PROFILE_HANDLE}`);
        expect(jsonMetadataBeforeTransfer.description).to.eq(
          `@${MOCK_PROFILE_HANDLE} - Lens profile`
        );
        const expectedAttributesBeforeTransfer = [
          { trait_type: 'id', value: `#${FIRST_PROFILE_ID.toString()}` },
          { trait_type: 'followers', value: '0' },
          { trait_type: 'owner', value: userAddress.toLowerCase() },
          { trait_type: 'handle', value: `@${MOCK_PROFILE_HANDLE}` },
        ];
        expect(jsonMetadataBeforeTransfer.attributes).to.eql(expectedAttributesBeforeTransfer);

        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;

        const tokenURIAfterTransfer = await lensHub.tokenURI(FIRST_PROFILE_ID);
        const jsonMetadataAfterTransfer = await getJsonMetadataFromBase64TokenUri(
          tokenURIAfterTransfer
        );
        expect(jsonMetadataAfterTransfer.name).to.eq(`@${MOCK_PROFILE_HANDLE}`);
        expect(jsonMetadataAfterTransfer.description).to.eq(
          `@${MOCK_PROFILE_HANDLE} - Lens profile`
        );
        const expectedAttributesAfterTransfer = [
          { trait_type: 'id', value: `#${FIRST_PROFILE_ID.toString()}` },
          { trait_type: 'followers', value: '1' },
          { trait_type: 'owner', value: userAddress.toLowerCase() },
          { trait_type: 'handle', value: `@${MOCK_PROFILE_HANDLE}` },
        ];
        expect(jsonMetadataAfterTransfer.attributes).to.eql(expectedAttributesAfterTransfer);
      });

      it('User should set user two as a dispatcher on their profile, user two should set the profile URI', async function () {
        await expect(lensHub.setDispatcher(FIRST_PROFILE_ID, userTwoAddress)).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).setProfileImageURI(FIRST_PROFILE_ID, MOCK_URI)
        ).to.not.be.reverted;
        const tokenURI = await lensHub.tokenURI(FIRST_PROFILE_ID);
        expect(keccak256(toUtf8Bytes(tokenURI))).to.eq(
          '0xe1731460db6ce5fa9f3a9f2bd778a8af49e623dceb531df6b1a5c162b7c2d79a'
        );
      });

      it('User should follow profile 1, user should change the follow NFT URI, URI is accurate before and after the change', async function () {
        await expect(lensHub.follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNFTAddress = await lensHub.getFollowNFT(FIRST_PROFILE_ID);
        const followNFT = FollowNFT__factory.connect(followNFTAddress, user);

        const uriBefore = await followNFT.tokenURI(1);
        expect(uriBefore).to.eq(MOCK_FOLLOW_NFT_URI);

        await expect(lensHub.setFollowNFTURI(FIRST_PROFILE_ID, OTHER_MOCK_URI)).to.not.be.reverted;

        const uriAfter = await followNFT.tokenURI(1);
        expect(uriAfter).to.eq(OTHER_MOCK_URI);
      });
    });
  });

  context('Meta-tx', function () {
    beforeEach(async function () {
      await expect(
        lensHub.connect(testWallet).createProfile({
          to: testWallet.address,
          handle: MOCK_PROFILE_HANDLE,
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.not.be.reverted;
    });

    context('Negatives', function () {
      it('TestWallet should fail to set profile URI with sig with signature deadline mismatch', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetProfileImageURIWithSigParts(
          FIRST_PROFILE_ID,
          MOCK_URI,
          nonce,
          '0'
        );

        await expect(
          lensHub.setProfileImageURIWithSig({
            profileId: FIRST_PROFILE_ID,
            imageURI: MOCK_URI,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should fail to set profile URI with sig with invalid deadline', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetProfileImageURIWithSigParts(
          FIRST_PROFILE_ID,
          MOCK_URI,
          nonce,
          '0'
        );

        await expect(
          lensHub.setProfileImageURIWithSig({
            profileId: FIRST_PROFILE_ID,
            imageURI: MOCK_URI,
            sig: {
              v,
              r,
              s,
              deadline: '0',
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_EXPIRED);
      });

      it('TestWallet should fail to set profile URI with sig with invalid nonce', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetProfileImageURIWithSigParts(
          FIRST_PROFILE_ID,
          MOCK_URI,
          nonce + 1,
          MAX_UINT256
        );

        await expect(
          lensHub.setProfileImageURIWithSig({
            profileId: FIRST_PROFILE_ID,
            imageURI: MOCK_URI,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should sign attempt to set profile URI with sig, cancel with empty permitForAll, then fail to set profile URI with sig', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetProfileImageURIWithSigParts(
          FIRST_PROFILE_ID,
          MOCK_URI,
          nonce,
          MAX_UINT256
        );

        await cancelWithPermitForAll();

        await expect(
          lensHub.setProfileImageURIWithSig({
            profileId: FIRST_PROFILE_ID,
            imageURI: MOCK_URI,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should fail to set the follow NFT URI with sig with signature deadline mismatch', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetFollowNFTURIWithSigParts(
          FIRST_PROFILE_ID,
          MOCK_URI,
          nonce,
          '0'
        );

        await expect(
          lensHub.setFollowNFTURIWithSig({
            profileId: FIRST_PROFILE_ID,
            followNFTURI: MOCK_URI,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should fail to set the follow NFT URI with sig with invalid deadline', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetFollowNFTURIWithSigParts(
          FIRST_PROFILE_ID,
          MOCK_URI,
          nonce,
          '0'
        );

        await expect(
          lensHub.setFollowNFTURIWithSig({
            profileId: FIRST_PROFILE_ID,
            followNFTURI: MOCK_URI,
            sig: {
              v,
              r,
              s,
              deadline: '0',
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_EXPIRED);
      });

      it('TestWallet should fail to set the follow NFT URI with sig with invalid nonce', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetFollowNFTURIWithSigParts(
          FIRST_PROFILE_ID,
          MOCK_URI,
          nonce + 1,
          MAX_UINT256
        );

        await expect(
          lensHub.setFollowNFTURIWithSig({
            profileId: FIRST_PROFILE_ID,
            followNFTURI: MOCK_URI,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should sign attempt to set follow NFT URI with sig, cancel with empty permitForAll, then fail to set follow NFT URI with sig', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetFollowNFTURIWithSigParts(
          FIRST_PROFILE_ID,
          MOCK_URI,
          nonce,
          MAX_UINT256
        );

        await cancelWithPermitForAll();

        await expect(
          lensHub.setFollowNFTURIWithSig({
            profileId: FIRST_PROFILE_ID,
            followNFTURI: MOCK_URI,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });
    });

    context('Scenarios', function () {
      it('TestWallet should set the profile URI with sig', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetProfileImageURIWithSigParts(
          FIRST_PROFILE_ID,
          MOCK_URI,
          nonce,
          MAX_UINT256
        );

        const tokenURIBefore = await lensHub.tokenURI(FIRST_PROFILE_ID);

        expect(keccak256(toUtf8Bytes(tokenURIBefore))).to.eq(
          '0x6ed04aa8ab68b7c5201afb2f9655d8fd483559794ce933b7f2282549ca9e3dba'
        );

        await expect(
          lensHub.setProfileImageURIWithSig({
            profileId: FIRST_PROFILE_ID,
            imageURI: MOCK_URI,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.not.be.reverted;

        const tokenURIAfter = await lensHub.tokenURI(FIRST_PROFILE_ID);

        expect(MOCK_PROFILE_URI).to.not.eq(MOCK_URI);
        expect(tokenURIBefore).to.not.eq(tokenURIAfter);

        expect(keccak256(toUtf8Bytes(tokenURIAfter))).to.eq(
          '0x2f93fe42168b386790c5615061bcd3c1d8aac1976bddca8cf57eb2bc525541ab'
        );
      });

      it('TestWallet should set the follow NFT URI with sig', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetFollowNFTURIWithSigParts(
          FIRST_PROFILE_ID,
          MOCK_URI,
          nonce,
          MAX_UINT256
        );

        const followNFTURIBefore = await lensHub.getFollowNFTURI(FIRST_PROFILE_ID);

        await expect(
          lensHub.setFollowNFTURIWithSig({
            profileId: FIRST_PROFILE_ID,
            followNFTURI: MOCK_URI,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.not.be.reverted;

        const followNFTURIAfter = await lensHub.getFollowNFTURI(FIRST_PROFILE_ID);

        expect(followNFTURIBefore).to.eq(MOCK_FOLLOW_NFT_URI);
        expect(followNFTURIAfter).to.eq(MOCK_URI);
      });
    });
  });
});
