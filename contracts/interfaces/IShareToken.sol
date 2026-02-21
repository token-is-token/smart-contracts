// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IShareToken
 * @dev Interface for the ShareToken contract, defining core minting, airdrop, and governance functions.
 */
interface IShareToken {
    /**
     * @dev Emitted when tokens are minted based on usage.
     * @param model The model identifier used.
     * @param tokenConsumed The amount of model tokens consumed.
     * @param amount The amount of ShareTokens minted.
     * @param provider The address of the provider.
     * @param timestamp The time the minting occurred.
     */
    event TokensMinted(string indexed model, uint256 tokenConsumed, uint256 amount, address indexed provider, uint256 timestamp);

    /**
     * @dev Emitted when the minting rate is updated for a specific model.
     * @param model The model identifier.
     * @param oldRate The previous minting rate.
     * @param newRate The new minting rate.
     */
    event MintingRateUpdated(string indexed model, uint256 oldRate, uint256 newRate);

    /**
     * @dev Emitted when an airdrop is distributed to a recipient.
     * @param recipient The address receiving the airdrop.
     * @param amount The amount of tokens distributed.
     * @param reason The reason for the airdrop.
     */
    event AirdropDistributed(address indexed recipient, uint256 amount, string reason);

    /**
     * @notice Mint tokens based on user usage.
     * @dev Restricted to MINTER_ROLE.
     * @param model The model identifier.
     * @param tokenConsumed The amount of model tokens consumed.
     * @param provider The address of the provider.
     */
    function mintByUsage(string calldata model, uint256 tokenConsumed, address provider) external;

    /**
     * @notice Batch distribute tokens to multiple recipients.
     * @dev Restricted to AIRDROP_ROLE.
     * @param recipients Array of addresses to receive tokens.
     * @param amounts Array of token amounts corresponding to each recipient.
     * @param reason The reason for the airdrop.
     */
    function batchAirdrop(address[] calldata recipients, uint256[] calldata amounts, string calldata reason) external;

    /**
     * @notice Update the minting rate for a specific model.
     * @dev Restricted to GOVERNANCE_ROLE.
     * @param model The model identifier.
     * @param newRate The new minting rate (ShareTokens per unit of model token).
     */
    function updateMintingRate(string calldata model, uint256 newRate) external;

    /**
     * @notice Get the current minting rate for a specific model.
     * @param model The model identifier.
     * @return The current minting rate.
     */
    function getMintingRate(string calldata model) external view returns (uint256);

    /**
     * @notice Get the total airdrop amount received by a user.
     * @param user The address of the user.
     * @return The total amount of tokens received via airdrops.
     */
    function getAirdropHistory(address user) external view returns (uint256);
}

