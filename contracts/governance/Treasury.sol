// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Treasury is Initializable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
    bool public frozen;
    event Deposited(address indexed token, address indexed from, uint256 amount);
    event Withdrawn(address indexed token, address to, uint256 amount);
    event Frozen(bool frozen);

    function initialize(address admin) external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(GOVERNANCE_ROLE, admin);
        _grantRole(FREEZER_ROLE, admin);
    }

    function deposit(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(token, msg.sender, amount);
    }

    function withdraw(address token, address to, uint256 amount) external onlyRole(GOVERNANCE_ROLE) {
        require(!frozen, "frozen");
        IERC20(token).safeTransfer(to, amount);
        emit Withdrawn(token, to, amount);
    }

    function freeze() external onlyRole(FREEZER_ROLE) { frozen = true; emit Frozen(true); }
    function unfreeze() external onlyRole(FREEZER_ROLE) { frozen = false; emit Frozen(false); }
    function getBalance(address token) external view returns (uint256) { return IERC20(token).balanceOf(address(this)); }
}
