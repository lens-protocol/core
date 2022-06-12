// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import 'forge-std/Test.sol';

import {Deploy} from '../../scripts/Deploy.sol';
import {DataTypes} from '../../contracts/libraries/DataTypes.sol';

contract BaseTest is Test {
    address immutable user = vm.addr(1);
    address immutable userTwo = vm.addr(2);
    address immutable userThree = vm.addr(3);
    address immutable governance = vm.addr(4);
    address immutable treasury = vm.addr(5);

    uint256 immutable FIRST_PROFILE_ID = 1;
    string constant MOCK_PROFILE_HANDLE = 'plant1ghost.eth';
    string constant MOCK_PROFILE_URI =
        'https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu';
    string constant MOCK_FOLLOW_NFT_URI =
        'https://ipfs.fleek.co/ipfs/ghostplantghostplantghostplantghostplantghostplantghostplan';

    string constant MOCK_URI = 'https://ipfs.io/ipfs/QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR';

    Deploy.Contracts internal contracts;

    function setUp() public virtual {
        Deploy deploy = new Deploy();

        // We delegate call here so that msg.sender is persisted and so that we do not need to have
        // test specific changes in the deploy script
        (bool success, bytes memory result) = address(deploy).delegatecall(
            abi.encode(Deploy.run.selector)
        );
        require(success, 'Could not deploy!');
        contracts = abi.decode(result, (Deploy.Contracts));

        vm.startPrank(governance);
        contracts.lensHub.whitelistCollectModule(address(contracts.feeCollectModule), true);
        contracts.lensHub.whitelistCollectModule(address(contracts.limitedFeeCollectModule), true);
        contracts.lensHub.whitelistCollectModule(address(contracts.timedFeeCollectModule), true);
        contracts.lensHub.whitelistCollectModule(
            address(contracts.limitedTimedFeeCollectModule),
            true
        );
        contracts.lensHub.whitelistCollectModule(address(contracts.revertCollectModule), true);
        contracts.lensHub.whitelistCollectModule(address(contracts.freeCollectModule), true);

        contracts.lensHub.whitelistFollowModule(address(contracts.feeFollowModule), true);
        contracts.lensHub.whitelistFollowModule(address(contracts.profileFollowModule), true);
        contracts.lensHub.whitelistFollowModule(address(contracts.revertFollowModule), true);

        contracts.lensHub.whitelistReferenceModule(
            address(contracts.followerOnlyReferenceModule),
            true
        );

        contracts.moduleGlobals.whitelistCurrency(address(contracts.currency), true);

        contracts.lensHub.whitelistProfileCreator(address(contracts.profileCreationProxy), true);
        contracts.lensHub.whitelistProfileCreator(user, true);

        contracts.lensHub.setState(DataTypes.ProtocolState.Unpaused);

        vm.stopPrank();
    }
}
