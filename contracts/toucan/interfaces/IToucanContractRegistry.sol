// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

interface IToucanContractRegistry {
    function carbonOffsetBatchesAddress() external view returns (address);

    function carbonProjectsAddress() external view returns (address);

    function carbonProjectVintagesAddress() external view returns (address);

    function toucanCarbonOffsetsFactoryAddress()
        external
        view
        returns (address);

    function carbonOffsetBadgesAddress() external view returns (address);

    function checkERC20(address _address) external view returns (bool);

    function addERC20(address _address) external;
}
