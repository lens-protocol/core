// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

contract Modifiers {
    modifier onlyBy(address _contractRegistry, address _owner) {
        require(
            _contractRegistry == msg.sender || _owner == msg.sender,
            'Caller is not the registry, nor owner'
        );
        _;
    }
}
