pragma solidity 0.8.10;

import {ILensHub} from '../interfaces/ILensHub.sol';
import {Proxy} from '@openzeppelin/contracts/proxy/Proxy.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

contract CollectNFTProxy is Proxy {
    using Address for address;
    address immutable HUB;

    constructor(bytes memory data) {
        HUB = msg.sender;
        ILensHub(msg.sender).getCollectNFTImpl().functionDelegateCall(data);
    }

    function _implementation() internal view override returns (address) {
        return ILensHub(HUB).getCollectNFTImpl();
    }
}
