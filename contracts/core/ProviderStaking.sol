// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IProviderStaking} from "../interfaces/IProviderStaking.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract ProviderStaking is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IProviderStaking {
    using SafeERC20 for IERC20;
    bytes32 public constant SLASHER_ROLE = keccak256("SLASHER_ROLE");
    uint256 private constant UNSTAKE_COOLDOWN = 7 days;
    uint256 private constant TIER_BASIC = 1000 * 10**18;
    uint256 private constant TIER_VERIFIED = 10000 * 10**18;
    uint256 private constant TIER_PREMIUM = 100000 * 10**18;
    uint256 private constant TIER_ENTERPRISE = 1000000 * 10**18;
    IERC20 public shareToken;
    mapping(address => StakeInfo) private _stakes;
    mapping(address => uint256) private _lastStakeTime;
    
    function initialize(address admin, address _shareToken) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SLASHER_ROLE, admin);
        shareToken = IERC20(_shareToken);
    }
    
    function _getTier(uint256 amount) internal pure returns (Tier) {
        if (amount >= TIER_ENTERPRISE) return Tier.Enterprise;
        if (amount >= TIER_PREMIUM) return Tier.Premium;
        if (amount >= TIER_VERIFIED) return Tier.Verified;
        if (amount >= TIER_BASIC) return Tier.Basic;
        return Tier.Basic;
    }
    
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "zero");
        shareToken.safeTransferFrom(msg.sender, address(this), amount);
        StakeInfo storage info = _stakes[msg.sender];
        Tier oldTier = info.tier;
        info.amount += amount;
        if (info.stakedAt == 0) info.stakedAt = block.timestamp;
        info.lastClaimTime = block.timestamp;
        info.tier = _getTier(info.amount);
        _lastStakeTime[msg.sender] = block.timestamp;
        if (oldTier != info.tier) emit TierUpdated(msg.sender, oldTier, info.tier);
        emit Staked(msg.sender, amount, info.tier);
    }
    
    function unstake(uint256 amount) external nonReentrant {
        StakeInfo storage info = _stakes[msg.sender];
        require(info.amount >= amount, "insufficient");
        require(block.timestamp >= _lastStakeTime[msg.sender] + UNSTAKE_COOLDOWN, "cooldown");
        Tier oldTier = info.tier;
        info.amount -= amount;
        info.tier = _getTier(info.amount);
        shareToken.safeTransfer(msg.sender, amount);
        if (oldTier != info.tier) emit TierUpdated(msg.sender, oldTier, info.tier);
        emit Unstaked(msg.sender, amount);
    }
    
    function claimRewards() external nonReentrant {
        StakeInfo storage info = _stakes[msg.sender];
        require(info.amount > 0, "no stake");
        uint256 duration = block.timestamp - info.lastClaimTime;
        uint256 weight = info.tier == Tier.Enterprise ? 3 : info.tier == Tier.Premium ? 2 : info.tier == Tier.Verified ? 15 : 1;
        uint256 reward = (info.amount * weight * duration) / (365 days * 10);
        info.lastClaimTime = block.timestamp;
        shareToken.safeTransfer(msg.sender, reward);
        emit RewardsClaimed(msg.sender, reward);
    }
    
    function slash(address provider, uint256 amount, string calldata reason) external onlyRole(SLASHER_ROLE) {
        StakeInfo storage info = _stakes[provider];
        require(info.amount >= amount, "insufficient");
        Tier oldTier = info.tier;
        info.amount -= amount;
        info.tier = _getTier(info.amount);
        shareToken.safeTransfer(msg.sender, amount);
        if (oldTier != info.tier) emit TierUpdated(provider, oldTier, info.tier);
        emit Slashed(provider, amount, reason);
    }
    
    function getProviderTier(address provider) external view returns (Tier) {
        return _stakes[provider].tier;
    }
    
    function getStakeInfo(address provider) external view returns (StakeInfo memory) {
        return _stakes[provider];
    }
}
