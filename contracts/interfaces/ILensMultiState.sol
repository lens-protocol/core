pragma solidity 0.8.15;

import {DataTypes} from '../libraries/DataTypes.sol';

interface ILensMultiState {
    function getState() external view returns (DataTypes.ProtocolState);
}
