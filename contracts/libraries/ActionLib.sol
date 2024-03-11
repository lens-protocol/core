// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from './constants/Types.sol';
import {StorageLib} from './StorageLib.sol';
import {ValidationLib} from './ValidationLib.sol';
import {IPublicationActionModule} from '../interfaces/IPublicationActionModule.sol';
import {Errors} from './constants/Errors.sol';
import {Events} from './constants/Events.sol';

library ActionLib {
    function act(
        Types.PublicationActionParams calldata publicationActionParams,
        address transactionExecutor,
        address actorProfileOwner
    ) external returns (bytes memory) {
        ValidationLib.validateNotBlocked({
            profile: publicationActionParams.actorProfileId,
            byProfile: publicationActionParams.publicationActedProfileId
        });

        Types.Publication storage _actedOnPublication = StorageLib.getPublication(
            publicationActionParams.publicationActedProfileId,
            publicationActionParams.publicationActedId
        );

        if (!_isActionEnabled(_actedOnPublication, publicationActionParams.actionModuleAddress)) {
            // This will also revert for:
            //   - Non-existent action modules
            //   - Non-existent publications
            //   - Legacy V1 publications
            // Because the storage will be empty.
            revert Errors.ActionNotAllowed();
        }

        Types.PublicationType[] memory referrerPubTypes = ValidationLib.validateReferrersAndGetReferrersPubTypes(
            publicationActionParams.referrerProfileIds,
            publicationActionParams.referrerPubIds,
            publicationActionParams.publicationActedProfileId,
            publicationActionParams.publicationActedId
        );

        bytes memory actionModuleReturnData = IPublicationActionModule(publicationActionParams.actionModuleAddress)
            .processPublicationAction(
                Types.ProcessActionParams({
                    publicationActedProfileId: publicationActionParams.publicationActedProfileId,
                    publicationActedId: publicationActionParams.publicationActedId,
                    actorProfileId: publicationActionParams.actorProfileId,
                    actorProfileOwner: actorProfileOwner,
                    transactionExecutor: transactionExecutor,
                    referrerProfileIds: publicationActionParams.referrerProfileIds,
                    referrerPubIds: publicationActionParams.referrerPubIds,
                    referrerPubTypes: referrerPubTypes,
                    actionModuleData: publicationActionParams.actionModuleData
                })
            );
        emit Events.Acted(publicationActionParams, actionModuleReturnData, transactionExecutor, block.timestamp);

        return actionModuleReturnData;
    }

    function _isActionEnabled(
        Types.Publication storage _publication,
        address actionModuleAddress
    ) private view returns (bool) {
        return _publication.actionModuleEnabled[actionModuleAddress];
    }
}
