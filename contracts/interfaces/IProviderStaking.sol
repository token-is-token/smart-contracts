// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IProviderStaking
 * @dev Interface for the Provider Staking contract, managing provider tiers and rewards.
 */
interface IProviderStaking {
    enum Tier { Basic, Verified, Premium, Enterprise }

    struct StakeInfo {
        uint256 amount;
        Tier tier;
        uint256 stakedAt;
        uint256 lastClaimTime;
    }

    event Staked(address indexed provider, uint256 amount, Tier tier);
    event Unstaked(address indexed provider, uint256 amount);
    event RewardsClaimed(address indexed provider, uint256 amount);
    event Slashed(address indexed provider, uint256 amount, string reason);
    event TierUpdated(address indexed provider, Tier oldTier, Tier newTier);

    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function claimRewards() external;
    function slash(address provider, uint256 amount, string calldata reason) external;
    function getProviderTier(address provider) external view returns (Tier);
    function getStakeInfo(address provider) external view returns (StakeInfo memory);
}
