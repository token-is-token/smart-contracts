// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaymentSettlement} from "../interfaces/IPaymentSettlement.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract PaymentSettlement is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IPaymentSettlement {
    bytes32 public constant SETTLER_ROLE = keccak256("SETTLER_ROLE");
    bytes32 public constant DISPUTE_RESOLVER_ROLE = keccak256("DISPUTE_RESOLVER_ROLE");
    uint256 private constant BATCH_LIMIT = 100;
    mapping(bytes32 => Settlement) private _settlements;
    
    function initialize(address admin) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SETTLER_ROLE, admin);
        _grantRole(DISPUTE_RESOLVER_ROLE, admin);
    }
    
    function settleUsage(bytes32 usageHash, address consumer, address provider, uint256 amount) public onlyRole(SETTLER_ROLE) {
        require(_settlements[usageHash].usageHash == bytes32(0), "exists");
        _settlements[usageHash] = Settlement({usageHash: usageHash, consumer: consumer, provider: provider, amount: amount, timestamp: block.timestamp, status: SettlementStatus.Pending});
        emit SettlementCreated(usageHash, consumer, provider, amount);
    }
    
    function batchSettle(bytes32[] calldata usageHashes, address[] calldata consumers, address[] calldata providers, uint256[] calldata amounts) external onlyRole(SETTLER_ROLE) {
        require(usageHashes.length <= BATCH_LIMIT, "limit");
        require(usageHashes.length == consumers.length && usageHashes.length == providers.length && usageHashes.length == amounts.length, "mismatch");
        for (uint256 i = 0; i < usageHashes.length; i++) {
            settleUsage(usageHashes[i], consumers[i], providers[i], amounts[i]);
        }
    }
    
    function disputeSettlement(bytes32 usageHash, string calldata reason) external {
        Settlement storage s = _settlements[usageHash];
        require(s.usageHash != bytes32(0), "not found");
        require(s.status == SettlementStatus.Pending, "not pending");
        require(msg.sender == s.consumer || msg.sender == s.provider, "unauthorized");
        s.status = SettlementStatus.Disputed;
        emit SettlementDisputed(usageHash, reason);
    }
    
    function resolveDispute(bytes32 usageHash, SettlementStatus resolveToStatus) external onlyRole(DISPUTE_RESOLVER_ROLE) {
        Settlement storage s = _settlements[usageHash];
        require(s.usageHash != bytes32(0), "not found");
        require(s.status == SettlementStatus.Disputed, "not disputed");
        require(resolveToStatus == SettlementStatus.Confirmed || resolveToStatus == SettlementStatus.Refunded, "invalid");
        s.status = resolveToStatus;
        emit SettlementResolved(usageHash, resolveToStatus);
    }
    
    function getSettlement(bytes32 usageHash) external view returns (Settlement memory) {
        return _settlements[usageHash];
    }
}
