// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {ILensHub} from '../interfaces/ILensHub.sol';
import {DataTypes} from '../libraries/DataTypes.sol';
import {Errors} from '../libraries/Errors.sol';

error InvalidHandleSuffix();

/**
 * @title MockProfileCreationProxy
 * @author Lens Protocol
 *
 * @dev This is a proxy to allow profiles to be created from any address while adding some handle restrictions.
 */
contract MockProfileCreationProxy {
    ILensHub immutable LENS_HUB;

    address governance;
    uint256 requiredMinHandleLengthBeforeSuffix;
    string requiredHandleSuffix;
    mapping(bytes1 => bool) isCharacterInvalid;

    modifier onlyGov() {
        if (msg.sender != governance) revert Errors.NotGovernance();
        _;
    }

    constructor(
        uint256 minHandleLengthBeforeSuffix,
        string memory handleSuffix,
        string memory invalidCharacters,
        address newGovernance,
        address hub
    ) {
        requiredMinHandleLengthBeforeSuffix = minHandleLengthBeforeSuffix;
        requiredHandleSuffix = handleSuffix;
        for (uint256 i = 0; i < bytes(invalidCharacters).length; ++i) {
            isCharacterInvalid[bytes(invalidCharacters)[i]] = true;
        }
        governance = newGovernance;
        LENS_HUB = ILensHub(hub);
    }

    function proxyCreateProfile(DataTypes.CreateProfileData calldata vars) external {
        uint256 suffixLength = bytes(requiredHandleSuffix).length;
        uint256 handleLength = bytes(vars.handle).length;
        if (handleLength < requiredMinHandleLengthBeforeSuffix + suffixLength) {
            revert Errors.HandleLengthInvalid();
        }
        for (uint256 i = 0; i < handleLength - suffixLength; ++i) {
            if (isCharacterInvalid[bytes(vars.handle)[i]]) {
                revert Errors.HandleContainsInvalidCharacters();
            }
        }
        if (suffixLength > 0) {
            for (uint256 i = 0; i < suffixLength; ++i) {
                if (
                    bytes(vars.handle)[i + handleLength - suffixLength] !=
                    bytes(requiredHandleSuffix)[i]
                ) {
                    revert InvalidHandleSuffix();
                }
            }
        }
        LENS_HUB.createProfile(vars);
    }

    function setRequiredHandleSuffix(string memory handleSuffix) external onlyGov {
        requiredHandleSuffix = handleSuffix;
    }

    function setCharacterValidity(bytes1 character, bool isValid) external onlyGov {
        isCharacterInvalid[character] = !isValid;
    }

    function setRequiredMinHandleLengthBeforeSuffix(uint256 minHandleLengthBeforeSuffix)
        external
        onlyGov
    {
        requiredMinHandleLengthBeforeSuffix = minHandleLengthBeforeSuffix;
    }

    function setGovernance(address newGovernance) external onlyGov {
        governance = newGovernance;
    }
}
