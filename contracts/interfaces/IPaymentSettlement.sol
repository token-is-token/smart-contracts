// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPaymentSettlement
 * @dev Interface for the PaymentSettlement contract, managing usage-based payments.
 */
interface IPaymentSettlement {
    enum SettlementStatus { Pending, Confirmed, Disputed, Refunded }

    struct Settlement {
        bytes32 usageHash;
        address consumer;
        address provider;
        uint256 amount;
        uint256 timestamp;
        SettlementStatus status;
    }

    event SettlementCreated(bytes32 indexed usageHash, address indexed consumer, address indexed provider, uint256 amount);
    event SettlementConfirmed(bytes32 indexed usageHash);
    event SettlementDisputed(bytes32 indexed usageHash, string reason);
    event SettlementResolved(bytes32 indexed usageHash, SettlementStatus finalStatus);

    function settleUsage(bytes32 usageHash, address consumer, address provider, uint256 amount) external;
    function batchSettle(bytes32[] calldata usageHashes, address[] calldata consumers, address[] calldata providers, uint256[] calldata amounts) external;
    function disputeSettlement(bytes32 usageHash, string calldata reason) external;
    function resolveDispute(bytes32 usageHash, SettlementStatus resolveToStatus) external;
    function getSettlement(bytes32 usageHash) external view returns (Settlement memory);
}
