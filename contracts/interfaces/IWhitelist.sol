// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

interface IWhitelist {
    function isProfileCreatorWhitelisted(address profileCreator) external view returns(bool);
    function isFollowModuleWhitelisted(address followModule) external view returns(bool);
    function isCollectModuleWhitelisted(address collectModule) external view returns(bool);
    function isReferenceModuleWhitelisted(address referenceModule) external view returns(bool);
}