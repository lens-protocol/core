// SPDX-License-Identifier: MIT

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {LensModule} from 'contracts/modules/LensModule.sol';

pragma solidity ^0.8.18;

contract LensModuleMetadata is LensModule, Ownable {
    string public metadataURI;

    constructor() Ownable() {}

    function setModuleMetadataURI(string memory _metadataURI) external onlyOwner {
        metadataURI = _metadataURI;
    }

    function getModuleMetadataURI() external view returns (string memory) {
        return metadataURI;
    }
}
