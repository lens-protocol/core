// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '../base/TestSetup.t.sol';
import 'forge-std/Test.sol';
import 'contracts/libraries/DataTypes.sol';

contract CollectingHelpers is TestSetup {
    CollectNFT _collectNftAfter;

    function _checkCollectNFTBefore() internal view returns (uint256) {
        // collect NFT doesn't exist yet

        address collectNftAddress = hub.getCollectNFT(
            mockCollectData.publisherProfileId,
            mockCollectData.pubId
        );

        // returns nft ID or 0 if no collect nft yet
        if (collectNftAddress != address(0)) {
            return CollectNFT(collectNftAddress).totalSupply();
        } else {
            return 0;
        }
    }

    function _checkCollectNFTAfter(uint256 nftId, uint256 expectedNftId) internal {
        _collectNftAfter = CollectNFT(
            hub.getCollectNFT(mockCollectData.publisherProfileId, mockCollectData.pubId)
        );

        (uint256 profileId, uint256 pubId) = _collectNftAfter.getSourcePublicationPointer();
        assertEq(profileId, mockCollectData.publisherProfileId);
        assertEq(pubId, mockCollectData.pubId);

        assertEq(nftId, expectedNftId);
        assertEq(
            _collectNftAfter.ownerOf(mockCollectData.pubId),
            hub.ownerOf(mockCollectData.collectorProfileId)
        );
        assertEq(_collectNftAfter.name(), _expectedName());
        assertEq(_collectNftAfter.symbol(), _expectedSymbol());
    }

    function _expectedName() internal virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    vm.toString(mockCollectData.publisherProfileId),
                    COLLECT_NFT_NAME_INFIX,
                    vm.toString(mockCollectData.pubId)
                )
            );
    }

    function _expectedSymbol() internal virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    vm.toString(mockCollectData.publisherProfileId),
                    COLLECT_NFT_SYMBOL_INFIX,
                    vm.toString(mockCollectData.pubId)
                )
            );
    }
}
