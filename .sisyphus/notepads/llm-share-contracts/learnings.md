# Learnings - LLM Share Network Smart Contracts

## 2026-02-21 Session Start

### Project Overview

- LLM Share Network 的智能合约系统
- 基于 0G Chain (EVM兼容)
- 使用 Solidity ^0.8.19

### Key Decisions

1. **Upgrade Pattern**: Transparent 代理模式
   - 5个合约使用代理: ShareToken, PaymentSettlement, UsageRegistry, ProviderStaking, Treasury
   - 2个合约不使用代理: Governor, Timelock (降低治理层风险)

2. **Testing Framework**: Hardhat + Foundry 双框架
   - Hardhat: 单元测试 + 集成测试 (TypeScript)
   - Foundry: Fuzz测试 + 快速测试 (Solidity)

3. **Configuration**: 使用 TODO 占位符
   - 0G Chain RPC/Chain ID
   - Treasury/Liquidity Pool 地址

### Technical Stack

- Solidity ^0.8.19
- OpenZeppelin Contracts (upgradeable)
- Hardhat + Foundry
- TypeScript

## 2026-02-21: 项目初始化

- 建立了标准的智能合约项目目录结构，区分了 token, core, governance 等模块。
- 采用了 Hardhat + Foundry 双框架的测试目录结构 (unit, integration, fuzz, e2e)。
- 配置了基本的 .gitignore 以支持 Hardhat 和 Foundry 的构建产物。
- 建立了部署记录规范，确保多链部署的可追踪性。

## 2026-02-21

- 配置了 Solhint 和 Prettier 工具以确保代码质量。
- 使用了 作为 Solidity 检查的基础规则。
- 配置了 以支持 Solidity 文件的格式化。
- 在 中添加了 和 脚本。

## 2026-02-21

- 配置了 Solhint 和 Prettier 工具以确保代码质量。
- 使用了 solhint:recommended 作为 Solidity 检查的基础规则。
- 配置了 prettier-plugin-solidity 以支持 Solidity 文件的格式化。
- 在 package.json 中添加了 lint 和 lint:fix 脚本。
## IShareToken Interface Definition
- Defined core functions: mintByUsage, batchAirdrop, updateMintingRate, getMintingRate, getAirdropHistory.
- Defined events: TokensMinted, MintingRateUpdated, AirdropDistributed.
- Note: Interface cannot contain state variables or constants like 'bytes32 public constant'. These should be defined in the implementation or a library if shared.
- Used Solidity ^0.8.19 and NatSpec documentation.
## IShareToken Interface Correction
- Updated interface to match specification in .prompts/02-share-token.md.
- mintByUsage: (string model, uint256 tokenConsumed, address provider)
- batchAirdrop: added 'string reason' parameter.
- updateMintingRate & getMintingRate: now per-model (string model).
- getAirdropHistory: now returns total amount for a specific user (address user).
- Events: Updated TokensMinted, MintingRateUpdated, and AirdropDistributed to match spec.

## 2026-02-21: ShareToken Foundry Fuzz Tests

- mintByUsage 的 `amount = tokenConsumed * rate / 1000` 需要同时约束：
  - `tokenConsumed > 0`
  - `tokenConsumed * rate` 不溢出（测试里用 `maxConsumed = type(uint256).max / rate`）
  - `amount > 0`（测试里用 `minConsumed = ceil(1000 / rate)`）
- 85/10/5 分配精度：treasury 与 LP 用 floor 计算，provider 拿 remainder，因此三者之和应严格等于 amount。
- batchAirdrop fuzz：为避免过大数组拖慢执行，建议把 fuzz 数组长度裁剪到一个小上限（例如 32），并注意重复 recipient 的累计断言。
- Foundry 测试可在不依赖 forge-std 的情况下，通过内嵌 Vm 接口 + 自定义断言实现（便于仓库尚未安装 forge-std 时先落测试）。
