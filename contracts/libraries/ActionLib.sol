// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';
import {IPublicationActionModule} from 'contracts/interfaces/IPublicationActionModule.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';

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

        address actionModuleAddress = publicationActionParams.actionModuleAddress;
        uint256 actionModuleId = StorageLib.actionModuleWhitelistData()[actionModuleAddress].id;

        if (!_isActionEnabled(_actedOnPublication, actionModuleId)) {
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

        bytes memory actionModuleReturnData = IPublicationActionModule(actionModuleAddress).processPublicationAction(
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

    function _isActionEnabled(Types.Publication storage _publication, uint256 actionModuleId)
        private
        view
        returns (bool)
    {
        if (actionModuleId == 0) {
            return false;
        }
        uint256 actionModuleIdBitmapMask = 1 << (actionModuleId - 1);
        return actionModuleIdBitmapMask & _publication.enabledActionModulesBitmap != 0;
    }
}
