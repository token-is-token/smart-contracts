// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IShareToken} from "../interfaces/IShareToken.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title ShareToken
 * @notice Upgradeable ERC20 token for LLM Share Network.
 * @dev Uses Transparent Proxy pattern (initializer, no constructor).
 */
contract ShareToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PermitUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    IShareToken
{
    // ============ Roles ============

    /// @notice Role allowed to mint tokens via usage.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role allowed to update minting parameters and protocol addresses.
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    /// @notice Role allowed to distribute airdrops.
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    // ============ Constants ============

    uint256 private constant _TOKENS_PER_UNIT = 1000; // rates are defined "per 1K tokens"

    uint256 private constant _PROVIDER_BPS = 8500;
    uint256 private constant _TREASURY_BPS = 1000;
    uint256 private constant _LP_BPS = 500;
    uint256 private constant _BPS_DENOMINATOR = 10000;

    uint256 private constant _MAX_RATE_CHANGE_BPS = 2000; // max 20% change per update

    // ============ Storage ============

    /// @notice Treasury address receiving 10% of minted tokens.
    address public treasury;

    /// @notice Liquidity pool address receiving 5% of minted tokens.
    address public liquidityPool;

    /// @dev Per-model minting rates, expressed as ShareTokens per 1K model tokens consumed.
    mapping(string model => uint256 rate) private _mintingRates;

    /// @dev Total airdropped amount received by a user.
    mapping(address user => uint256 totalReceived) private _airdropReceived;

    // ============ Initializer ============

    /**
     * @notice Initialize the token (Transparent Proxy pattern).
     * @param name_ ERC20 name.
     * @param symbol_ ERC20 symbol.
     * @param admin_ Address receiving DEFAULT_ADMIN_ROLE and initial protocol roles.
     * @param treasury_ Treasury address.
     * @param liquidityPool_ Liquidity pool address.
     */
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin_,
        address treasury_,
        address liquidityPool_
    ) external virtual initializer {
        require(admin_ != address(0), "ShareToken: admin=0");
        require(treasury_ != address(0), "ShareToken: treasury=0");
        require(liquidityPool_ != address(0), "ShareToken: lp=0");

        __ERC20_init(name_, symbol_);
        __ERC20Burnable_init();
        __ERC20Permit_init(name_);
        __AccessControl_init();
        __ReentrancyGuard_init();

        treasury = treasury_;
        liquidityPool = liquidityPool_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GOVERNANCE_ROLE, admin_);
        _grantRole(MINTER_ROLE, admin_);
        _grantRole(AIRDROP_ROLE, admin_);

        // Initial minting rates (per 1K tokens)
        _mintingRates["claude-3-opus"] = 1000;
        _mintingRates["claude-3-sonnet"] = 500;
        _mintingRates["gpt-4-turbo"] = 800;
        _mintingRates["gpt-3.5-turbo"] = 100;
        _mintingRates["seedance-2.0"] = 10000;
    }

    // ============ Minting ============

    /**
     * @inheritdoc IShareToken
     */
    function mintByUsage(
        string calldata model,
        uint256 tokenConsumed,
        address provider
    ) external override onlyRole(MINTER_ROLE) nonReentrant {
        require(provider != address(0), "ShareToken: provider=0");

        uint256 rate = _mintingRates[model];
        require(rate > 0, "ShareToken: rate=0");
        require(tokenConsumed > 0, "ShareToken: consumed=0");

        // amount = tokenConsumed * rate / 1000
        uint256 amount = (tokenConsumed * rate) / _TOKENS_PER_UNIT;
        require(amount > 0, "ShareToken: amount=0");

        address treasury_ = treasury;
        address lp_ = liquidityPool;
        require(treasury_ != address(0), "ShareToken: treasury=0");
        require(lp_ != address(0), "ShareToken: lp=0");

        uint256 treasuryAmount = (amount * _TREASURY_BPS) / _BPS_DENOMINATOR;
        uint256 lpAmount = (amount * _LP_BPS) / _BPS_DENOMINATOR;
        uint256 providerAmount = amount - treasuryAmount - lpAmount;

        _mint(provider, providerAmount);
        _mint(treasury_, treasuryAmount);
        _mint(lp_, lpAmount);

        emit TokensMinted(model, tokenConsumed, amount, provider, block.timestamp);
    }

    // ============ Airdrop ============

    /**
     * @inheritdoc IShareToken
     */
    function batchAirdrop(
        address[] calldata recipients,
        uint256[] calldata amounts,
        string calldata reason
    ) external override onlyRole(AIRDROP_ROLE) nonReentrant {
        require(recipients.length == amounts.length, "ShareToken: length");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            require(recipient != address(0), "ShareToken: recipient=0");
            require(amount > 0, "ShareToken: amount=0");

            _airdropReceived[recipient] += amount;
            _mint(recipient, amount);

            emit AirdropDistributed(recipient, amount, reason);
        }
    }

    // ============ Governance ============

    /**
     * @inheritdoc IShareToken
     */
    function updateMintingRate(string calldata model, uint256 newRate)
        external
        override
        onlyRole(GOVERNANCE_ROLE)
    {
        require(newRate > 0, "ShareToken: newRate=0");

        uint256 oldRate = _mintingRates[model];

        // If rate already set, enforce max ±20% change per update.
        if (oldRate > 0) {
            uint256 maxDelta = (oldRate * _MAX_RATE_CHANGE_BPS) / _BPS_DENOMINATOR;
            uint256 lower = oldRate - maxDelta;
            uint256 upper = oldRate + maxDelta;
            require(newRate >= lower && newRate <= upper, "ShareToken: delta>20%");
        }

        _mintingRates[model] = newRate;
        emit MintingRateUpdated(model, oldRate, newRate);
    }

    /**
     * @notice Update treasury address.
     * @dev Restricted to GOVERNANCE_ROLE.
     */
    function updateTreasury(address newTreasury) external onlyRole(GOVERNANCE_ROLE) {
        require(newTreasury != address(0), "ShareToken: treasury=0");
        treasury = newTreasury;
    }

    /**
     * @notice Update liquidity pool address.
     * @dev Restricted to GOVERNANCE_ROLE.
     */
    function updateLiquidityPool(address newLiquidityPool) external onlyRole(GOVERNANCE_ROLE) {
        require(newLiquidityPool != address(0), "ShareToken: lp=0");
        liquidityPool = newLiquidityPool;
    }

    // ============ Views ============

    /**
     * @inheritdoc IShareToken
     */
    function getMintingRate(string calldata model) external view override returns (uint256) {
        return _mintingRates[model];
    }

    /**
     * @inheritdoc IShareToken
     */
    function getAirdropHistory(address user) external view override returns (uint256) {
        return _airdropReceived[user];
    }

    // ============ ERC165 ============

    /**
     * @dev AccessControlUpgradeable implements ERC165.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IShareToken).interfaceId || super.supportsInterface(interfaceId);
    }

    uint256[46] private __gap;
}
