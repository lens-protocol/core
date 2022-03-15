// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';
import {IWhitelist} from '../interfaces/IWhitelist.sol';

/**
 * @title Whitelist
 * @author Lens Protocol
 *
 * @notice This contract manages the whitelisting of modules(follow, collect, reference) and profile creators.
 *
 */
contract Whitelist is IWhitelist {
    address public _governance;

    mapping(address => bool) internal _profileCreatorWhitelisted;
    mapping(address => bool) internal _followModuleWhitelisted;
    mapping(address => bool) internal _collectModuleWhitelisted;
    mapping(address => bool) internal _referenceModuleWhitelisted;

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        if (msg.sender != _governance) revert Errors.NotGovernance();
        _;
    }

    constructor(address newGovernance) {
        _setGovernance(newGovernance);
    }

    /// *********************************
    /// *****EXTERNAL VIEW FUNCTIONS*****
    /// *********************************

    /// @inheritdoc IWhitelist
    function isProfileCreatorWhitelisted(address profileCreator)
        external
        view
        override
        returns (bool)
    {
        return _profileCreatorWhitelisted[profileCreator];
    }

    /// @inheritdoc IWhitelist
    function isFollowModuleWhitelisted(address followModule) external view override returns (bool) {
        return _followModuleWhitelisted[followModule];
    }

    /// @inheritdoc IWhitelist
    function isCollectModuleWhitelisted(address collectModule)
        external
        view
        override
        returns (bool)
    {
        return _collectModuleWhitelisted[collectModule];
    }

    /// @inheritdoc IWhitelist
    function isReferenceModuleWhitelisted(address referenceModule)
        external
        view
        override
        returns (bool)
    {
        return _referenceModuleWhitelisted[referenceModule];
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    /**
     * @notice Sets the privileged governance role. This function can only be called by the current governance
     * address.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external onlyGov {
        _setGovernance(newGovernance);
    }

    /**
     * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) external onlyGov {
        _profileCreatorWhitelisted[profileCreator] = whitelist;
        emit Events.ProfileCreatorWhitelisted(profileCreator, whitelist, block.timestamp);
    }

    /**
     * @notice Adds or removes a follow module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param followModule The follow module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the follow module should be whitelisted.
     */
    function whitelistFollowModule(address followModule, bool whitelist) external onlyGov {
        _followModuleWhitelisted[followModule] = whitelist;
        emit Events.FollowModuleWhitelisted(followModule, whitelist, block.timestamp);
    }

    /**
     * @notice Adds or removes a reference module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param referenceModule The reference module contract to add or remove from the whitelist.
     * @param whitelist Whether or not the reference module should be whitelisted.
     */
    function whitelistReferenceModule(address referenceModule, bool whitelist) external onlyGov {
        _referenceModuleWhitelisted[referenceModule] = whitelist;
        emit Events.ReferenceModuleWhitelisted(referenceModule, whitelist, block.timestamp);
    }

    /**
     * @notice Adds or removes a collect module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param collectModule The collect module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the collect module should be whitelisted.
     */
    function whitelistCollectModule(address collectModule, bool whitelist) external onlyGov {
        _collectModuleWhitelisted[collectModule] = whitelist;
        emit Events.CollectModuleWhitelisted(collectModule, whitelist, block.timestamp);
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.GovernanceSet(msg.sender, prevGovernance, newGovernance, block.timestamp);
    }
}
