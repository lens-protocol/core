// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '../base/TestSetup.t.sol';
import 'forge-std/Test.sol';
import 'contracts/libraries/DataTypes.sol';

contract CollectingHelpers is TestSetup {
    using Strings for uint256;

    CollectNFT _collectNftAfter;

    function _checkCollectNFTBefore() internal returns (uint256) {
        // collect NFT doesn't exist yet

        address collectNftAddress = hub.getCollectNFT(
            mockCollectData.profileId,
            mockCollectData.pubId
        );

        // TODO improve this for fork tests
        assertEq(collectNftAddress, address(0));

        // returns nft ID or 0 if no collect nft yet
        if (collectNftAddress != address(0)) {
            return CollectNFT(collectNftAddress).totalSupply();
        } else {
            return 0;
        }
    }

    function _checkCollectNFTAfter(uint256 nftId, uint256 expectedNftId) internal {
        _collectNftAfter = CollectNFT(
            hub.getCollectNFT(mockCollectData.profileId, mockCollectData.pubId)
        );

        assertEq(nftId, expectedNftId);
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
