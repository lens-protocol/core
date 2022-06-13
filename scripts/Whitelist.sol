// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ModuleGlobals} from '../contracts/core/modules/ModuleGlobals.sol';
import {LensHub} from '../contracts/core/LensHub.sol';
import {FollowNFT} from '../contracts/core/FollowNFT.sol';
import {CollectNFT} from '../contracts/core/CollectNFT.sol';

import {TransparentUpgradeableProxy} from '../contracts/upgradeability/TransparentUpgradeableProxy.sol';

import {FeeCollectModule} from '../contracts/core/modules/collect/FeeCollectModule.sol';
import {LimitedFeeCollectModule} from '../contracts/core/modules/collect/LimitedFeeCollectModule.sol';
import {TimedFeeCollectModule} from '../contracts/core/modules/collect/TimedFeeCollectModule.sol';
import {LimitedTimedFeeCollectModule} from '../contracts/core/modules/collect/LimitedTimedFeeCollectModule.sol';
import {RevertCollectModule} from '../contracts/core/modules/collect/RevertCollectModule.sol';
import {FreeCollectModule} from '../contracts/core/modules/collect/FreeCollectModule.sol';

import {FeeFollowModule} from '../contracts/core/modules/follow/FeeFollowModule.sol';
import {ProfileFollowModule} from '../contracts/core/modules/follow/ProfileFollowModule.sol';
import {RevertFollowModule} from '../contracts/core/modules/follow/RevertFollowModule.sol';

import {FollowerOnlyReferenceModule} from '../contracts/core/modules/reference/FollowerOnlyReferenceModule.sol';

import {LensPeriphery} from '../contracts/misc/LensPeriphery.sol';
import {UIDataProvider} from '../contracts/misc/UIDataProvider.sol';
import {ProfileCreationProxy} from '../contracts/misc/ProfileCreationProxy.sol';

import {Currency} from '../contracts/mocks/Currency.sol';

import {DataTypes} from '../contracts/libraries/DataTypes.sol';

import {ScriptTypes} from './ScriptTypes.sol';

import 'forge-std/Script.sol';

contract Whitelist is Script {
    function run(ScriptTypes.Contracts calldata contracts) external {
        vm.startBroadcast(msg.sender);

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

        contracts.lensHub.setState(DataTypes.ProtocolState.Unpaused);

        vm.stopBroadcast();
    }
}
