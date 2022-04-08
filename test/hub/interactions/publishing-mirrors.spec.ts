import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { MAX_UINT256, ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import {
  cancelWithPermitForAll,
  getMirrorWithSigParts,
  mirrorReturningTokenId,
} from '../../helpers/utils';
import {
  abiCoder,
  freeCollectModule,
  FIRST_PROFILE_ID,
  governance,
  lensHub,
  makeSuiteCleanRoom,
  mockReferenceModule,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  MOCK_URI,
  testWallet,
  userAddress,
  userTwo,
  userTwoAddress,
} from '../../__setup.spec';

makeSuiteCleanRoom('Publishing mirrors', function () {
  context('Generic', function () {
    beforeEach(async function () {
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
        lensHub.connect(governance).whitelistCollectModule(freeCollectModule.address, true)
      ).to.not.be.reverted;

      await expect(
        lensHub.connect(governance).whitelistReferenceModule(mockReferenceModule.address, true)
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
    });

    context('Negatives', function () {
      it('UserTwo should fail to publish a mirror to a profile owned by User', async function () {
        await expect(
          lensHub.connect(userTwo).mirror({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 1,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER_OR_DISPATCHER);
      });

      it('User should fail to mirror with an unwhitelisted reference module', async function () {
        await expect(
          lensHub.mirror({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 1,
            referenceModuleData: [],
            referenceModule: userAddress,
            referenceModuleInitData: [],
          })
        ).to.be.revertedWith(ERRORS.REFERENCE_MODULE_NOT_WHITELISTED);
      });

      it('User should fail to mirror with invalid reference module data format', async function () {
        await expect(
          lensHub.mirror({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 1,
            referenceModuleData: [],
            referenceModule: mockReferenceModule.address,
            referenceModuleInitData: [0x12, 0x23],
          })
        ).to.be.revertedWith(ERRORS.NO_REASON_ABI_DECODE);
      });

      it('User should fail to mirror a publication that does not exist', async function () {
        await expect(
          lensHub.mirror({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 2,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.be.revertedWith(ERRORS.PUBLICATION_DOES_NOT_EXIST);
      });
    });

    context('Scenarios', function () {
      it('Should return the expected token IDs when mirroring publications', async function () {
        await expect(
          lensHub.createProfile({
            to: testWallet.address,
            handle: 'testwallet',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;

        expect(
          await mirrorReturningTokenId({
            vars: {
              profileId: FIRST_PROFILE_ID,
              profileIdPointed: FIRST_PROFILE_ID,
              pubIdPointed: 1,
              referenceModuleData: [],
              referenceModule: ZERO_ADDRESS,
              referenceModuleInitData: [],
            },
          })
        ).to.eq(2);

        expect(
          await mirrorReturningTokenId({
            sender: userTwo,
            vars: {
              profileId: FIRST_PROFILE_ID + 2,
              profileIdPointed: FIRST_PROFILE_ID,
              pubIdPointed: 2,
              referenceModuleData: [],
              referenceModule: ZERO_ADDRESS,
              referenceModuleInitData: [],
            },
          })
        ).to.eq(1);

        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const referenceModuleInitData = [];
        const referenceModuleData = [];

        const { v, r, s } = await getMirrorWithSigParts(
          FIRST_PROFILE_ID + 1,
          FIRST_PROFILE_ID,
          '1',
          referenceModuleData,
          ZERO_ADDRESS,
          referenceModuleInitData,
          nonce,
          MAX_UINT256
        );
        expect(
          await mirrorReturningTokenId({
            vars: {
              profileId: FIRST_PROFILE_ID + 1,
              profileIdPointed: FIRST_PROFILE_ID,
              pubIdPointed: '1',
              referenceModuleData: [],
              referenceModule: ZERO_ADDRESS,
              referenceModuleInitData: referenceModuleInitData,
              sig: {
                v,
                r,
                s,
                deadline: MAX_UINT256,
              },
            },
          })
        ).to.eq(1);

        expect(
          await mirrorReturningTokenId({
            vars: {
              profileId: FIRST_PROFILE_ID,
              profileIdPointed: FIRST_PROFILE_ID + 1,
              pubIdPointed: 1,
              referenceModuleData: [],
              referenceModule: ZERO_ADDRESS,
              referenceModuleInitData: [],
            },
          })
        ).to.eq(3);
      });

      it('User should create a mirror with empty reference module and reference module data, fetched mirror data should be accurate', async function () {
        await expect(
          lensHub.mirror({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 1,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.not.be.reverted;

        const pub = await lensHub.getPub(FIRST_PROFILE_ID, 2);
        expect(pub.profileIdPointed).to.eq(FIRST_PROFILE_ID);
        expect(pub.pubIdPointed).to.eq(1);
        expect(pub.contentURI).to.eq('');
        expect(pub.collectModule).to.eq(ZERO_ADDRESS);
        expect(pub.collectNFT).to.eq(ZERO_ADDRESS);
        expect(pub.referenceModule).to.eq(ZERO_ADDRESS);
      });

      it('User should mirror a mirror with empty reference module and reference module data, fetched mirror data should be accurate and point to the original post', async function () {
        await expect(
          lensHub.mirror({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 1,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.not.be.reverted;

        await expect(
          lensHub.mirror({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 2,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.not.be.reverted;

        const pub = await lensHub.getPub(FIRST_PROFILE_ID, 3);
        expect(pub.profileIdPointed).to.eq(FIRST_PROFILE_ID);
        expect(pub.pubIdPointed).to.eq(1);
        expect(pub.contentURI).to.eq('');
        expect(pub.collectModule).to.eq(ZERO_ADDRESS);
        expect(pub.collectNFT).to.eq(ZERO_ADDRESS);
        expect(pub.referenceModule).to.eq(ZERO_ADDRESS);
      });

      it('User should create a post using the mock reference module as reference module, then mirror that post', async function () {
        const data = abiCoder.encode(['uint256'], ['1']);
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: freeCollectModule.address,
            collectModuleInitData: abiCoder.encode(['bool'], [true]),
            referenceModule: mockReferenceModule.address,
            referenceModuleInitData: data,
          })
        ).to.not.be.reverted;

        await expect(
          lensHub.mirror({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 2,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.not.be.reverted;
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
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.not.be.reverted;

      await expect(
        lensHub.connect(governance).whitelistCollectModule(freeCollectModule.address, true)
      ).to.not.be.reverted;

      await expect(
        lensHub.connect(testWallet).post({
          profileId: FIRST_PROFILE_ID,
          contentURI: MOCK_URI,
          collectModule: freeCollectModule.address,
          collectModuleInitData: abiCoder.encode(['bool'], [true]),
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      ).to.not.be.reverted;
    });

    context('Negatives', function () {
      it('Testwallet should fail to mirror with sig with signature deadline mismatch', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const referenceModuleInitData = [];
        const referenceModuleData = [];

        const { v, r, s } = await getMirrorWithSigParts(
          FIRST_PROFILE_ID,
          FIRST_PROFILE_ID,
          '1',
          referenceModuleData,
          ZERO_ADDRESS,
          referenceModuleInitData,
          nonce,
          '0'
        );

        await expect(
          lensHub.mirrorWithSig({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: '1',
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: referenceModuleInitData,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('Testwallet should fail to mirror with sig with invalid deadline', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const referenceModuleInitData = [];
        const referenceModuleData = [];

        const { v, r, s } = await getMirrorWithSigParts(
          FIRST_PROFILE_ID,
          FIRST_PROFILE_ID,
          '1',
          referenceModuleData,
          ZERO_ADDRESS,
          referenceModuleInitData,
          nonce,
          '0'
        );

        await expect(
          lensHub.mirrorWithSig({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: '1',
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: referenceModuleInitData,
            sig: {
              v,
              r,
              s,
              deadline: '0',
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_EXPIRED);
      });

      it('Testwallet should fail to mirror with sig with invalid deadline', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const referenceModuleInitData = [];
        const referenceModuleData = [];

        const { v, r, s } = await getMirrorWithSigParts(
          FIRST_PROFILE_ID,
          FIRST_PROFILE_ID,
          '1',
          referenceModuleData,
          ZERO_ADDRESS,
          referenceModuleInitData,
          nonce + 1,
          MAX_UINT256
        );

        await expect(
          lensHub.mirrorWithSig({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: '1',
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: referenceModuleInitData,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('Testwallet should fail to mirror with sig with unwhitelisted reference module', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const referenceModuleInitData = [];
        const referenceModuleData = [];
        const { v, r, s } = await getMirrorWithSigParts(
          FIRST_PROFILE_ID,
          FIRST_PROFILE_ID,
          '1',
          referenceModuleData,
          userAddress,
          referenceModuleInitData,
          nonce,
          MAX_UINT256
        );

        await expect(
          lensHub.mirrorWithSig({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: '1',
            referenceModuleData: [],
            referenceModule: userAddress,
            referenceModuleInitData: referenceModuleInitData,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.REFERENCE_MODULE_NOT_WHITELISTED);
      });

      it('TestWallet should fail to mirror a publication with sig that does not exist yet', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const referenceModuleInitData = [];
        const referenceModuleData = [];

        const { v, r, s } = await getMirrorWithSigParts(
          FIRST_PROFILE_ID,
          FIRST_PROFILE_ID,
          '2',
          referenceModuleData,
          ZERO_ADDRESS,
          referenceModuleInitData,
          nonce,
          MAX_UINT256
        );

        await expect(
          lensHub.mirrorWithSig({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: '2',
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: referenceModuleInitData,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.PUBLICATION_DOES_NOT_EXIST);
      });

      it('TestWallet should sign attempt to mirror with sig, cancel via empty permitForAll, then fail to mirror with sig', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const referenceModuleInitData = [];
        const referenceModuleData = [];

        const { v, r, s } = await getMirrorWithSigParts(
          FIRST_PROFILE_ID,
          FIRST_PROFILE_ID,
          '1',
          referenceModuleData,
          ZERO_ADDRESS,
          referenceModuleInitData,
          nonce,
          MAX_UINT256
        );

        await cancelWithPermitForAll();

        await expect(
          lensHub.mirrorWithSig({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: '1',
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: referenceModuleInitData,
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
      it('Testwallet should mirror with sig, fetched mirror data should be accurate', async function () {
        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const referenceModuleInitData = [];
        const referenceModuleData = [];

        const { v, r, s } = await getMirrorWithSigParts(
          FIRST_PROFILE_ID,
          FIRST_PROFILE_ID,
          '1',
          referenceModuleData,
          ZERO_ADDRESS,
          referenceModuleInitData,
          nonce,
          MAX_UINT256
        );

        await expect(
          lensHub.mirrorWithSig({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: '1',
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: referenceModuleInitData,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.not.be.reverted;

        const pub = await lensHub.getPub(FIRST_PROFILE_ID, 2);
        expect(pub.profileIdPointed).to.eq(FIRST_PROFILE_ID);
        expect(pub.pubIdPointed).to.eq(1);
        expect(pub.contentURI).to.eq('');
        expect(pub.collectModule).to.eq(ZERO_ADDRESS);
        expect(pub.collectNFT).to.eq(ZERO_ADDRESS);
        expect(pub.referenceModule).to.eq(ZERO_ADDRESS);
      });

      it('TestWallet should mirror a mirror with sig, fetched mirror data should be accurate', async function () {
        await expect(
          lensHub.connect(testWallet).mirror({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 1,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.not.be.reverted;

        const nonce = (await lensHub.sigNonces(testWallet.address)).toNumber();
        const referenceModuleInitData = [];
        const referenceModuleData = [];
        
        const { v, r, s } = await getMirrorWithSigParts(
          FIRST_PROFILE_ID,
          FIRST_PROFILE_ID,
          '2',
          referenceModuleData,
          ZERO_ADDRESS,
          referenceModuleInitData,
          nonce,
          MAX_UINT256
        );

        await expect(
          lensHub.mirrorWithSig({
            profileId: FIRST_PROFILE_ID,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: '2',
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: referenceModuleInitData,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.not.be.reverted;

        const pub = await lensHub.getPub(FIRST_PROFILE_ID, 3);
        expect(pub.profileIdPointed).to.eq(FIRST_PROFILE_ID);
        expect(pub.pubIdPointed).to.eq(1);
        expect(pub.contentURI).to.eq('');
        expect(pub.collectModule).to.eq(ZERO_ADDRESS);
        expect(pub.collectNFT).to.eq(ZERO_ADDRESS);
        expect(pub.referenceModule).to.eq(ZERO_ADDRESS);
      });
    });
  });
});
