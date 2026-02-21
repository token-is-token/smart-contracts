# Decisions - LLM Share Network Smart Contracts

## 2026-02-21 Initial Architecture Decisions

### 1. Contract Upgrade Strategy

**Decision**: Transparent Proxy for 5 contracts, no proxy for Governor/Timelock
**Rationale**: Transparent proxy is safer for high-value contracts; Governor/Timelock should not be upgradeable to reduce governance layer risk

### 2. ShareToken Minting Distribution

**Decision**: 85% Provider, 10% Treasury, 5% Liquidity Pool
**Rationale**: Incentivize providers while supporting protocol sustainability

### 3. Provider Staking Tiers

| Tier       | Minimum Stake   | Weight |
| ---------- | --------------- | ------ |
| Basic      | 1,000 SHARE     | 1x     |
| Verified   | 10,000 SHARE    | 1.5x   |
| Premium    | 100,000 SHARE   | 2x     |
| Enterprise | 1,000,000 SHARE | 3x     |

### 4. Governance Parameters

- votingDelay: 1 day
- votingPeriod: 7 days
- proposalThreshold: 10,000 SHARE
- quorumNumerator: 4%
- timelockDelay: 2 days

### 5. Treasury Multi-sig

**Decision**: External address/role, not implementing multi-sig contract
**Rationale**: Reduce scope, use existing Safe or similar solutions

## Foundry Configuration

- Enabled optimizer with 200 runs.
- Set solc version to 0.8.19.
- Configured remappings for OpenZeppelin via node_modules.
- Set test directory to test/foundry.
