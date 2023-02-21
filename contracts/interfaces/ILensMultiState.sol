pragma solidity 0.8.15;

import {Types} from '../libraries/constants/Types.sol';

interface ILensMultiState {
    function getState() external view returns (Types.ProtocolState);
}
