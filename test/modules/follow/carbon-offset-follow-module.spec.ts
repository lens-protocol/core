import { BigNumber } from '@ethersproject/contracts/node_modules/@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { MAX_UINT256, ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import { getTimestamp, matchEvent, waitForTx } from '../../helpers/utils';
import {
  abiCoder,
  BPS_MAX,
  currency,
  bctToken,
  carbonOffsetFollowModule,
  FIRST_PROFILE_ID,
  governance,
  lensHub,
  lensHubImpl,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  moduleGlobals,
  treasuryAddress,
  TREASURY_FEE_BPS,
  userAddress,
  userTwo,
  userTwoAddress,
} from '../../__setup.spec';

makeSuiteCleanRoom('Carbon Offset Follow Module', function () {
  const DEFAULT_FOLLOW_PRICE = parseEther('10');
  const OFFSET_PERCENT = '100';

  beforeEach(async function () {
    await expect(
      lensHub.connect(governance).whitelistFollowModule(carbonOffsetFollowModule.address, true)
    ).to.not.be.reverted;
    await expect(
      moduleGlobals.connect(governance).whitelistCurrency(currency.address, true)
    ).to.not.be.reverted;
  });

  context.only('Scenarios', function () {
    it('User should create a profile with the carbon offset follow module as the follow module and data, user two follows, fee distribution is valid', async function () {
      const followModuleData = abiCoder.encode(
        ['uint256', 'uint256', 'address', 'address', 'address'],
        [DEFAULT_FOLLOW_PRICE, OFFSET_PERCENT, currency.address, bctToken.address, userAddress]
      );
      await expect(
        lensHub.createProfile({
          to: userAddress,
          handle: MOCK_PROFILE_HANDLE,
          imageURI: MOCK_PROFILE_URI,
          followModule: carbonOffsetFollowModule.address,
          followModuleData: followModuleData,
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.not.be.reverted;

      await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
      await expect(
        currency.connect(userTwo).approve(carbonOffsetFollowModule.address, MAX_UINT256)
      ).to.not.be.reverted;
      const data = abiCoder.encode(
        ['address', 'uint256'],
        [currency.address, DEFAULT_FOLLOW_PRICE]
      );
      await lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [data]);
      await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [data])).to.not.be.reverted;

      const expectedTreasuryAmount = BigNumber.from(DEFAULT_FOLLOW_PRICE)
        .mul(TREASURY_FEE_BPS)
        .div(BPS_MAX);
      const expectedOffsetAmount = BigNumber.from(DEFAULT_FOLLOW_PRICE)
        .mul(OFFSET_PERCENT)
        .div(BPS_MAX);
      const expectedRecipientAmount = BigNumber.from(DEFAULT_FOLLOW_PRICE)
        .sub(expectedTreasuryAmount)
        .sub(expectedOffsetAmount);

      expect(await currency.balanceOf(userTwoAddress)).to.eq(
        BigNumber.from(MAX_UINT256).sub(DEFAULT_FOLLOW_PRICE)
      );
      expect(await currency.balanceOf(userAddress)).to.eq(expectedRecipientAmount);
      expect(await currency.balanceOf(treasuryAddress)).to.eq(expectedTreasuryAmount);
    });
  });
});
