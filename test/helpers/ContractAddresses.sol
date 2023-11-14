// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LegacyCollectNFT} from 'contracts/misc/LegacyCollectNFT.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {LensHub} from 'contracts/LensHub.sol';
import {MockActionModule} from 'test/mocks/MockActionModule.sol';
import {MockReferenceModule} from 'test/mocks/MockReferenceModule.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/namespaces/TokenHandleRegistry.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {ProxyAdmin} from 'contracts/misc/access/ProxyAdmin.sol';
import {ModuleRegistry} from 'contracts/misc/ModuleRegistry.sol';
import {ProfileTokenURI} from 'contracts/misc/token-uris/ProfileTokenURI.sol';
import {FollowTokenURI} from 'contracts/misc/token-uris/FollowTokenURI.sol';
import {HandleTokenURI} from 'contracts/misc/token-uris/HandleTokenURI.sol';

contract ContractAddresses {
    ////////////////////////////////// Types
    struct TestAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    struct TestPublication {
        uint256 profileId;
        uint256 pubId;
    }

    // JSON Parsing Library will sort the object fields alphabetically, that's why we need to keep this order.
    struct Module {
        address addy;
        string name;
    }

    // Avoid setUp to be run more than once.
    bool internal __setUpDone;
    uint256 internal lensVersion;

    ////////////////////////////////// Accounts
    TestAccount defaultAccount;

    ////////////////////////////////// Publications
    TestPublication defaultPub;

    ////////////////////////////////// Relevant actors' addresses
    address deployer;
    address governance; // TODO: We need to make this lensHubGovernance (maybe even a function that will return it dynamically)
    address governanceMultisig;
    address treasury;
    address proxyAdmin; // TODO: This needs to be a function that goes to lensHub and gets it.
    address proxyAdminMultisig; // TODO: and ProxyAdminMultisig - load it from addresses.json or .env

    ////////////////////////////////// Relevant values or constants
    uint16 TREASURY_FEE_BPS;
    uint16 constant TREASURY_FEE_MAX_BPS = 10000; // TODO: This should be a constant in 'contracts/libraries/constants/'
    string constant MOCK_URI = 'ipfs://QmUXfQWe43RKx31VzA2BnbwhSMW8WuaJvszFWChD59m76U';
    bytes32 domainSeparator;

    ////////////////////////////////// Deployed addresses
    address hubProxyAddr;
    LegacyCollectNFT legacyCollectNFT;
    FollowNFT followNFT;
    LensHubInitializable hubImpl;
    TransparentUpgradeableProxy hubAsProxy;
    LensHub hub;
    MockActionModule mockActionModule;
    MockReferenceModule mockReferenceModule;
    LensHandles lensHandles;
    TokenHandleRegistry tokenHandleRegistry;
    ModuleRegistry moduleRegistry;

    Governance governanceContract;
    ProxyAdmin proxyAdminContract;
    address migrationAdmin;

    ProfileTokenURI profileTokenURIContract;
    FollowTokenURI followTokenURIContract;
    HandleTokenURI handleTokenURIContract;
}
