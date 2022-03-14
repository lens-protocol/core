import {
  BigNumber,
  BigNumberish,
} from '@ethersproject/contracts/node_modules/@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { FollowNFT__factory } from '../../../typechain-types';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import { getTimestamp, matchEvent, setNextBlockTimestamp, waitForTx } from '../../helpers/utils';
import {
  abiCoder,
  BPS_MAX,
  currency,
  FIRST_PROFILE_ID,
  governance,
  lensHub,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  MOCK_URI,
  moduleGlobals,
  REFERRAL_FEE_BPS,
  treasuryAddress,
  TREASURY_FEE_BPS,
  pubProfileOwnerAddress,
  auctionCollectModule,
  collectFeeRecipient,
  collectFeeRecipientAddress,
  otherUserAddress,
  bidder,
  emptyCollectModule,
  pubProfileOwner,
  otherBidder,
  bidderAddress,
  otherBidderAddress,
  otherUser,
  user,
} from '../../__setup.spec';

makeSuiteCleanRoom('Auction Collect Module', function () {
  const ONE_DAY_IN_SECONDS = BigNumber.from(24 * 3600);
  const TEN_MINUTES_IN_SECONDS = BigNumber.from(10 * 60);
  const DEFAULT_RESERVE_PRICE = parseEther('1');
  const DEFAULT_MIN_TIME_AFTER_BID = TEN_MINUTES_IN_SECONDS;
  const DEFAULT_MIN_BID_INCREMENT = parseEther('0.1');
  const DEFAULT_BID_AMOUNT = parseEther('2');
  const FIRST_PUB_ID = 1;

  interface AuctionCollectModuleData {
    reservePrice?: BigNumber;
    endTimestamp?: BigNumber;
    minTimeAfterBid?: BigNumber;
    minBidIncrement?: BigNumber;
    currencyAddress?: string;
    recipientAddress?: string;
    referralFee?: number;
    onlyFollowers?: boolean;
  }

  async function getAuctionCollectModuleData({
    reservePrice = DEFAULT_RESERVE_PRICE,
    endTimestamp,
    minTimeAfterBid = DEFAULT_MIN_TIME_AFTER_BID,
    minBidIncrement = DEFAULT_MIN_BID_INCREMENT,
    currencyAddress = currency.address,
    recipientAddress = collectFeeRecipientAddress,
    referralFee = REFERRAL_FEE_BPS,
    onlyFollowers = false,
  }: AuctionCollectModuleData): Promise<string> {
    return abiCoder.encode(
      ['uint256', 'uint256', 'uint256', 'uint256', 'address', 'address', 'uint16', 'bool'],
      [
        reservePrice,
        endTimestamp ? endTimestamp : BigNumber.from(await getTimestamp()).add(ONE_DAY_IN_SECONDS),
        minTimeAfterBid,
        minBidIncrement,
        currencyAddress,
        recipientAddress,
        referralFee,
        onlyFollowers,
      ]
    );
  }

  interface AuctionEndSimulationData {
    profileId?: BigNumberish;
    pubId?: BigNumberish;
    secondsToBeElapsedAfterEnd?: BigNumberish;
  }

  async function simulateAuctionEnd({
    profileId = FIRST_PROFILE_ID,
    pubId = FIRST_PUB_ID,
    secondsToBeElapsedAfterEnd = 1,
  }: AuctionEndSimulationData) {
    const endTimestamp = (await auctionCollectModule.getAuctionData(profileId, pubId))[1];
    setNextBlockTimestamp(endTimestamp.add(secondsToBeElapsedAfterEnd).toNumber());
  }

  before(async function () {
    await expect(
      lensHub.createProfile({
        to: pubProfileOwnerAddress,
        handle: MOCK_PROFILE_HANDLE,
        imageURI: MOCK_PROFILE_URI,
        followModule: ZERO_ADDRESS,
        followModuleData: [],
        followNFTURI: MOCK_FOLLOW_NFT_URI,
      })
    ).to.not.be.reverted;
    await expect(
      lensHub.connect(governance).whitelistCollectModule(auctionCollectModule.address, true)
    ).to.not.be.reverted;
    await expect(
      moduleGlobals.connect(governance).whitelistCurrency(currency.address, true)
    ).to.not.be.reverted;
  });

  context('Negatives', function () {
    context('Publication creation', function () {
      it('User should fail to post using reserve price less than max BPS', async function () {
        const collectModuleData = await getAuctionCollectModuleData({
          reservePrice: ethers.constants.Zero,
        });
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: collectModuleData,
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
      });

      it('User should fail to post using referral fee greater than max BPS', async function () {
        const collectModuleData = await getAuctionCollectModuleData({
          referralFee: BPS_MAX + 1,
        });
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: collectModuleData,
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
      });

      it('User should fail to post using auction end timestamp less than current timestamp plus min time after bid', async function () {
        const collectModuleData = await getAuctionCollectModuleData({
          endTimestamp: BigNumber.from(await getTimestamp()),
        });
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: collectModuleData,
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
      });

      it('User should fail to post using unwhitelisted currency', async function () {
        const nonWhitelistedCurrencyAddress = otherUserAddress;
        const collectModuleData = await getAuctionCollectModuleData({
          currencyAddress: nonWhitelistedCurrencyAddress,
        });
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: collectModuleData,
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
      });

      it('User should fail to post using zero address as collect fee recipient', async function () {
        const collectModuleData = await getAuctionCollectModuleData({
          recipientAddress: ZERO_ADDRESS,
        });
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: collectModuleData,
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
      });
    });

    context('Bidding', function () {
      beforeEach(async function () {
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: await getAuctionCollectModuleData({}),
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
      });

      it('User should fail to bid  for an unexistent publication', async function () {
        const unexistentPublicationId = 69;
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, unexistentPublicationId, DEFAULT_BID_AMOUNT)
        ).to.be.revertedWith(ERRORS.PUBLICATION_DOES_NOT_EXIST);
      });

      it('User should fail to bid for an existent publication which does not use auction collect module because end timestamp will be set as zero', async function () {
        await expect(
          lensHub.connect(governance).whitelistCollectModule(emptyCollectModule.address, true)
        ).to.not.be.reverted;
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: emptyCollectModule.address,
            collectModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
        const pubId = FIRST_PUB_ID + 1;
        await expect(
          auctionCollectModule.connect(bidder).bid(FIRST_PROFILE_ID, pubId, DEFAULT_BID_AMOUNT)
        ).to.be.revertedWith(ERRORS.ENDED_AUCTION);
      });

      it('User should fail to bid for a publication which auction has ended', async function () {
        await simulateAuctionEnd({});
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.be.revertedWith(ERRORS.ENDED_AUCTION);
      });

      it('Address zero should fail to bid for a publication', async function () {
        await expect(
          auctionCollectModule
            .connect(ZERO_ADDRESS)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.be.revertedWith(ERRORS.INVALID_BIDDER);
      });

      it('User should fail to bid for its own publication', async function () {
        await expect(
          auctionCollectModule
            .connect(pubProfileOwner)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.be.revertedWith(ERRORS.INVALID_BIDDER);
      });

      it('User should fail to bid for a publication where he is the collect fee recipient', async function () {
        await expect(
          auctionCollectModule
            .connect(collectFeeRecipient)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.be.revertedWith(ERRORS.INVALID_BIDDER);
      });

      it('User should fail to bid if has not approved tokens to be pulled by the auction collect module', async function () {
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_RESERVE_PRICE)
        ).to.be.revertedWith(ERRORS.ERC20_INSUFFICIENT_ALLOWANCE);
      });

      it('User should fail to bid if has insufficient token balance', async function () {
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_RESERVE_PRICE);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_RESERVE_PRICE)
        ).to.be.revertedWith(ERRORS.ERC20_TRANSFER_EXCEEDS_BALANCE);
      });

      it('User should fail to bid an amount below winning bid price', async function () {
        const winningBidPrice = parseEther('3');
        await currency.mint(bidderAddress, winningBidPrice);
        await currency.connect(bidder).approve(auctionCollectModule.address, winningBidPrice);
        await expect(
          auctionCollectModule.connect(bidder).bid(FIRST_PROFILE_ID, FIRST_PUB_ID, winningBidPrice)
        ).to.not.be.reverted;
        const amountBelowWinningBidPrice = parseEther('2');
        await currency.mint(otherBidderAddress, amountBelowWinningBidPrice);
        await currency
          .connect(otherBidder)
          .approve(auctionCollectModule.address, amountBelowWinningBidPrice);
        await expect(
          auctionCollectModule
            .connect(otherBidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, amountBelowWinningBidPrice)
        ).to.be.revertedWith(ERRORS.INSUFFICIENT_BID_AMOUNT);
      });

      it('User should fail to bid an amount below auction reserve price', async function () {
        const amountBelowReservePrice = parseEther('0.5');
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, amountBelowReservePrice)
        ).to.be.revertedWith(ERRORS.INSUFFICIENT_BID_AMOUNT);
      });

      it('User should fail to bid an amount less than winning bid price', async function () {
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        const insufficientBidIncrement = parseEther('0.00000000001');
        const incrementedAmount = DEFAULT_BID_AMOUNT.add(insufficientBidIncrement);
        await currency.mint(otherBidderAddress, insufficientBidIncrement);
        await currency
          .connect(otherBidder)
          .approve(auctionCollectModule.address, incrementedAmount);
        await expect(
          auctionCollectModule
            .connect(otherBidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, incrementedAmount)
        ).to.be.revertedWith(ERRORS.INSUFFICIENT_BID_AMOUNT);
      });

      it('User should fail to bid an amount equal to the winning bid price even when min bid increment is not set', async function () {
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: await getAuctionCollectModuleData({
              minBidIncrement: ethers.constants.Zero,
            }),
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
        const pubId = FIRST_PUB_ID + 1;
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule.connect(bidder).bid(FIRST_PROFILE_ID, pubId, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        await currency.mint(otherBidderAddress, DEFAULT_BID_AMOUNT);
        await currency
          .connect(otherBidder)
          .approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule.connect(otherBidder).bid(FIRST_PROFILE_ID, pubId, DEFAULT_BID_AMOUNT)
        ).to.be.revertedWith(ERRORS.INSUFFICIENT_BID_AMOUNT);
      });

      it('User should fail to bid an amount which has a difference lower than min bid increment between winning bid price', async function () {
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        const insufficientBidIncrement = parseEther('0.00000000001');
        const incrementedAmount = DEFAULT_BID_AMOUNT.add(insufficientBidIncrement);
        await currency.mint(otherBidderAddress, insufficientBidIncrement);
        await currency
          .connect(otherBidder)
          .approve(auctionCollectModule.address, incrementedAmount);
        await expect(
          auctionCollectModule
            .connect(otherBidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, incrementedAmount)
        ).to.be.revertedWith(ERRORS.INSUFFICIENT_BID_AMOUNT);
      });

      it('User should fail to bid an only-follower auction when he is not following the owner of the publication', async function () {
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: await getAuctionCollectModuleData({ onlyFollowers: true }),
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
        const pubId = FIRST_PUB_ID + 1;
        await expect(
          auctionCollectModule.connect(bidder).bid(FIRST_PROFILE_ID, pubId, DEFAULT_BID_AMOUNT)
        ).to.be.revertedWith(ERRORS.FOLLOW_INVALID);
      });
    });

    context('Bidding with increment', function () {
      beforeEach(async function () {
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: await getAuctionCollectModuleData({}),
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
      });

      it('User should fail to bid for an unexistent publication', async function () {
        const unexistentPublicationId = 69;
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bidWithIncrement(FIRST_PROFILE_ID, unexistentPublicationId, DEFAULT_MIN_BID_INCREMENT)
        ).to.be.revertedWith(ERRORS.PUBLICATION_DOES_NOT_EXIST);
      });

      it('User should fail to bid for an existent publication which does not use auction collect module because end timestamp will be set as zero', async function () {
        await expect(
          lensHub.connect(governance).whitelistCollectModule(emptyCollectModule.address, true)
        ).to.not.be.reverted;
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: emptyCollectModule.address,
            collectModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
        const pubId = FIRST_PUB_ID + 1;
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bidWithIncrement(FIRST_PROFILE_ID, pubId, DEFAULT_MIN_BID_INCREMENT)
        ).to.be.revertedWith(ERRORS.ENDED_AUCTION);
      });

      it('User should fail to bid for a publication which auction has ended', async function () {
        await simulateAuctionEnd({});
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bidWithIncrement(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_MIN_BID_INCREMENT)
        ).to.be.revertedWith(ERRORS.ENDED_AUCTION);
      });

      it('Address zero should fail to bid for a publication', async function () {
        await expect(
          auctionCollectModule
            .connect(ZERO_ADDRESS)
            .bidWithIncrement(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_MIN_BID_INCREMENT)
        ).to.be.revertedWith(ERRORS.INVALID_BIDDER);
      });

      it('User should fail to bid for its own publication', async function () {
        await expect(
          auctionCollectModule
            .connect(pubProfileOwner)
            .bidWithIncrement(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_MIN_BID_INCREMENT)
        ).to.be.revertedWith(ERRORS.INVALID_BIDDER);
      });

      it('User should fail to bid for a publication where he is the collect fee recipient', async function () {
        await expect(
          auctionCollectModule
            .connect(collectFeeRecipient)
            .bidWithIncrement(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_MIN_BID_INCREMENT)
        ).to.be.revertedWith(ERRORS.INVALID_BIDDER);
      });

      it('User should fail to bid if has not approved tokens to be pulled by the auction collect module', async function () {
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bidWithIncrement(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_MIN_BID_INCREMENT)
        ).to.be.revertedWith(ERRORS.ERC20_INSUFFICIENT_ALLOWANCE);
      });

      it('User should fail to bid if has insufficient token balance', async function () {
        await currency
          .connect(bidder)
          .approve(
            auctionCollectModule.address,
            DEFAULT_RESERVE_PRICE.add(DEFAULT_MIN_BID_INCREMENT)
          );
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bidWithIncrement(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_MIN_BID_INCREMENT)
        ).to.be.revertedWith(ERRORS.ERC20_TRANSFER_EXCEEDS_BALANCE);
      });

      it('User should fail to bid with an increment lower than min bid increment', async function () {
        const insufficientBidIncrement = parseEther('0.00000000001');
        const expectedBidAmount = DEFAULT_RESERVE_PRICE.add(insufficientBidIncrement);
        await currency.mint(bidderAddress, expectedBidAmount);
        await currency.connect(bidder).approve(auctionCollectModule.address, expectedBidAmount);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, insufficientBidIncrement)
        ).to.be.revertedWith(ERRORS.INSUFFICIENT_BID_AMOUNT);
      });

      it('User should fail to bid with zero increment when there is already a winning bid even if min bid increment is not set', async function () {
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: await getAuctionCollectModuleData({
              minBidIncrement: ethers.constants.Zero,
            }),
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
        const pubId = FIRST_PUB_ID + 1;
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule.connect(bidder).bid(FIRST_PROFILE_ID, pubId, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        await currency.mint(otherBidderAddress, DEFAULT_BID_AMOUNT);
        await currency
          .connect(otherBidder)
          .approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule.connect(otherBidder).bid(FIRST_PROFILE_ID, pubId, 0)
        ).to.be.revertedWith(ERRORS.INSUFFICIENT_BID_AMOUNT);
      });

      it('User should fail to bid an only-follower auction when he is not following the owner of the publication', async function () {
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: await getAuctionCollectModuleData({ onlyFollowers: true }),
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
        const pubId = FIRST_PUB_ID + 1;
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bidWithIncrement(FIRST_PROFILE_ID, pubId, DEFAULT_MIN_BID_INCREMENT)
        ).to.be.revertedWith(ERRORS.FOLLOW_INVALID);
      });
    });

    context('Withdrawing', function () {
      beforeEach(async function () {
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: await getAuctionCollectModuleData({}),
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
      });

      it('User should fail to withdraw if the publication does not exists', async function () {
        const unexistentPublicationId = 69;
        await expect(
          auctionCollectModule.connect(bidder).withdraw(FIRST_PROFILE_ID, unexistentPublicationId)
        ).to.be.revertedWith(ERRORS.NOTHING_TO_WITHDRAW);
      });

      it('User should fail to withdraw if the publication does not have the auction collect module set', async function () {
        await expect(
          lensHub.connect(governance).whitelistCollectModule(emptyCollectModule.address, true)
        ).to.not.be.reverted;
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: emptyCollectModule.address,
            collectModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
        const pubId = FIRST_PROFILE_ID + 1;
        await expect(
          auctionCollectModule.connect(bidder).withdraw(FIRST_PROFILE_ID, pubId)
        ).to.be.revertedWith(ERRORS.NOTHING_TO_WITHDRAW);
      });

      it('User should fail to withdraw if he has never bidded on the auction', async function () {
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        await expect(
          auctionCollectModule.connect(otherBidder).withdraw(FIRST_PROFILE_ID, FIRST_PUB_ID)
        ).to.be.revertedWith(ERRORS.NOTHING_TO_WITHDRAW);
      });

      it('User should fail to withdraw if he is the current auction winner', async function () {
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        const winner = (
          await auctionCollectModule.getAuctionData(FIRST_PROFILE_ID, FIRST_PUB_ID)
        )[5];
        expect(winner).to.be.equal(bidderAddress);
        await expect(
          auctionCollectModule.connect(winner).withdraw(FIRST_PROFILE_ID, FIRST_PUB_ID)
        ).to.be.revertedWith(ERRORS.AUCTION_WINNER_CAN_NOT_WITHDRAW);
      });

      it('User should fail to withdraw if he has already withdrawn from the auction', async function () {
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        const otherBidderBidAmount = DEFAULT_BID_AMOUNT.add(DEFAULT_MIN_BID_INCREMENT);
        await currency.mint(otherBidderAddress, otherBidderBidAmount);
        await currency
          .connect(otherBidder)
          .approve(auctionCollectModule.address, otherBidderBidAmount);
        await expect(
          auctionCollectModule
            .connect(otherBidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, otherBidderBidAmount)
        ).to.not.be.reverted;
        await expect(
          auctionCollectModule.connect(bidder).withdraw(FIRST_PROFILE_ID, FIRST_PUB_ID)
        ).to.not.be.reverted;
        await expect(
          auctionCollectModule.connect(bidder).withdraw(FIRST_PROFILE_ID, FIRST_PUB_ID)
        ).to.be.revertedWith(ERRORS.NOTHING_TO_WITHDRAW);
      });
    });

    context('Collecting', function () {
      beforeEach(async function () {
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: await getAuctionCollectModuleData({}),
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
      });

      it('User should fail to collect if auction has ended without a winner', async function () {
        await simulateAuctionEnd({});
        await expect(
          lensHub.connect(bidder).collect(FIRST_PROFILE_ID, FIRST_PUB_ID, [])
        ).to.be.revertedWith(ERRORS.MODULE_DATA_MISMATCH);
      });

      it('User should fail to collect if auction has ended without a winner even when address zero is the collector', async function () {
        await simulateAuctionEnd({});
        await expect(
          lensHub.connect(ZERO_ADDRESS).collect(FIRST_PROFILE_ID, FIRST_PUB_ID, [])
        ).to.be.revertedWith(ERRORS.ERC721_MINT_TO_ZERO_ADDRESS);
      });

      it('User should fail to collect if auction has not ended yet', async function () {
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        const winner = (
          await auctionCollectModule.getAuctionData(FIRST_PROFILE_ID, FIRST_PUB_ID)
        )[5];
        expect(winner).to.be.equal(bidderAddress);
        await expect(
          lensHub.connect(bidder).collect(FIRST_PROFILE_ID, FIRST_PUB_ID, [])
        ).to.be.revertedWith(ERRORS.ACTIVE_AUCTION);
      });

      it('User should fail to collect if he is passing custom data', async function () {
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        await simulateAuctionEnd({});
        const winner = (
          await auctionCollectModule.getAuctionData(FIRST_PROFILE_ID, FIRST_PUB_ID)
        )[5];
        expect(winner).to.be.equal(bidderAddress);
        const unexpectedCustomData = abiCoder.encode(
          ['address', 'uint256'],
          [currency.address, DEFAULT_BID_AMOUNT]
        );
        await expect(
          lensHub.connect(bidder).collect(FIRST_PROFILE_ID, FIRST_PUB_ID, unexpectedCustomData)
        ).to.be.revertedWith(ERRORS.MODULE_DATA_MISMATCH);
      });

      it('User should fail to collect if has referrer profile and the passed one is not matching the one in his first bid', async function () {
        await expect(
          lensHub.createProfile({
            to: otherUserAddress,
            handle: 'otheruserhandle',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        const otherUserProfileId = FIRST_PROFILE_ID + 1;
        await expect(
          lensHub.connect(otherUser).mirror({
            profileId: otherUserProfileId,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: FIRST_PUB_ID,
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(otherUserProfileId, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        await simulateAuctionEnd({});
        const winner = (
          await auctionCollectModule.getAuctionData(FIRST_PROFILE_ID, FIRST_PUB_ID)
        )[5];
        expect(winner).to.equals(bidderAddress);
        const referrerProfileId = await auctionCollectModule.getReferrerProfileIdOf(
          FIRST_PROFILE_ID,
          FIRST_PUB_ID,
          winner
        );
        expect(referrerProfileId).to.equals(otherUserProfileId);
        await expect(
          lensHub.connect(bidder).collect(FIRST_PROFILE_ID, FIRST_PUB_ID, [])
        ).to.be.revertedWith(ERRORS.MODULE_DATA_MISMATCH);
      });

      it('User should fail to collect if does not have referrer profile and he is passing one', async function () {
        await expect(
          lensHub.createProfile({
            to: otherUserAddress,
            handle: 'otheruserhandle',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        const otherUserProfileId = FIRST_PROFILE_ID + 1;
        await expect(
          lensHub.connect(otherUser).mirror({
            profileId: otherUserProfileId,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: FIRST_PUB_ID,
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        await simulateAuctionEnd({});
        const winner = (
          await auctionCollectModule.getAuctionData(FIRST_PROFILE_ID, FIRST_PUB_ID)
        )[5];
        expect(winner).to.equals(bidderAddress);
        const referrerProfileId = await auctionCollectModule.getReferrerProfileIdOf(
          FIRST_PROFILE_ID,
          FIRST_PUB_ID,
          winner
        );
        expect(referrerProfileId).to.equals(FIRST_PROFILE_ID);
        await expect(
          lensHub.connect(bidder).collect(otherUserProfileId, FIRST_PUB_ID, [])
        ).to.be.revertedWith(ERRORS.MODULE_DATA_MISMATCH);
      });

      it('User should fail to collect if collector is not the winner and has not even participated in the auction', async function () {
        await currency.mint(otherBidderAddress, DEFAULT_RESERVE_PRICE);
        await currency
          .connect(otherBidder)
          .approve(auctionCollectModule.address, DEFAULT_RESERVE_PRICE);
        await expect(
          auctionCollectModule
            .connect(otherBidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_RESERVE_PRICE)
        ).to.not.be.reverted;
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        await simulateAuctionEnd({});
        const winner = (
          await auctionCollectModule.getAuctionData(FIRST_PROFILE_ID, FIRST_PUB_ID)
        )[5];
        expect(winner).to.be.equal(bidderAddress);
        await expect(
          lensHub.connect(otherUser).collect(FIRST_PROFILE_ID, FIRST_PUB_ID, [])
        ).to.be.revertedWith(ERRORS.MODULE_DATA_MISMATCH);
      });

      it('User should fail to collect if collector is not the winner even if he has participated in the auction', async function () {
        await currency.mint(otherBidderAddress, DEFAULT_RESERVE_PRICE);
        await currency
          .connect(otherBidder)
          .approve(auctionCollectModule.address, DEFAULT_RESERVE_PRICE);
        await expect(
          auctionCollectModule
            .connect(otherBidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_RESERVE_PRICE)
        ).to.not.be.reverted;
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        await simulateAuctionEnd({});
        const winner = (
          await auctionCollectModule.getAuctionData(FIRST_PROFILE_ID, FIRST_PUB_ID)
        )[5];
        expect(winner).to.be.equal(bidderAddress);
        await expect(
          lensHub.connect(otherBidder).collect(FIRST_PROFILE_ID, FIRST_PUB_ID, [])
        ).to.be.revertedWith(ERRORS.MODULE_DATA_MISMATCH);
      });

      it('User should fail to collect if publication was already collected', async function () {
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule
            .connect(bidder)
            .bid(FIRST_PROFILE_ID, FIRST_PUB_ID, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        await simulateAuctionEnd({});
        const winner = (
          await auctionCollectModule.getAuctionData(FIRST_PROFILE_ID, FIRST_PUB_ID)
        )[5];
        expect(winner).to.be.equal(bidderAddress);
        await expect(
          lensHub.connect(bidder).collect(FIRST_PROFILE_ID, FIRST_PUB_ID, [])
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(bidder).collect(FIRST_PROFILE_ID, FIRST_PUB_ID, [])
        ).to.be.revertedWith(ERRORS.COLLECT_NOT_ALLOWED);
      });

      it('User should fail to collect if auction is for followers only and he is not following the owner of the publication anymore', async function () {
        await expect(
          lensHub.post({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: auctionCollectModule.address,
            collectModuleData: await getAuctionCollectModuleData({ onlyFollowers: true }),
            referenceModule: ZERO_ADDRESS,
            referenceModuleData: [],
          })
        ).to.not.be.reverted;
        await expect(lensHub.connect(bidder).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
        const followNftAddress = await lensHub.getFollowNFT(FIRST_PROFILE_ID);
        expect(followNftAddress).to.not.equals(ZERO_ADDRESS);
        const followNFT = FollowNFT__factory.connect(followNftAddress, bidder);
        expect(await followNFT.totalSupply()).to.equals(1);
        expect(await followNFT.ownerOf(1)).to.equals(bidderAddress);
        const pubId = FIRST_PUB_ID + 1;
        await currency.mint(bidderAddress, DEFAULT_BID_AMOUNT);
        await currency.connect(bidder).approve(auctionCollectModule.address, DEFAULT_BID_AMOUNT);
        await expect(
          auctionCollectModule.connect(bidder).bid(FIRST_PROFILE_ID, pubId, DEFAULT_BID_AMOUNT)
        ).to.not.be.reverted;
        await simulateAuctionEnd({ pubId: pubId });
        const winner = (await auctionCollectModule.getAuctionData(FIRST_PROFILE_ID, pubId))[5];
        expect(winner).to.equals(bidderAddress);
        await expect(followNFT.burn(1)).to.not.be.reverted;
        expect(await followNFT.balanceOf(bidderAddress)).to.equals(0);
        await expect(
          lensHub.connect(bidder).collect(FIRST_PROFILE_ID, pubId, [])
        ).to.be.revertedWith(ERRORS.FOLLOW_INVALID);
      });
    });

    context('Processing collect fee', function () {});

    context('Bidding meta-tx', function () {});

    context('Bidding with increment meta-tx', function () {});

    context('Withdrawing meta-tx', function () {});
  });

  context('Scenarios', function () {});
});
