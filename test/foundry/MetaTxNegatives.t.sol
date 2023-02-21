// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';

abstract contract MetaTxNegatives is BaseTest {
    uint256 private constant NO_DEADLINE = type(uint256).max;
    uint256 private _defaultMetaTxSignerPk;
    address private _defaultMetaTxSigner;
    uint256 private _defaultMetaTxSignerNonce;

    function setUp() public virtual override {
        _defaultMetaTxSignerPk = _getDefaultMetaTxSignerPk();
        _defaultMetaTxSigner = vm.addr(_defaultMetaTxSignerPk);
        _defaultMetaTxSignerNonce = _getMetaTxNonce(_defaultMetaTxSigner);
    }

    // Functions to mandatorily override.

    function _executeMetaTx(
        uint256 signerPk,
        uint256 nonce,
        uint256 deadline
    ) internal virtual;

    function _getDefaultMetaTxSignerPk() internal virtual returns (uint256);

    // Functions to override ONLY if the contract where to execute the MetaTx is not the LensHub.

    function _getMetaTxNonce(address signer) internal virtual returns (uint256) {
        return _getSigNonce(signer);
    }

    function _getDomainName() internal virtual returns (bytes memory) {
        return bytes('Lens Protocol Profiles');
    }

    function _getRevisionNumber() internal virtual returns (bytes memory) {
        return bytes('1');
    }

    function _getVerifyingContract() internal virtual returns (address) {
        return hubProxyAddr;
    }

    // Functions for MetaTx Negative test cases.

    function testCannotExecuteMetaTxWhenSignatureHasExpired() public {
        domainSeparator = _getValidDomainSeparator();
        uint256 expiredTimestamp = block.timestamp;
        uint256 mockTimestamp = expiredTimestamp + 69;
        vm.warp(mockTimestamp);
        vm.expectRevert(Errors.SignatureExpired.selector);
        _executeMetaTx({
            signerPk: _defaultMetaTxSignerPk,
            nonce: _defaultMetaTxSignerNonce,
            deadline: expiredTimestamp
        });
    }

    function testCannotExecuteMetaTxWhenSignatureNonceIsInvalid() public {
        domainSeparator = _getValidDomainSeparator();
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _executeMetaTx({
            signerPk: _defaultMetaTxSignerPk,
            nonce: _defaultMetaTxSignerNonce + 69,
            deadline: NO_DEADLINE
        });
    }

    function testCannotExecuteMetaTxWhenSignatureSignerIsInvalid() public {
        domainSeparator = _getValidDomainSeparator();
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _executeMetaTx({signerPk: 1234569696969, nonce: _defaultMetaTxSignerNonce, deadline: NO_DEADLINE});
    }

    function testCannotExecuteMetaTxWhenSignatureDomainWasGeneratedWithWrongRevisionNumber() public {
        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256(_getDomainName()),
                keccak256('69696969696969696969696969969696'),
                block.chainid,
                _getVerifyingContract()
            )
        );
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _executeMetaTx({signerPk: _defaultMetaTxSignerPk, nonce: _defaultMetaTxSignerNonce, deadline: NO_DEADLINE});
    }

    function testCannotExecuteMetaTxWhenSignatureDomainWasGeneratedWithWrongChainId() public {
        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256(_getDomainName()),
                keccak256(_getRevisionNumber()),
                type(uint256).max,
                _getVerifyingContract()
            )
        );
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _executeMetaTx({signerPk: _defaultMetaTxSignerPk, nonce: _defaultMetaTxSignerNonce, deadline: NO_DEADLINE});
    }

    function testCannotExecuteMetaTxWhenSignatureDomainWasGeneratedWithWrongVerifyingContract() public {
        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256(_getDomainName()),
                keccak256(_getRevisionNumber()),
                block.chainid,
                address(0x691234569696969)
            )
        );
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _executeMetaTx({signerPk: _defaultMetaTxSignerPk, nonce: _defaultMetaTxSignerNonce, deadline: NO_DEADLINE});
    }

    function testCannotExecuteMetaTxWhenSignatureDomainWasGeneratedWithWrongName() public {
        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256('This should be an invalid name :)'),
                keccak256(_getRevisionNumber()),
                block.chainid,
                _getVerifyingContract()
            )
        );
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _executeMetaTx({signerPk: _defaultMetaTxSignerPk, nonce: _defaultMetaTxSignerNonce, deadline: NO_DEADLINE});
    }

    function _getValidDomainSeparator() internal virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    Typehash.EIP712_DOMAIN,
                    keccak256(_getDomainName()),
                    keccak256(_getRevisionNumber()),
                    block.chainid,
                    _getVerifyingContract()
                )
            );
    }
}
