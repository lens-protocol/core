// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '../base/TestSetup.t.sol';
import 'forge-std/Test.sol';
import 'contracts/libraries/constants/Types.sol';

contract CollectingHelpers is TestSetup {
    CollectNFT _collectNftAfter;

    function _checkCollectNFTBefore() internal view returns (uint256) {
        // collect NFT doesn't exist yet

        address collectNftAddress = hub.getCollectNFT(
            mockCollectParams.publicationCollectedProfileId,
            mockCollectParams.publicationCollectedId
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
            hub.getCollectNFT(
                mockCollectParams.publicationCollectedProfileId,
                mockCollectParams.publicationCollectedId
            )
        );

        (uint256 profileId, uint256 pubId) = _collectNftAfter.getSourcePublicationPointer();
        assertEq(profileId, mockCollectParams.publicationCollectedProfileId);
        assertEq(pubId, mockCollectParams.publicationCollectedId);

        assertEq(nftId, expectedNftId);
        assertEq(
            _collectNftAfter.ownerOf(mockCollectParams.publicationCollectedId),
            hub.ownerOf(mockCollectParams.collectorProfileId)
        );
        assertEq(_collectNftAfter.name(), _expectedName());
        assertEq(_collectNftAfter.symbol(), _expectedSymbol());
    }

    function _expectedName() internal virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    vm.toString(mockCollectParams.publicationCollectedProfileId),
                    COLLECT_NFT_NAME_INFIX,
                    vm.toString(mockCollectParams.publicationCollectedId)
                )
            );
    }

    function _expectedSymbol() internal virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    vm.toString(mockCollectParams.publicationCollectedProfileId),
                    COLLECT_NFT_SYMBOL_INFIX,
                    vm.toString(mockCollectParams.publicationCollectedId)
                )
            );
    }
}
