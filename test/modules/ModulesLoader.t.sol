// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import {CollectPublicationAction} from 'contracts/modules/act/collect/CollectPublicationAction.sol';
import {CollectNFT} from 'contracts/modules/act/collect/CollectNFT.sol';
import {ForkManagement} from 'test/helpers/ForkManagement.sol';
import {LensHub} from 'contracts/LensHub.sol';
import {ModuleGlobals} from 'contracts/misc/ModuleGlobals.sol';
import {FeeFollowModule} from 'contracts/modules/follow/FeeFollowModule.sol';
import {RevertFollowModule} from 'contracts/modules/follow/RevertFollowModule.sol';
import {DegreesOfSeparationReferenceModule} from 'contracts/modules/reference/DegreesOfSeparationReferenceModule.sol';
import {FollowerOnlyReferenceModule} from 'contracts/modules/reference/FollowerOnlyReferenceModule.sol';
import {TokenGatedReferenceModule} from 'contracts/modules/reference/TokenGatedReferenceModule.sol';

contract ModulesLoader is Test, ForkManagement {
    using stdJson for string;

    function loadOrDeploy_CollectPublicationAction() internal returns (address, address) {
        address collectNFTImpl;
        CollectPublicationAction collectPublicationAction;

        // Deploy CollectPublicationAction
        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.CollectNFTImpl')))) {
            collectNFTImpl = json.readAddress(string(abi.encodePacked('.', forkEnv, '.CollectNFTImpl')));
            console.log('Found CollectNFTImpl deployed at:', address(collectNFTImpl));
        }

        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.CollectPublicationAction')))) {
            collectPublicationAction = CollectPublicationAction(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.CollectPublicationAction')))
            );
            console.log('Found collectPublicationAction deployed at:', address(collectPublicationAction));
        }

        // Both deployed - need to verify if they are linked
        if (collectNFTImpl != address(0) && address(collectPublicationAction) != address(0)) {
            if (CollectNFT(collectNFTImpl).ACTION_MODULE() == address(collectPublicationAction)) {
                console.log('CollectNFTImpl and CollectPublicationAction already deployed and linked');
                return (collectNFTImpl, address(collectPublicationAction));
            }
        }

        uint256 deployerNonce = vm.getNonce(deployer);

        address predictedCollectPublicationAction = computeCreateAddress(deployer, deployerNonce);
        address predictedCollectNFTImpl = computeCreateAddress(deployer, deployerNonce + 1);

        vm.startPrank(deployer);
        collectPublicationAction = new CollectPublicationAction(
            address(hub),
            predictedCollectNFTImpl,
            address(moduleGlobals)
        );
        collectNFTImpl = address(new CollectNFT(address(hub), address(collectPublicationAction)));
        vm.stopPrank();

        assertEq(
            address(collectPublicationAction),
            predictedCollectPublicationAction,
            'CollectPublicationAction deployed address mismatch'
        );
        assertEq(collectNFTImpl, predictedCollectNFTImpl, 'CollectNFTImpl deployed address mismatch');

        vm.label(address(collectPublicationAction), 'CollectPublicationAction');
        vm.label(collectNFTImpl, 'CollectNFTImpl');

        return (collectNFTImpl, address(collectPublicationAction));
    }

    // function loadOrDeploy_SeaDropMintPublicationAction() internal returns (address) {}

    function loadOrDeploy_FeeFollowModule() internal returns (address) {
        address feeFollowModule;
        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.FeeFollowModule')))) {
            feeFollowModule = json.readAddress(string(abi.encodePacked('.', forkEnv, '.FeeFollowModule')));
            console.log('Testing against already deployed module at:', feeFollowModule);
        } else {
            vm.prank(deployer);
            feeFollowModule = address(new FeeFollowModule(address(hub), address(moduleGlobals)));
        }
        return feeFollowModule;
    }

    function loadOrDeploy_RevertFollowModule() internal returns (address) {
        address revertFollowModule;
        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.RevertFollowModule')))) {
            revertFollowModule = json.readAddress(string(abi.encodePacked('.', forkEnv, '.RevertFollowModule')));
            console.log('Testing against already deployed module at:', revertFollowModule);
        } else {
            vm.prank(deployer);
            revertFollowModule = address(new RevertFollowModule());
        }
        return revertFollowModule;
    }

    function loadOrDeploy_DegreesOfSeparationReferenceModule() internal returns (address) {
        address degreesOfSeparationReferenceModule;
        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.DegreesOfSeparationReferenceModule')))) {
            degreesOfSeparationReferenceModule = json.readAddress(
                string(abi.encodePacked('.', forkEnv, '.DegreesOfSeparationReferenceModule'))
            );
            console.log('Testing against already deployed module at:', degreesOfSeparationReferenceModule);
        } else {
            vm.prank(deployer);
            degreesOfSeparationReferenceModule = address(new DegreesOfSeparationReferenceModule(hubProxyAddr));
        }
        return degreesOfSeparationReferenceModule;
    }

    function loadOrDeploy_FollowerOnlyReferenceModule() internal returns (address) {
        address followerOnlyReferenceModule;
        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.FollowerOnlyReferenceModule')))) {
            followerOnlyReferenceModule = json.readAddress(
                string(abi.encodePacked('.', forkEnv, '.FollowerOnlyReferenceModule'))
            );
            console.log('Testing against already deployed module at:', followerOnlyReferenceModule);
        } else {
            vm.prank(deployer);
            followerOnlyReferenceModule = address(new FollowerOnlyReferenceModule(hubProxyAddr));
        }
        return followerOnlyReferenceModule;
    }

    function loadOrDeploy_TokenGatedReferenceModule() internal returns (address) {
        address tokenGatedReferenceModule;
        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.TokenGatedReferenceModule')))) {
            tokenGatedReferenceModule = json.readAddress(
                string(abi.encodePacked('.', forkEnv, '.TokenGatedReferenceModule'))
            );
            console.log('Testing against already deployed module at:', tokenGatedReferenceModule);
        } else {
            vm.prank(deployer);
            tokenGatedReferenceModule = address(new TokenGatedReferenceModule(hubProxyAddr));
        }
        return tokenGatedReferenceModule;
    }
}
