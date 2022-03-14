pragma solidity 0.8.10;

import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';

contract Whitelist {
    
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

    function isProfileCreatorWhitelisted(address profileCreator) external view returns(bool) {
        return _profileCreatorWhitelisted[profileCreator];
    }

    function isFollowModuleWhitelisted(address followModule) external view returns(bool) {
        return _followModuleWhitelisted[followModule];
    }

    function isCollectModuleWhitelisted(address collectModule) external view returns(bool) {
        return _collectModuleWhitelisted[collectModule];
    }

    function isReferenceModuleWhitelisted(address referenceModule) external view returns(bool) {
        return _referenceModuleWhitelisted[referenceModule];
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    function setGovernance(address newGovernance) external onlyGov {
        _setGovernance(newGovernance);
    }

    function whitelistProfileCreator(address profileCreator, bool whitelist)
        external
        onlyGov
    {
        _profileCreatorWhitelisted[profileCreator] = whitelist;
        emit Events.ProfileCreatorWhitelisted(profileCreator, whitelist, block.timestamp);
    }

    function whitelistFollowModule(address followModule, bool whitelist) external onlyGov {
        _followModuleWhitelisted[followModule] = whitelist;
        emit Events.FollowModuleWhitelisted(followModule, whitelist, block.timestamp);
    }

    function whitelistReferenceModule(address referenceModule, bool whitelist)
        external
        onlyGov
    {
        _referenceModuleWhitelisted[referenceModule] = whitelist;
        emit Events.ReferenceModuleWhitelisted(referenceModule, whitelist, block.timestamp);
    }

    function whitelistCollectModule(address collectModule, bool whitelist)
        external
        onlyGov
    {
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