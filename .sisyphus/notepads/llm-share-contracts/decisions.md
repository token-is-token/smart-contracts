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

## 2026-02-21 Update: Foundry test 路径与 solc 版本对齐

- **Decision**: 将 `foundry.toml` 的 `test` 目录改为 `test/`（从 `test/foundry`）。
- **Rationale**: 仓库测试结构使用 `test/{unit,integration,fuzz,...}`，将 Foundry 测试直接放在 `test/fuzz` 更符合约定，且 `forge test --match-contract` 可直接发现合约。
- **Note**: ShareToken 依赖 OZ upgradeable（^0.8.20），Foundry/合约编译器版本需保持 0.8.20。
