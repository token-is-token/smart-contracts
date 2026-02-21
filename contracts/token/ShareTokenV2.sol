// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ShareToken} from "./ShareToken.sol";

/**
 * @title ShareTokenV2
 * @notice Mock V2 for upgrade testing.
 */
contract ShareTokenV2 is ShareToken {
    uint256 public version;

    /**
     * @notice Initializer for V2.
     */
    function initializeV2(uint256 _version) external reinitializer(2) onlyRole(GOVERNANCE_ROLE) {
        version = _version;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin_,
        address treasury_,
        address liquidityPool_
    ) external override initializer {
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
    }

    function setVersion(uint256 _version) external onlyRole(GOVERNANCE_ROLE) {
        version = _version;
    }

    function getVersion() external view returns (uint256) {
        return version;
    }
}
