// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

struct Usage {
    bytes32 hash;
    string model;
    uint256 promptTokens;
    uint256 completionTokens;
    uint256 totalTokens;
    address consumer;
    address provider;
    uint256 timestamp;
    bool settled;
}

interface IUsageRegistry {
    event UsageRecorded(bytes32 indexed hash, string model, address indexed consumer, address indexed provider, uint256 totalTokens);
    function recordUsage(string calldata model, uint256 promptTokens, uint256 completionTokens, address consumer, address provider) external returns (bytes32);
    function getUsage(bytes32 hash) external view returns (Usage memory);
    function getConsumerUsage(address consumer, uint256 startTime, uint256 endTime) external view returns (bytes32[] memory);
}

contract UsageRegistry is Initializable, AccessControlUpgradeable, IUsageRegistry {
    bytes32 public constant RECORDER_ROLE = keccak256("RECORDER_ROLE");
    uint256 private constant MAX_RESULTS = 100;
    mapping(bytes32 => Usage) private _usages;
    mapping(address => bytes32[]) private _consumerUsages;
    uint256 private _nonce;
    
    function initialize(address admin) external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RECORDER_ROLE, admin);
    }
    
    function recordUsage(string calldata model, uint256 promptTokens, uint256 completionTokens, address consumer, address provider) external onlyRole(RECORDER_ROLE) returns (bytes32) {
        _nonce++;
        bytes32 hash = keccak256(abi.encodePacked(model, promptTokens, completionTokens, consumer, provider, block.timestamp, _nonce));
        Usage memory usage = Usage({hash: hash, model: model, promptTokens: promptTokens, completionTokens: completionTokens, totalTokens: promptTokens + completionTokens, consumer: consumer, provider: provider, timestamp: block.timestamp, settled: false});
        _usages[hash] = usage;
        _consumerUsages[consumer].push(hash);
        emit UsageRecorded(hash, model, consumer, provider, usage.totalTokens);
        return hash;
    }
    
    function getUsage(bytes32 hash) external view returns (Usage memory) {
        return _usages[hash];
    }
    
    function getConsumerUsage(address consumer, uint256 startTime, uint256 endTime) external view returns (bytes32[] memory) {
        bytes32[] storage allHashes = _consumerUsages[consumer];
        uint256 count = 0;
        for (uint256 i = 0; i < allHashes.length && count < MAX_RESULTS; i++) {
            if (_usages[allHashes[i]].timestamp >= startTime && _usages[allHashes[i]].timestamp <= endTime) {
                count++;
            }
        }
        bytes32[] memory result = new bytes32[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allHashes.length && index < count; i++) {
            if (_usages[allHashes[i]].timestamp >= startTime && _usages[allHashes[i]].timestamp <= endTime) {
                result[index] = allHashes[i];
                index++;
            }
        }
        return result;
    }
}
