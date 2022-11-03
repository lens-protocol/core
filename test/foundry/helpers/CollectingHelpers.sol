// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '../base/TestSetup.t.sol';
import 'forge-std/Test.sol';
import 'contracts/libraries/DataTypes.sol';

contract CollectingHelpers is TestSetup {
    using Strings for uint256;

    CollectNFT _collectNftAfter;

    function _checkCollectNFTAfter(uint256 nftId) internal {
        _collectNftAfter = CollectNFT(
            hub.getCollectNFT(mockCollectData.profileId, mockCollectData.pubId)
        );
        assertEq(nftId, mockCollectData.pubId);
        assertEq(_collectNftAfter.ownerOf(mockCollectData.pubId), mockCollectData.collector);
        assertEq(_collectNftAfter.name(), _expectedName());
        assertEq(_collectNftAfter.symbol(), _expectedSymbol());
    }

    function _expectedName() internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    mockCollectData.profileId.toString(),
                    COLLECT_NFT_NAME_INFIX,
                    uint256(mockCollectData.pubId).toString()
                )
            );
    }

    function _expectedSymbol() internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    mockCollectData.profileId.toString(),
                    COLLECT_NFT_SYMBOL_INFIX,
                    uint256(mockCollectData.pubId).toString()
                )
            );
    }
}
