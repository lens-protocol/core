// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface ILensModule is IERC165 {
    /// @dev for now we check for keccak('LENS_MODULE');
    /// Override this and add the type(IModuleInterface).interfaceId for corresponding module type
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    /// @notice Human-readable description of the module
    // Can be JSON
    // Can be contract source code
    // Can be github link
    // Can be ipfs with documentation
    // etc
    function getModuleMetadataURI() external view returns (string memory);
}
