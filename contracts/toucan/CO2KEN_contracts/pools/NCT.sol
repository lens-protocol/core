// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import './../IToucanContractRegistry.sol';
import './../ICarbonOffsetBatches.sol';
import './../ToucanCarbonOffsets.sol';
import './NCTStorage.sol';

/// @notice Nature Carbon Tonne (or NatureCarbonTonne)
/// Contract is an ERC20 compliant token that acts as a pool for TCO2 tokens
contract NatureCarbonTonne is
    ContextUpgradeable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    NatureCarbonTonneStorage
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ----------------------------------------
    //      Constants
    // ----------------------------------------

    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant SEEDER_ROLE = keccak256('SEEDER_ROLE');
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    /// @dev fees redeem percentage with 2 fixed decimals precision
    uint256 public constant feeRedeemDivider = 1e4;

    // ----------------------------------------
    //      Events
    // ----------------------------------------

    event Deposited(address erc20Addr, uint256 amount);
    event Redeemed(address account, address erc20, uint256 amount);
    event ExternalAddressWhitelisted(address erc20addr);
    event ExternalAddressRemovedFromWhitelist(address erc20addr);
    event InternalAddressWhitelisted(address erc20addr);
    event InternalAddressBlacklisted(address erc20addr);
    event InternalAddressRemovedFromBlackList(address erc20addr);
    event InternalAddressRemovedFromWhitelist(address erc20addr);
    event AttributeStandardAdded(string standard);
    event AttributeStandardRemoved(string standard);
    event AttributeMethodologyAdded(string methodology);
    event AttributeMethodologyRemoved(string methodology);
    event AttributeRegionAdded(string region);
    event AttributeRegionRemoved(string region);
    event RedeemFeePaid(address redeemeer, uint256 fees);
    event RedeemFeeBurnt(address redeemer, uint256 fees);

    // ----------------------------------------
    //      Upgradable related functions
    // ----------------------------------------

    function initialize(
        uint64 _minimumVintageStartTime,
        address _feeRedeemReceiver,
        uint256 _feeRedeemPercentageInBase,
        address _feeRedeemBurnAddress,
        uint256 _feeRedeemBurnPercentageInBase
    ) public virtual initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained('Toucan Protocol: Nature Carbon Tonne', 'NCT');
        setMinimumVintageStartTime(_minimumVintageStartTime);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        seedMode = true;
        setFeeRedeemReceiver(_feeRedeemReceiver);
        setFeeRedeemPercentage(_feeRedeemPercentageInBase);
        setFeeRedeemBurnAddress(_feeRedeemBurnAddress);
        setFeeRedeemBurnPercentage(_feeRedeemBurnPercentageInBase);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    // ------------------------
    //      Admin functions
    // ------------------------

    /// @notice Dis-allow deposits by accounts w/o the Seeder role, which will add AMM liquidity
    /// the modifier only checks this as long as the seedMode is active
    modifier onlyPoolSeeders() {
        if (seedMode) {
            require(
                hasRole(SEEDER_ROLE, msg.sender) || owner() == msg.sender,
                'Not a pool seeder'
            );
        }
        _;
    }

    /// @notice The function irreversibly disables the seedMode after which deposits are open publicly
    function disableSeedMode() external onlyOwner {
        seedMode = false;
    }

    /// @dev Modifier that only lets the contract's owner and granted pausers pause the system
    modifier onlyPausers() {
        require(
            hasRole(PAUSER_ROLE, msg.sender) || owner() == msg.sender,
            'Caller not authorized'
        );
        _;
    }

    /// @dev Modifier that's restricting access to contract's owner and granted managers
    modifier onlyManagers() {
        require(
            hasRole(MANAGER_ROLE, msg.sender) || owner() == msg.sender,
            'Caller not authorized'
        );
        _;
    }

    /// @notice Emergency function to disable contract's core functionality
    /// @dev wraps _pause(), only Admin
    function pause() public virtual onlyPausers {
        _pause();
    }

    /// @dev Unpause the system, wraps _unpause(), only Admin
    function unpause() public virtual onlyPausers {
        _unpause();
    }

    function setToucanContractRegistry(address _address)
        public
        virtual
        onlyOwner
    {
        contractRegistry = _address;
    }

    /// @notice Generic function to switch attributes mappings into either
    /// acceptance or rejection criteria
    /// @param _mappingName attribute mapping of project-vintage data
    /// @param accepted determines if mapping works as black or whitelist
    function switchMapping(string memory _mappingName, bool accepted)
        public
        virtual
        onlyOwner
    {
        if (strcmp(_mappingName, 'regions')) {
            accepted
                ? regionsIsAcceptedMapping = true
                : regionsIsAcceptedMapping = false;
        } else if (strcmp(_mappingName, 'standards')) {
            accepted
                ? standardsIsAcceptedMapping = true
                : standardsIsAcceptedMapping = false;
        } else if (strcmp(_mappingName, 'methodologies')) {
            accepted
                ? methodologiesIsAcceptedMapping = true
                : methodologiesIsAcceptedMapping = false;
        }
    }

    /// @notice Function to add attributes for filtering (does not support complex AttributeSets)
    /// @param addToList determines whether attribute should be added or removed
    /// Other params are arrays of attributes to be added
    function addAttributes(
        bool addToList,
        string[] memory _regions,
        string[] memory _standards,
        string[] memory _methodologies
    ) public virtual onlyOwner {
        uint256 standardsLen = _standards.length;
        if (standardsLen > 0) {
            for (uint256 i = 0; i < standardsLen; i++) {
                if (addToList == true) {
                    standards[_standards[i]] = true;
                    emit AttributeStandardAdded(_standards[i]);
                } else {
                    standards[_standards[i]] = false;
                    emit AttributeStandardRemoved(_standards[i]);
                }
            }
        }

        uint256 methodologiesLen = _methodologies.length;
        if (methodologiesLen > 0) {
            for (uint256 i = 0; i < methodologiesLen; i++) {
                if (addToList == true) {
                    methodologies[_methodologies[i]] = true;
                    emit AttributeMethodologyAdded(_methodologies[i]);
                } else {
                    methodologies[_methodologies[i]] = false;
                    emit AttributeMethodologyRemoved(_methodologies[i]);
                }
            }
        }

        uint256 regionsLen = _regions.length;
        if (regionsLen > 0) {
            for (uint256 i = 0; i < regionsLen; i++) {
                if (addToList == true) {
                    regions[_regions[i]] = true;
                    emit AttributeRegionAdded(_regions[i]);
                } else {
                    regions[_regions[i]] = false;
                    emit AttributeRegionRemoved(_regions[i]);
                }
            }
        }
    }

    /// @notice Function to whitelist selected external non-TCO2 contracts by their address
    /// @param erc20Addr accepts an array of contract addresses
    function addToExternalWhiteList(address[] memory erc20Addr)
        public
        onlyOwner
    {
        uint256 addrLen = erc20Addr.length;

        for (uint256 i = 0; i < addrLen; i++) {
            externalWhiteList[erc20Addr[i]] = true;
            emit ExternalAddressWhitelisted(erc20Addr[i]);
        }
    }

    /// @notice Function to whitelist certain TCO2 contracts by their address
    /// @param erc20Addr accepts an array of contract addresses
    function addToInternalWhiteList(address[] memory erc20Addr)
        public
        onlyOwner
    {
        uint256 addrLen = erc20Addr.length;

        for (uint256 i = 0; i < addrLen; i++) {
            internalWhiteList[erc20Addr[i]] = true;
            emit InternalAddressWhitelisted(erc20Addr[i]);
        }
    }

    /// @notice Function to blacklist certain TCO2 contracts by their address
    /// @param erc20Addr accepts an array of contract addresses
    function addToInternalBlackList(address[] memory erc20Addr)
        public
        onlyOwner
    {
        uint256 addrLen = erc20Addr.length;

        for (uint256 i = 0; i < addrLen; i++) {
            internalBlackList[erc20Addr[i]] = true;
            emit InternalAddressBlacklisted(erc20Addr[i]);
        }
    }

    /// @notice Function to remove ERC20 addresses from external whitelist
    /// @param erc20Addr accepts an array of contract addresses
    function removeFromExternalWhiteList(address[] memory erc20Addr)
        public
        onlyOwner
    {
        uint256 addrLen = erc20Addr.length;

        for (uint256 i = 0; i < addrLen; i++) {
            externalWhiteList[erc20Addr[i]] = false;
            emit ExternalAddressRemovedFromWhitelist(erc20Addr[i]);
        }
    }

    /// @notice Function to remove TCO2 addresses from internal blacklist
    /// @param erc20Addr accepts an array of contract addresses
    function removeFromInternalBlackList(address[] memory erc20Addr)
        public
        onlyOwner
    {
        uint256 addrLen = erc20Addr.length;

        for (uint256 i = 0; i < addrLen; i++) {
            internalBlackList[erc20Addr[i]] = false;
            emit InternalAddressRemovedFromBlackList(erc20Addr[i]);
        }
    }

    /// @notice Function to remove TCO2 addresses from internal whitelist
    /// @param erc20Addr accepts an array of contract addressesc
    function removeFromInternalWhiteList(address[] memory erc20Addr)
        public
        onlyOwner
    {
        uint256 addrLen = erc20Addr.length;

        for (uint256 i = 0; i < addrLen; i++) {
            internalWhiteList[erc20Addr[i]] = false;
            emit InternalAddressRemovedFromWhitelist(erc20Addr[i]);
        }
    }

    /// @notice Function to limit the maximum NCT supply
    /// @dev supplyCap is initially set to 0 and must be increased before deposits
    function setSupplyCap(uint256 newCap) external virtual onlyOwner {
        supplyCap = newCap;
    }

    /// @notice Determines the minimum vintage start time acceptance criteria of TCO2s
    /// @param _minimumVintageStartTime unix time format
    function setMinimumVintageStartTime(uint64 _minimumVintageStartTime)
        public
        virtual
        onlyOwner
    {
        minimumVintageStartTime = _minimumVintageStartTime;
    }

    /// @notice Allows owner to pass an array to hold TCO2 contract addesses that are
    /// ordered by some form of scoring mechanism
    /// @param tco2s array of ordered TCO2 addresses
    function setTCO2Scoring(address[] calldata tco2s) external onlyManagers {
        require(tco2s.length > 0, 'TCO2 Array is empty');
        scoredTCO2s = tco2s;
    }

    // ----------------------------
    //   Permissionless functions
    // ----------------------------

    /// @notice Deposit function for NCT pool that accepts TCO2s and mints NCT 1:1
    /// @param erc20Addr ERC20 contract address to be deposited, requires approve
    /// @dev Eligibility is checked via `checkEligible`, balances are tracked
    /// for each TCO2 separately
    function deposit(address erc20Addr, uint256 amount)
        public
        virtual
        whenNotPaused
        onlyPoolSeeders
    {
        require(checkEligible(erc20Addr));

        uint256 remainingSpace = getRemaining();
        require(remainingSpace > 0, 'Pool is full');

        if (amount > remainingSpace) amount = remainingSpace;

        IERC20Upgradeable(erc20Addr).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        /// @dev Increase balance sheet of individual token
        tokenBalances[erc20Addr] += amount;
        _mint(msg.sender, amount);
        emit Deposited(erc20Addr, amount);
    }

    /// @notice Internal function that checks if token to be deposited is eligible for this pool
    function checkEligible(address erc20Addr)
        internal
        view
        virtual
        returns (bool)
    {
        bool isToucanContract = IToucanContractRegistry(contractRegistry)
            .checkERC20(erc20Addr);

        if (isToucanContract) {
            if (internalWhiteList[erc20Addr]) {
                return true;
            }

            require(internalBlackList[erc20Addr] == false, 'TCO2 blacklisted');

            require(checkAttributeMatching(erc20Addr) == true);
        }
        /// @dev If not Toucan native contract, check if address is whitelisted
        else {
            require(
                externalWhiteList[erc20Addr] == true,
                'External contract not whitelisted'
            );
            return true;
        }

        return true;
    }

    /// @notice Checks whether incoming TCO2s match the accepted criteria/attributes
    function checkAttributeMatching(address erc20Addr)
        public
        view
        virtual
        returns (bool)
    {
        ProjectData memory projectData;
        VintageData memory vintageData;
        (projectData, vintageData) = ToucanCarbonOffsets(erc20Addr)
            .getAttributes();

        /// @dev checks if any one of the attributes are blacklisted.
        /// If mappings are set to "whitelist"-mode, require the opposite
        require(
            vintageData.startTime >= minimumVintageStartTime,
            'StartTime too old'
        );
        require(
            regions[projectData.region] == regionsIsAcceptedMapping,
            'Region not accepted'
        );
        require(
            standards[projectData.standard] == standardsIsAcceptedMapping,
            'Standard not accepted'
        );
        require(
            methodologies[projectData.methodology] ==
                methodologiesIsAcceptedMapping,
            'Methodology not accepted'
        );

        return true;
    }

    /// @notice Update the fee redeem percentage
    /// @param _feeRedeemPercentageInBase percentage of fee in base
    function setFeeRedeemPercentage(uint256 _feeRedeemPercentageInBase)
        public
        virtual
        onlyOwner
    {
        require(
            _feeRedeemPercentageInBase < feeRedeemDivider,
            'Requires feeRedeemPercentage < divider'
        );
        feeRedeemPercentageInBase = _feeRedeemPercentageInBase;
    }

    /// @notice Update the fee redeem receiver
    /// @param _feeRedeemReceiver address to transfer the fees
    function setFeeRedeemReceiver(address _feeRedeemReceiver)
        public
        virtual
        onlyOwner
    {
        require(
            _feeRedeemReceiver != address(0),
            'Fee redeem receiver invalid'
        );
        feeRedeemReceiver = _feeRedeemReceiver;
    }

    /// @notice Update the fee redeem burn percentage
    /// @param _feeRedeemBurnPercentageInBase percentage of fee in base
    function setFeeRedeemBurnPercentage(uint256 _feeRedeemBurnPercentageInBase)
        public
        virtual
        onlyOwner
    {
        require(
            _feeRedeemBurnPercentageInBase < feeRedeemDivider,
            'Invalid burn percentage'
        );
        feeRedeemBurnPercentageInBase = _feeRedeemBurnPercentageInBase;
    }

    /// @notice Update the fee redeem burn address
    /// @param _feeRedeemBurnAddress address to transfer the fees to burn
    function setFeeRedeemBurnAddress(address _feeRedeemBurnAddress)
        public
        virtual
        onlyOwner
    {
        require(_feeRedeemBurnAddress != address(0), 'Invalid burn address');
        feeRedeemBurnAddress = _feeRedeemBurnAddress;
    }

    /// @notice View function to calculate fees pre-execution
    /// @dev User specifies in front-end the addresses and amounts they want
    /// @param tco2s Array of TCO2 contract addresses
    /// @param amounts Array of amounts to redeem for each tco2s
    /// @return Total fees amount
    function calculateRedeemFees(
        address[] memory tco2s,
        uint256[] memory amounts
    ) public view virtual whenNotPaused returns (uint256) {
        uint256 addrLen = tco2s.length;
        uint256 amountsLen = amounts.length;
        uint256 totalFee = 0;
        require(addrLen == amountsLen, 'Length of arrays differ');

        for (uint256 i = 0; i < addrLen; i++) {
            uint256 feeAmount = calculateFeeForSingleAmount(
                amounts[i],
                feeRedeemPercentageInBase
            );
            totalFee += feeAmount;
        }
        return totalFee;
    }

    /// @notice Redeems Pool tokens for multiple underlying TCO2s 1:1 minus fees
    /// @dev User specifies in front-end the addresses and amounts they want
    /// @param tco2s Array of TCO2 contract addresses
    /// @param amounts Array of amounts to redeem for each tco2s
    /// NCT Pool token in user's wallet get burned
    function redeemMany(address[] memory tco2s, uint256[] memory amounts)
        public
        virtual
        whenNotPaused
    {
        uint256 addrLen = tco2s.length;
        uint256 amountsLen = amounts.length;
        uint256 totalFee = 0;
        require(addrLen == amountsLen, 'Length of arrays differ');
        uint256 _feeRedeemPercentageInBase = feeRedeemPercentageInBase;
        for (uint256 i = 0; i < addrLen; i++) {
            uint256 feeAmount = 0;
            feeAmount = calculateFeeForSingleAmount(
                amounts[i],
                _feeRedeemPercentageInBase
            );
            totalFee += feeAmount;
            redeemSingle(msg.sender, tco2s[i], amounts[i] - feeAmount);
        }
        if (totalFee != 0) {
            uint256 burnAmount = calculateRedeemFeeBurnAmount(
                totalFee,
                feeRedeemBurnPercentageInBase
            );
            totalFee -= burnAmount;
            transfer(feeRedeemReceiver, totalFee);
            emit RedeemFeePaid(msg.sender, totalFee);
            if (burnAmount > 0) {
                transfer(feeRedeemBurnAddress, burnAmount);
                emit RedeemFeeBurnt(msg.sender, burnAmount);
            }
        }
    }

    function calculateRedeemFeeBurnAmount(
        uint256 _totalFee,
        uint256 feeRedeemBurnBp
    ) internal pure returns (uint256 _burnAmount) {
        return (_totalFee * feeRedeemBurnBp) / feeRedeemDivider;
    }

    function calculateFeeForSingleAmount(uint256 _amount, uint256 feeRedeemBp)
        internal
        pure
        returns (uint256 _fees)
    {
        if (feeRedeemBp == 0) {
            return 0;
        }
        _fees = (_amount * feeRedeemBp) / feeRedeemDivider;
    }

    /// @notice Automatically redeems an amount of Pool tokens for underlying
    /// TCO2s from an array of ranked TCO2 contracts
    /// starting from contract at index 0 until amount is satisfied
    /// @param amount Total amount to be redeemed
    /// @dev NCT Pool tokens in user's wallet get burned
    function redeemAuto(uint256 amount) public virtual whenNotPaused {
        require(amount <= totalSupply(), 'Amount exceeds totalSupply');
        uint256 remainingAmount = amount;
        uint256 i = 0;

        uint256 scoredTCO2Len = scoredTCO2s.length;
        while (remainingAmount > 0 && i < scoredTCO2Len) {
            address tco2 = scoredTCO2s[i];
            uint256 balance = tokenBalances[tco2];
            uint256 amountToRedeem = remainingAmount > balance
                ? balance
                : remainingAmount;
            redeemSingle(msg.sender, tco2, amountToRedeem);
            remainingAmount -= amountToRedeem;
            i += 1;
        }

        require(
            remainingAmount == 0,
            'Amount exceeds balance of TCO2s in array'
        );
    }

    /// @dev Internal function that redeems a single underlying token
    function redeemSingle(
        address account,
        address erc20,
        uint256 amount
    ) internal virtual whenNotPaused {
        require(msg.sender == account, 'Only own funds can be redeemed');
        require(tokenBalances[erc20] >= amount, 'Amount exceeds supply');
        _burn(account, amount);
        tokenBalances[erc20] -= amount;
        IERC20Upgradeable(erc20).safeTransfer(account, amount);
        emit Redeemed(account, erc20, amount);
    }

    /// @dev Implemented in order to disable transfers when paused
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), 'Transfers are paused');
    }

    /// @dev Returns the remaining space in pool before hitting the cap
    function getRemaining() public view returns (uint256) {
        return (supplyCap - totalSupply());
    }

    // -----------------------------
    //      Locked ERC20 safety
    // -----------------------------

    /// @dev Modifier to disallowing sending tokens to either the 0-address
    /// or this contract itself
    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        validDestination(recipient)
        returns (bool)
    {
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override validDestination(recipient) returns (bool) {
        super.transferFrom(sender, recipient, amount);
        return true;
    }

    // -----------------------------
    //      Helper Functions
    // -----------------------------
    function memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return memcmp(bytes(a), bytes(b));
    }

    function getScoredTCO2s() public view returns (address[] memory) {
        return scoredTCO2s;
    }
}
