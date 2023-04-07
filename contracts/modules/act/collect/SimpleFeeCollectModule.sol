// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {BaseFeeCollectModule} from 'contracts/modules/act/collect/base/BaseFeeCollectModule.sol';
import {BaseFeeCollectModuleInitData, BaseProfilePublicationData} from 'contracts/modules/interfaces/IBaseFeeCollectModule.sol';
import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';

/**
 * @title SimpleFeeCollectModule
 * @author Lens Protocol
 *
 * @notice This is a simple Lens CollectModule implementation, allowing customization of time to collect,
 * number of collects and whether only followers can collect.
 *
 * You can build your own collect modules by inheriting from BaseFeeCollectModule and adding your
 * functionality along with getPublicationData function.
 */
contract SimpleFeeCollectModule is BaseFeeCollectModule {
    constructor(address hub, address moduleGlobals) BaseFeeCollectModule(hub, moduleGlobals) {}

    /**
     * @inheritdoc ICollectModule
     * @notice This collect module levies a fee on collects and supports referrals. Thus, we need to decode data.
     * @param data The arbitrary data parameter, decoded into BaseFeeCollectModuleInitData struct:
     *        amount: The collecting cost associated with this publication. 0 for free collect.
     *        collectLimit: The maximum number of collects for this publication. 0 for no limit.
     *        currency: The currency associated with this publication.
     *        referralFee: The referral fee associated with this publication.
     *        followerOnly: True if only followers of publisher may collect the post.
     *        endTimestamp: The end timestamp after which collecting is impossible. 0 for no expiry.
     *        recipient: Recipient of collect fees.
     *
     * @return An abi encoded bytes parameter, which is the same as the passed data parameter.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        address /* transactionExecutor */,
        bytes calldata data
    ) external override returns (bytes memory) {
        BaseFeeCollectModuleInitData memory baseInitData = abi.decode(data, (BaseFeeCollectModuleInitData));
        _validateBaseInitData(baseInitData);
        _storeBasePublicationCollectParameters(profileId, pubId, baseInitData);
        return data;
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param profileId The token ID of the profile mapped to the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return The BaseProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(
        uint256 profileId,
        uint256 pubId
    ) external view virtual returns (BaseProfilePublicationData memory) {
        return getBasePublicationData(profileId, pubId);
    }
}
