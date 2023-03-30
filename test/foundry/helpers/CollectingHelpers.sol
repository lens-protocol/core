// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/foundry/base/TestSetup.t.sol';
import 'forge-std/Test.sol';
import 'contracts/libraries/constants/Types.sol';

contract CollectingHelpers is TestSetup {
    string constant COLLECT_NFT_NAME_INFIX = '-Collect-';
    string constant COLLECT_NFT_SYMBOL_INFIX = '-Cl-';

    CollectNFT _collectNftAfter;

    uint256 constant PUB_BY_ID_BY_PROFILE_MAPPING_SLOT = 20;
    uint256 constant COLLECT_NFT_OFFSET = 5;

    function _getCollectNFT(uint256 profileId, uint256 pubId) internal returns (address) {
        uint256 collectNftSlot = uint256(
            keccak256(
                abi.encode(
                    uint256(
                        keccak256(
                            abi.encode(uint256(keccak256(abi.encode(PUB_BY_ID_BY_PROFILE_MAPPING_SLOT))) + profileId)
                        )
                    ) + pubId
                )
            )
        ) + COLLECT_NFT_OFFSET;
        address collectNft = address(uint160(uint256(vm.load(address(hub), bytes32(collectNftSlot)))));
        return collectNft;
    }

    function _checkCollectNFTBefore() internal returns (uint256) {
        // collect NFT doesn't exist yet

        address collectNftAddress = _getCollectNFT(
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
            _getCollectNFT(mockCollectParams.publicationCollectedProfileId, mockCollectParams.publicationCollectedId)
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
