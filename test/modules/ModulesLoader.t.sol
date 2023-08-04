// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import {CollectPublicationAction} from 'contracts/modules/act/collect/CollectPublicationAction.sol';
import {CollectNFT} from 'contracts/modules/act/collect/CollectNFT.sol';
import {ForkManagement} from 'test/helpers/ForkManagement.sol';
import {LensHub} from 'contracts/LensHub.sol';
import {ModuleGlobals} from 'contracts/misc/ModuleGlobals.sol';

contract ModulesLoader is Test, ForkManagement {
    using stdJson for string;

    function loadOrDeploy_CollectPublicationAction() internal returns (address, CollectPublicationAction) {
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
                return (collectNFTImpl, collectPublicationAction);
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

        return (collectNFTImpl, collectPublicationAction);
    }

    // function loadOrDeploy_SeaDropMintPublicationAction() internal returns (address) {}

    function loadOrDeploy_FeeFollowModule() internal returns (address) {}

    function loadOrDeploy_RevertFollowModule() internal returns (address) {}

    function loadOrDeploy_DegreesOfSeparationReferenceModule() internal returns (address) {}

    function loadOrDeploy_FollowerOnlyReferenceModule() internal returns (address) {}

    function loadOrDeploy_TokenGatedReferenceModule() internal returns (address) {}
}
