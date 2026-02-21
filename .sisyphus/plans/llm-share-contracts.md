# LLM Share Network Smart Contracts - 工作计划

## TL;DR

> **Quick Summary**: 开发完整的 LLM Share Network 智能合约系统，包括7个核心可升级合约、接口定义、完整测试套件、部署脚本和CI/CD配置。
>
> **Deliverables**:
>
> - 7个核心合约 (ShareToken, PaymentSettlement, UsageRegistry, ProviderStaking, Governor, Timelock, Treasury)
> - 3个接口定义 + 1个工具库
> - Hardhat + Foundry 双框架测试套件
> - 部署脚本 + 验证脚本
> - GitHub Actions CI/CD
> - 项目文档

> **Estimated Effort**: XL (大型项目)
> **Parallel Execution**: YES - 7 waves
> **Critical Path**: 基础设施 → ShareToken → 核心合约 → 治理合约 → 测试 → 部署 → CI/CD

---

## Context

### Original Request

用户要求按照 `.prompts` 文件夹中的7个提示词文档，开发完整的 LLM Share Network 智能合约系统。

### Interview Summary

**Key Discussions**:

- 合约升级策略: Transparent代理模式
- 0G Chain配置: 使用TODO占位符
- 部署地址: 使用TODO占位符
- 测试策略: Hardhat + Foundry 双框架并重

**Research Findings**:

- 项目为全新项目，无现有代码库
- 使用OpenZeppelin Contracts标准模式
- 需要使用 openzeppelin-contracts-upgradeable 进行代理模式实现

### Metis Review

**Identified Gaps** (addressed):

- 信任模型/用量真实性: 假设由授权的 UsageReporter 角色上报，防止虚报通过 MINTER_ROLE 权限控制
- 动态铸造公式: 使用 `.prompts` 中定义的铸造系数表，无总量上限
- 治理投票权来源: 使用 ShareToken (ERC20Votes)，接受动态铸造带来的投票权变化
- 升级范围: ShareToken/PaymentSettlement/UsageRegistry/ProviderStaking/Treasury 使用 Transparent 代理；Governor/Timelock 不使用代理（降低治理层风险）
- Treasury多签: 作为外部地址/role，本期不实现多签合约

---

## Work Objectives

### Core Objective

构建一个完整的、可升级的、安全的智能合约系统，支持 LLM Share Network 的代币经济、支付结算、用量记录、提供者质押和DAO治理功能。

### Concrete Deliverables

- `contracts/token/ShareToken.sol` - ERC20动态铸造代币
- `contracts/core/PaymentSettlement.sol` - 支付结算合约
- `contracts/core/UsageRegistry.sol` - 用量记录合约
- `contracts/core/ProviderStaking.sol` - 提供者质押合约
- `contracts/governance/Governor.sol` - DAO治理合约
- `contracts/governance/Timelock.sol` - 时间锁合约
- `contracts/governance/Treasury.sol` - 国库合约
- `contracts/interfaces/*.sol` - 3个接口定义
- `contracts/libraries/Utils.sol` - 工具库
- `test/**/*.test.ts` - Hardhat测试
- `test/**/*.t.sol` - Foundry测试
- `scripts/deploy/*.ts` - 部署脚本
- `.github/workflows/*.yml` - CI/CD配置
- `docs/architecture.md` - 架构文档

### Definition of Done

- [ ] 所有合约编译成功 (`npx hardhat compile` && `forge build`)
- [ ] 所有测试通过 (`npx hardhat test` && `forge test`)
- [ ] 代码风格检查通过 (`npm run lint`)
- [ ] 本地部署脚本运行成功
- [ ] CI/CD流程配置完成

### Must Have

- 所有7个核心合约完整实现
- 完整的单元测试覆盖
- 可工作的部署脚本
- Transparent代理升级支持（5个合约）
- OpenZeppelin安全模式

### Must NOT Have (Guardrails)

- **不引入未讨论模块**: 预言机、跨链桥、复杂AMM/LP管理、链上仲裁
- **不实现多签合约**: Treasury多签作为外部地址
- **不使用不受限数组遍历**: 所有批量操作必须有上限或使用pull-based模式
- **不混用upgradeable/非upgradeable**: 明确哪些合约使用代理，哪些不使用
- **不在Governor/Timelock上使用代理**: 降低治理层风险

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision

- **Infrastructure exists**: NO (全新项目)
- **Automated tests**: YES (TDD)
- **Framework**: Hardhat (TypeScript) + Foundry (Solidity)
- **TDD Workflow**: 每个任务遵循 RED → GREEN → REFACTOR

### QA Policy

Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Solidity Contracts**: Use Hardhat test + Foundry test — compile, run tests, assert results
- **Deployment Scripts**: Use Bash (npx hardhat run) — run script, verify output addresses
- **CI/CD**: Use Bash (act/gh cli) — validate workflow syntax, dry-run

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — 基础设施 + 项目配置):
├── Task 1: 项目目录结构和基础配置 [quick]
├── Task 2: Hardhat配置 + TypeScript [quick]
├── Task 3: Foundry配置 [quick]
├── Task 4: 代码质量工具配置 (Solhint + Prettier) [quick]
├── Task 5: OpenZeppelin依赖安装和验证 [quick]
└── Task 6: 项目文档骨架 [quick]

Wave 2 (After Wave 1 — ShareToken核心):
├── Task 7: IShareToken接口定义 [quick]
├── Task 8: ShareToken合约实现 [deep]
├── Task 9: ShareToken单元测试 (Hardhat) [quick]
├── Task 10: ShareToken Fuzz测试 (Foundry) [unspecified-high]
└── Task 11: ShareToken代理升级测试 [quick]

Wave 3 (After Wave 2 — 核心业务合约):
├── Task 12: IPaymentSettlement接口定义 [quick]
├── Task 13: IProviderStaking接口定义 [quick]
├── Task 14: PaymentSettlement合约实现 [deep]
├── Task 15: UsageRegistry合约实现 [deep]
├── Task 16: ProviderStaking合约实现 [deep]
├── Task 17: 核心合约单元测试 (Hardhat) [unspecified-high]
└── Task 18: 核心合约Fuzz测试 (Foundry) [unspecified-high]

Wave 4 (After Wave 3 — 治理合约):
├── Task 19: Timelock合约实现 [quick]
├── Task 20: Governor合约实现 [deep]
├── Task 21: Treasury合约实现 [deep]
├── Task 22: 治理合约单元测试 (Hardhat) [unspecified-high]
└── Task 23: 治理合约集成测试 [deep]

Wave 5 (After Wave 4 — 工具库和完整集成):
├── Task 24: Utils工具库实现 [quick]
├── Task 25: 合约间集成测试 [deep]
├── Task 26: 完整流程E2E测试 [deep]
└── Task 27: 升级回归测试 [quick]

Wave 6 (After Wave 5 — 部署脚本):
├── Task 28: deploy-token.ts部署脚本 [quick]
├── Task 29: deploy-core.ts部署脚本 [quick]
├── Task 30: deploy-governance.ts部署脚本 [quick]
├── Task 31: deploy-all.ts完整部署脚本 [quick]
├── Task 32: verify-contracts.ts验证脚本 [quick]
└── Task 33: 部署脚本测试 [quick]

Wave 7 (After Wave 6 — CI/CD和文档):
├── Task 34: test.yml工作流 [quick]
├── Task 35: lint.yml工作流 [quick]
├── Task 36: security.yml工作流 [quick]
├── Task 37: deploy-testnet.yml工作流 [quick]
├── Task 38: GitHub Issue/PR模板 [quick]
└── Task 39: 完整架构文档 [writing]

Critical Path: Wave 1 → Wave 2 → Wave 3 → Wave 4 → Wave 5 → Wave 6 → Wave 7
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 7 (Wave 3)
```

### Dependency Matrix

| Task  | Depends On | Blocks |
| ----- | ---------- | ------ |
| 1-6   | —          | 7-39   |
| 7-11  | 1-6        | 12-27  |
| 12-18 | 7-11       | 19-27  |
| 19-23 | 12-18      | 24-33  |
| 24-27 | 19-23      | 28-39  |
| 28-33 | 24-27      | 34-39  |
| 34-39 | 28-33      | —      |

### Agent Dispatch Summary

- **Wave 1**: 6 tasks → all `quick`
- **Wave 2**: 5 tasks → 3 `quick`, 1 `deep`, 1 `unspecified-high`
- **Wave 3**: 7 tasks → 3 `quick`, 3 `deep`, 2 `unspecified-high`
- **Wave 4**: 5 tasks → 1 `quick`, 2 `deep`, 2 `unspecified-high`
- **Wave 5**: 4 tasks → 2 `quick`, 2 `deep`
- **Wave 6**: 6 tasks → all `quick`
- **Wave 7**: 6 tasks → 5 `quick`, 1 `writing`

---

## TODOs

### Wave 1: 基础设施 + 项目配置

- [ ] 1. 项目目录结构和基础配置

  **What to do**:
  - 创建完整目录结构 (contracts/, test/, scripts/, deployments/, docs/, .github/)
  - 创建 LICENSE (MIT)
  - 更新 .gitignore (node_modules, cache, artifacts, .env, deployments/\*.json)
  - 创建 deployments/README.md

  **Must NOT do**:
  - 不创建任何合约文件
  - 不配置具体的网络参数

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 简单的目录创建和文件写入
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2-6)
  - **Blocks**: Tasks 7-39
  - **Blocked By**: None

  **References**:
  - `.prompts/01-init-repository.md:9-61` - 完整目录结构定义
  - `.prompts/01-init-repository.md:87-92` - .gitignore 内容

  **Acceptance Criteria**:
  - [ ] 目录结构符合 `.prompts/01-init-repository.md` 定义
  - [ ] LICENSE 文件存在
  - [ ] .gitignore 包含所有必要条目

  **QA Scenarios**:

  ```
  Scenario: 验证目录结构
    Tool: Bash
    Steps:
      1. ls -la contracts/ test/ scripts/ deployments/ docs/ .github/
      2. test -f LICENSE && test -f .gitignore
    Expected Result: 所有目录存在，LICENSE 和 .gitignore 文件存在
    Evidence: .sisyphus/evidence/task-01-structure.txt
  ```

  **Commit**: NO (groups with Wave 1)

- [ ] 2. Hardhat配置 + TypeScript

  **What to do**:
  - 创建 package.json (hardhat, ethers, typescript, @openzeppelin/hardhat-upgrades 等依赖)
  - 创建 hardhat.config.ts (Solidity 0.8.19, 0G Chain TODO占位符)
  - 创建 tsconfig.json

  **Must NOT do**:
  - 不配置真实的0G Chain RPC地址
  - 不添加未验证的第三方依赖

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 配置文件创建
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3-6)
  - **Blocks**: Tasks 7-39
  - **Blocked By**: None

  **References**:
  - `.prompts/01-init-repository.md:73-82` - package.json 和 hardhat.config.ts 要求
  - `.prompts/system-prompt.md:27-32` - 技术栈定义

  **Acceptance Criteria**:
  - [ ] package.json 包含所有必要依赖
  - [ ] hardhat.config.ts 配置 Solidity 0.8.19
  - [ ] tsconfig.json 配置正确

  **QA Scenarios**:

  ```
  Scenario: 验证Hardhat配置
    Tool: Bash
    Steps:
      1. npm install
      2. npx hardhat compile (expect no contracts to compile)
    Expected Result: npm install 成功，hardhat 命令可执行
    Evidence: .sisyphus/evidence/task-02-hardhat.txt
  ```

  **Commit**: NO (groups with Wave 1)

- [ ] 3. Foundry配置

  **What to do**:
  - 创建 foundry.toml (标准配置，依赖 @openzeppelin/contracts)
  - 创建 remappings.txt (OpenZeppelin路径映射)

  **Must NOT do**:
  - 不配置真实的网络RPC

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 配置文件创建
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1-2, 4-6)
  - **Blocks**: Tasks 7-39
  - **Blocked By**: None

  **References**:
  - `.prompts/01-init-repository.md:83-85` - foundry.toml 要求
  - `.prompts/system-prompt.md:29` - Foundry框架

  **Acceptance Criteria**:
  - [ ] foundry.toml 配置正确
  - [ ] remappings.txt 包含 OpenZeppelin 映射

  **QA Scenarios**:

  ```
  Scenario: 验证Foundry配置
    Tool: Bash
    Steps:
      1. forge build (expect no contracts to build)
    Expected Result: forge 命令可执行
    Evidence: .sisyphus/evidence/task-03-foundry.txt
  ```

  **Commit**: NO (groups with Wave 1)

- [ ] 4. 代码质量工具配置 (Solhint + Prettier)

  **What to do**:
  - 创建 .solhint.json (Solidity代码风格规则)
  - 创建 .prettierrc (格式化配置)
  - 创建 .prettierignore
  - 在 package.json 添加 lint 脚本

  **Must NOT do**:
  - 不添加过于严格的规则导致开发困难

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 配置文件创建
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1-3, 5-6)
  - **Blocks**: Tasks 7-39
  - **Blocked By**: None

  **References**:
  - `.prompts/01-init-repository.md:21-22` - .solhint.json 和 .prettierrc

  **Acceptance Criteria**:
  - [ ] .solhint.json 配置合理规则
  - [ ] .prettierrc 配置正确
  - [ ] npm run lint 脚本可用

  **QA Scenarios**:

  ```
  Scenario: 验证lint配置
    Tool: Bash
    Steps:
      1. npm run lint (expect no files to lint yet)
    Expected Result: lint 命令可执行
    Evidence: .sisyphus/evidence/task-04-lint.txt
  ```

  **Commit**: NO (groups with Wave 1)

- [ ] 5. OpenZeppelin依赖安装和验证

  **What to do**:
  - 确保 package.json 包含 @openzeppelin/contracts 和 @openzeppelin/contracts-upgradeable
  - 确保 @openzeppelin/hardhat-upgrades 已添加
  - 安装依赖并验证导入路径

  **Must NOT do**:
  - 不使用非官方的OpenZeppelin分支

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 依赖安装和验证
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1-4, 6)
  - **Blocks**: Tasks 7-39
  - **Blocked By**: None

  **References**:
  - `.prompts/system-prompt.md:10` - OpenZeppelin合约库使用

  **Acceptance Criteria**:
  - [ ] @openzeppelin/contracts 已安装
  - [ ] @openzeppelin/contracts-upgradeable 已安装
  - [ ] @openzeppelin/hardhat-upgrades 已安装

  **QA Scenarios**:

  ```
  Scenario: 验证OpenZeppelin依赖
    Tool: Bash
    Steps:
      1. npm list @openzeppelin/contracts @openzeppelin/contracts-upgradeable @openzeppelin/hardhat-upgrades
    Expected Result: 所有包显示已安装版本
    Evidence: .sisyphus/evidence/task-05-oz.txt
  ```

  **Commit**: NO (groups with Wave 1)

- [ ] 6. 项目文档骨架

  **What to do**:
  - 更新 README.md (项目介绍、技术栈、安装命令、编译测试命令、部署说明)
  - 创建 docs/architecture.md 骨架 (合约架构图占位、合约关系说明占位)

  **Must NOT do**:
  - 不编写详细的合约文档（后续任务补充）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 文档骨架创建
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1-5)
  - **Blocks**: Tasks 7-39
  - **Blocked By**: None

  **References**:
  - `.prompts/01-init-repository.md:65-71` - README.md 要求
  - `.prompts/07-ci-cd-and-docs.md:78-80` - docs/architecture.md 要求

  **Acceptance Criteria**:
  - [ ] README.md 包含所有必要章节
  - [ ] docs/architecture.md 骨架存在

  **QA Scenarios**:

  ```
  Scenario: 验证文档骨架
    Tool: Bash
    Steps:
      1. grep -q "技术栈" README.md
      2. test -f docs/architecture.md
    Expected Result: README.md 包含技术栈说明，architecture.md 存在
    Evidence: .sisyphus/evidence/task-06-docs.txt
  ```

  **Commit**: YES (Wave 1 完成提交)
  - Message: `chore(init): project scaffolding and configuration`
  - Files: 所有Wave 1创建的文件
  - Pre-commit: npm run lint

---

### Wave 2: ShareToken核心

- [ ] 7. IShareToken接口定义

  **What to do**:
  - 创建 contracts/interfaces/IShareToken.sol
  - 定义所有外部函数接口
  - 定义事件和错误
  - 定义数据结构

  **Must NOT do**:
  - 不包含实现代码

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 接口定义
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 8-11)
  - **Blocks**: Tasks 12-27
  - **Blocked By**: Tasks 1-6

  **References**:
  - `.prompts/02-share-token.md:36-46` - 核心函数定义
  - `.prompts/02-share-token.md:68-73` - 事件定义
  - `.prompts/05-interfaces-and-tests.md:9-15` - 接口要求

  **Acceptance Criteria**:
  - [ ] 所有核心函数签名定义
  - [ ] 所有事件定义
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证接口编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
      2. forge build
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-07-interface.txt
  ```

  **Commit**: NO (groups with Wave 2)

- [ ] 8. ShareToken合约实现

  **What to do**:
  - 创建 contracts/token/ShareToken.sol
  - 继承 ERC20Upgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, AccessControlUpgradeable
  - 实现动态铸造逻辑 (85% Provider, 10% Treasury, 5% LP)
  - 实现铸造系数管理
  - 实现空投功能
  - 定义角色 (MINTER_ROLE, GOVERNANCE_ROLE, AIRDROP_ROLE)
  - 实现 initialize 函数 (替代 constructor)
  - 实现铸造系数表初始化

  **Must NOT do**:
  - 不使用 constructor (Transparent代理模式)
  - 不实现总量上限
  - 不实现减半机制

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 核心代币合约，复杂度高
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 7, 9-11)
  - **Blocks**: Tasks 12-27
  - **Blocked By**: Tasks 1-6

  **References**:
  - `.prompts/02-share-token.md:9-73` - 完整合约要求
  - `.prompts/02-share-token.md:48-56` - 铸造系数表
  - `.prompts/02-share-token.md:58-66` - 安全要求
  - `.prompts/system-prompt.md:35-41` - 安全模式要求

  **Acceptance Criteria**:
  - [ ] 继承正确的OpenZeppelin upgradeable合约
  - [ ] mintByUsage 实现铸造分配 85/10/5
  - [ ] 批量空投功能实现
  - [ ] 铸造系数可治理更新
  - [ ] 所有角色定义正确
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证ShareToken编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
    Expected Result: exit code 0, ShareToken.sol 编译成功
    Evidence: .sisyphus/evidence/task-08-compile.txt
  ```

  **Commit**: NO (groups with Wave 2)

- [x] 9. ShareToken单元测试 (Hardhat)

  **What to do**:
  - 创建 test/unit/ShareToken.test.ts
  - 测试部署和初始化
  - 测试铸造功能 (mintByUsage)
  - 测试铸造分配 85/10/5
  - 测试铸造系数更新
  - 测试空投功能
  - 测试权限控制
  - 测试 permit 功能

  **Must NOT do**:
  - 不跳过负面测试用例

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 单元测试编写
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 7-8, 10-11)
  - **Blocks**: Tasks 12-27
  - **Blocked By**: Tasks 1-6

  **References**:
  - `.prompts/05-interfaces-and-tests.md:39-45` - ShareToken测试要求
  - `.prompts/02-share-token.md:48-56` - 铸造系数表测试数据

  **Acceptance Criteria**:
  - [ ] 所有测试用例实现
  - [ ] npx hardhat test test/unit/ShareToken.test.ts 全部通过

  **QA Scenarios**:

  ```
  Scenario: 运行ShareToken单元测试
    Tool: Bash
    Steps:
      1. npx hardhat test test/unit/ShareToken.test.ts
    Expected Result: "X passing", "0 failing"
    Evidence: .sisyphus/evidence/task-09-hardhat-test.txt
  ```

  **Commit**: NO (groups with Wave 2)

- [x] 10. ShareToken Fuzz测试 (Foundry)

  **What to do**:
  - 创建 test/fuzz/ShareTokenFuzz.t.sol
  - 测试铸造系数边界
  - 测试大额铸造
  - 测试铸造分配精度
  - 测试批量空投边界

  **Must NOT do**:
  - 不假设固定的测试数据

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Fuzz测试需要深入理解边界条件
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 7-9, 11)
  - **Blocks**: Tasks 12-27
  - **Blocked By**: Tasks 1-6

  **References**:
  - `.prompts/05-interfaces-and-tests.md:66-72` - Fuzz测试模板

  **Acceptance Criteria**:
  - [ ] Fuzz测试覆盖核心功能
  - [ ] forge test --match-contract ShareTokenFuzz 全部通过

  **QA Scenarios**:

  ```
  Scenario: 运行ShareToken Fuzz测试
    Tool: Bash
    Steps:
      1. forge test --match-contract ShareTokenFuzz -vvv
    Expected Result: "0 failed", 所有测试通过
    Evidence: .sisyphus/evidence/task-10-fuzz-test.txt
  ```

  **Commit**: NO (groups with Wave 2)

- [x] 11. ShareToken代理升级测试

  **What to do**:
  - 创建 test/upgrade/ShareTokenUpgrade.test.ts
  - 测试 Transparent 代理部署
  - 测试升级流程
  - 测试升级后状态保持
  - 测试未授权升级拒绝

  **Must NOT do**:
  - 不跳过代理安全性测试

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 代理测试模式固定
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 7-10)
  - **Blocks**: Tasks 12-27
  - **Blocked By**: Tasks 1-6

  **References**:
  - @openzeppelin/hardhat-upgrades 文档
  - `.prompts/system-prompt.md:41` - 升级代理模式

  **Acceptance Criteria**:
  - [ ] 代理部署测试通过
  - [ ] 升级流程测试通过
  - [ ] 状态保持测试通过

  **QA Scenarios**:

  ```
  Scenario: 运行代理升级测试
    Tool: Bash
    Steps:
      1. npx hardhat test test/upgrade/ShareTokenUpgrade.test.ts
    Expected Result: "X passing", "0 failing"
    Evidence: .sisyphus/evidence/task-11-upgrade-test.txt
  ```

  **Commit**: YES (Wave 2 完成提交)
  - Message: `feat(token): ShareToken implementation with tests`
  - Files: contracts/token/, contracts/interfaces/IShareToken.sol, test/unit/ShareToken.test.ts, test/fuzz/ShareTokenFuzz.t.sol, test/upgrade/ShareTokenUpgrade.test.ts
  - Pre-commit: npx hardhat test

---

### Wave 3: 核心业务合约

- [x] 12. IPaymentSettlement接口定义

  **What to do**:
  - 创建 contracts/interfaces/IPaymentSettlement.sol
  - 定义 Settlement 结构体和枚举
  - 定义核心函数接口
  - 定义事件

  **Must NOT do**:
  - 不包含实现代码

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 13-18)
  - **Blocks**: Tasks 19-27
  - **Blocked By**: Tasks 7-11

  **References**:
  - `.prompts/03-core-contracts.md:15-35` - PaymentSettlement 接口定义
  - `.prompts/05-interfaces-and-tests.md:17-24` - 接口要求

  **Acceptance Criteria**:
  - [ ] 所有函数签名定义
  - [ ] 结构体和枚举定义完整
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证接口编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-12-interface.txt
  ```

  **Commit**: NO (groups with Wave 3)

- [x] 13. IProviderStaking接口定义

  **What to do**:
  - 创建 contracts/interfaces/IProviderStaking.sol
  - 定义 Tier 枚举和 StakeInfo 结构体
  - 定义核心函数接口
  - 定义事件

  **Must NOT do**:
  - 不包含实现代码

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 12, 14-18)
  - **Blocks**: Tasks 19-27
  - **Blocked By**: Tasks 7-11

  **References**:
  - `.prompts/03-core-contracts.md:82-104` - ProviderStaking 等级定义
  - `.prompts/05-interfaces-and-tests.md:25-36` - 接口要求

  **Acceptance Criteria**:
  - [ ] 所有函数签名定义
  - [ ] Tier 枚举完整 (Basic, Verified, Premium, Enterprise)
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证接口编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-13-interface.txt
  ```

  **Commit**: NO (groups with Wave 3)

- [x] 14. PaymentSettlement合约实现

  **What to do**:
  - 创建 contracts/core/PaymentSettlement.sol
  - 继承 Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable
  - 实现 Settlement 结构体和状态映射
  - 实现 settleUsage 单笔结算
  - 实现 batchSettle 批量结算 (带上限防止DoS)
  - 实现 disputeSettlement 争议提交
  - 实现 resolveDispute 争议解决
  - 实现权限控制 (SETTLER_ROLE, DISPUTE_RESOLVER_ROLE)

  **Must NOT do**:
  - 不使用不受限数组遍历
  - 不接受原生币支付 (除非明确处理)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 支付结算逻辑复杂，需要安全考虑
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 12-13, 15-18)
  - **Blocks**: Tasks 19-27
  - **Blocked By**: Tasks 7-11

  **References**:
  - `.prompts/03-core-contracts.md:8-35` - 完整功能要求
  - `.prompts/system-prompt.md:35-37` - Checks-Effects-Interactions 和防重入

  **Acceptance Criteria**:
  - [ ] 结算流程完整实现
  - [ ] 批量操作有上限
  - [ ] 争议处理完整
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证PaymentSettlement编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-14-compile.txt
  ```

  **Commit**: NO (groups with Wave 3)

- [x] 15. UsageRegistry合约实现

  **What to do**:
  - 创建 contracts/core/UsageRegistry.sol
  - 继承 Initializable, AccessControlUpgradeable
  - 实现 Usage 结构体
  - 实现 recordUsage 记录用量 (返回唯一hash)
  - 实现 getUsage 查询
  - 实现 getConsumerUsage 按消费者查询 (使用时间范围)
  - 实现防重放 (nonce/epoch key)
  - 使用 mapping 存储而非数组

  **Must NOT do**:
  - 不按调用逐条存储 (使用聚合或限制)
  - 不使用 unbounded loop

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 用量记录是核心，需要防篡改和效率考虑
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 12-14, 16-18)
  - **Blocks**: Tasks 19-27
  - **Blocked By**: Tasks 7-11

  **References**:
  - `.prompts/03-core-contracts.md:37-72` - 完整功能要求
  - `.prompts/03-core-contracts.md:41-42` - 防篡改要求

  **Acceptance Criteria**:
  - [ ] 用量记录完整实现
  - [ ] 查询功能正常
  - [ ] 防重放机制
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证UsageRegistry编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-15-compile.txt
  ```

  **Commit**: NO (groups with Wave 3)

- [x] 16. ProviderStaking合约实现

  **What to do**:
  - 创建 contracts/core/ProviderStaking.sol
  - 继承 Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, ERC721Holder
  - 实现 Tier 枚举 (Basic, Verified, Premium, Enterprise)
  - 实现 StakeInfo 结构体
  - 实现 stake 质押 (更新等级)
  - 实现 unstake 解押 (冷却期检查)
  - 实现 claimRewards 奖励领取
  - 实现 slash 惩罚 (SLASHER_ROLE)
  - 实现 getProviderTier 和 getStakeInfo
  - 使用 SafeERC20 处理代币转账

  **Must NOT do**:
  - 不允许负数质押
  - 不跳过冷却期检查

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 质押逻辑复杂，涉及等级、奖励、惩罚
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 12-15, 17-18)
  - **Blocks**: Tasks 19-27
  - **Blocked By**: Tasks 7-11

  **References**:
  - `.prompts/03-core-contracts.md:74-104` - 完整功能要求
  - `.prompts/03-core-contracts.md:82-89` - 质押等级定义
  - `.prompts/03-core-contracts.md:100-103` - 惩罚条件

  **Acceptance Criteria**:
  - [ ] 4级质押系统完整实现
  - [ ] 质押/解押流程正常
  - [ ] 奖励分配正确
  - [ ] 惩罚机制完整
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证ProviderStaking编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-16-compile.txt
  ```

  **Commit**: NO (groups with Wave 3)

- [x] 17. 核心合约单元测试 (Hardhat)

  **What to do**:
  - 创建 test/unit/PaymentSettlement.test.ts
  - 创建 test/unit/UsageRegistry.test.ts
  - 创建 test/unit/ProviderStaking.test.ts
  - 测试各合约的核心功能
  - 测试权限控制
  - 测试边界条件

  **Must NOT do**:
  - 不跳过负面测试

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 多个合约的完整测试覆盖
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 12-16, 18)
  - **Blocks**: Tasks 19-27
  - **Blocked By**: Tasks 7-11

  **References**:
  - `.prompts/05-interfaces-and-tests.md:47-57` - 测试要求

  **Acceptance Criteria**:
  - [ ] 所有测试用例实现
  - [ ] npx hardhat test test/unit/PaymentSettlement.test.ts 全部通过
  - [ ] npx hardhat test test/unit/UsageRegistry.test.ts 全部通过
  - [ ] npx hardhat test test/unit/ProviderStaking.test.ts 全部通过

  **QA Scenarios**:

  ```
  Scenario: 运行核心合约单元测试
    Tool: Bash
    Steps:
      1. npx hardhat test test/unit/PaymentSettlement.test.ts test/unit/UsageRegistry.test.ts test/unit/ProviderStaking.test.ts
    Expected Result: "X passing", "0 failing"
    Evidence: .sisyphus/evidence/task-17-hardhat-test.txt
  ```

  **Commit**: NO (groups with Wave 3)

- [x] 18. 核心合约Fuzz测试 (Foundry)

  **What to do**:
  - 创建 test/fuzz/PaymentSettlementFuzz.t.sol
  - 创建 test/fuzz/UsageRegistryFuzz.t.sol
  - 创建 test/fuzz/ProviderStakingFuzz.t.sol
  - 测试结算金额边界
  - 测试质押等级变更
  - 测试惩罚金额边界

  **Must NOT do**:
  - 不假设固定测试数据

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Fuzz测试需要深入理解边界条件
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 12-17)
  - **Blocks**: Tasks 19-27
  - **Blocked By**: Tasks 7-11

  **References**:
  - `.prompts/05-interfaces-and-tests.md:64-72` - Fuzz测试模板

  **Acceptance Criteria**:
  - [ ] Fuzz测试覆盖核心功能
  - [ ] forge test --match-path "test/fuzz/\*Fuzz.t.sol" 全部通过

  **QA Scenarios**:

  ```
  Scenario: 运行核心合约Fuzz测试
    Tool: Bash
    Steps:
      1. forge test --match-path "test/fuzz/*Fuzz.t.sol" -vvv
    Expected Result: "0 failed"
    Evidence: .sisyphus/evidence/task-18-fuzz-test.txt
  ```

  **Commit**: YES (Wave 3 完成提交)
  - Message: `feat(core): PaymentSettlement, UsageRegistry, ProviderStaking`
  - Files: contracts/core/, contracts/interfaces/IPaymentSettlement.sol, contracts/interfaces/IProviderStaking.sol, test/unit/PaymentSettlement.test.ts, test/unit/UsageRegistry.test.ts, test/unit/ProviderStaking.test.ts, test/fuzz/
  - Pre-commit: npx hardhat test

---

### Wave 4: 治理合约

- [x] 19. Timelock合约实现

  **What to do**:
  - 创建 contracts/governance/Timelock.sol
  - 继承 OpenZeppelin TimelockController
  - 配置 minDelay = 2 days
  - 配置角色 (PROPOSER_ROLE, EXECUTOR_ROLE, CANCELLER_ROLE)
  - 不使用代理模式 (降低治理层风险)

  **Must NOT do**:
  - 不使用代理模式
  - 不缩短最小延迟

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 直接继承OpenZeppelin，配置简单
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 20-23)
  - **Blocks**: Tasks 24-27
  - **Blocked By**: Tasks 12-18

  **References**:
  - `.prompts/04-governance-contracts.md:43-63` - Timelock 要求
  - `.prompts/04-governance-contracts.md:55-57` - 核心参数

  **Acceptance Criteria**:
  - [ ] 继承 TimelockController 正确
  - [ ] 角色配置完整
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证Timelock编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-19-compile.txt
  ```

  **Commit**: NO (groups with Wave 4)

- [x] 20. Governor合约实现

  **What to do**:
  - 创建 contracts/governance/Governor.sol
  - 继承 Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorTimelockControl
  - 配置 votingDelay = 1 day
  - 配置 votingPeriod = 7 days
  - 配置 proposalThreshold = 10000e18
  - 配置 quorum(以blockNumber) 返回总供给的 4%
  - 实现 propose, castVote, castVoteWithReason, execute
  - 不使用代理模式

  **Must NOT do**:
  - 不使用代理模式
  - 不缩短投票期

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 治理合约逻辑复杂，涉及多个模块
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 19, 21-23)
  - **Blocks**: Tasks 24-27
  - **Blocked By**: Tasks 12-18

  **References**:
  - `.prompts/04-governance-contracts.md:8-42` - Governor 要求
  - `.prompts/04-governance-contracts.md:22-29` - 核心参数

  **Acceptance Criteria**:
  - [ ] 继承正确
  - [ ] 所有参数配置正确
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证Governor编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-20-compile.txt
  ```

  **Commit**: NO (groups with Wave 4)

- [x] 21. Treasury合约实现

  **What to do**:
  - 创建 contracts/governance/Treasury.sol
  - 继承 Initializable, AccessControlUpgradeable
  - 实现 deposit 存款
  - 实现 withdraw 提款 (onlyGovernance)
  - 实现 getBalance 查询余额
  - 实现紧急冻结机制 (FREEZER_ROLE)
  - 使用 Transparent 代理模式
  - 多签作为外部地址/role (不实现多签合约)

  **Must NOT do**:
  - 不实现多签合约
  - 不允许绕过治理提款

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 国库资金管理，安全要求高
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 19-20, 22-23)
  - **Blocks**: Tasks 24-27
  - **Blocked By**: Tasks 12-18

  **References**:
  - `.prompts/04-governance-contracts.md:64-82` - Treasury 要求

  **Acceptance Criteria**:
  - [ ] 存取款功能完整
  - [ ] 权限控制正确
  - [ ] 紧急冻结机制
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证Treasury编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-21-compile.txt
  ```

  **Commit**: NO (groups with Wave 4)

- [x] 22. 治理合约单元测试 (Hardhat)

  **What to do**:
  - 创建 test/unit/Timelock.test.ts
  - 创建 test/unit/Governor.test.ts
  - 创建 test/unit/Treasury.test.ts
  - 测试提案创建和投票
  - 测试时间锁执行
  - 测试国库操作

  **Must NOT do**:
  - 不跳过治理流程测试

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 治理测试涉及复杂的时间线
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 19-21, 23)
  - **Blocks**: Tasks 24-27
  - **Blocked By**: Tasks 12-18

  **References**:
  - `.prompts/05-interfaces-and-tests.md` - 测试参考

  **Acceptance Criteria**:
  - [ ] 所有测试用例实现
  - [ ] npx hardhat test test/unit/Timelock.test.ts 全部通过
  - [ ] npx hardhat test test/unit/Governor.test.ts 全部通过
  - [ ] npx hardhat test test/unit/Treasury.test.ts 全部通过

  **QA Scenarios**:

  ```
  Scenario: 运行治理合约单元测试
    Tool: Bash
    Steps:
      1. npx hardhat test test/unit/Timelock.test.ts test/unit/Governor.test.ts test/unit/Treasury.test.ts
    Expected Result: "X passing", "0 failing"
    Evidence: .sisyphus/evidence/task-22-hardhat-test.txt
  ```

  **Commit**: NO (groups with Wave 4)

- [x] 23. 治理合约集成测试

  **What to do**:
  - 创建 test/integration/GovernanceIntegration.test.ts
  - 测试完整治理流程: 提案 → 投票 → 时间锁 → 执行
  - 测试 Governor + Timelock + Treasury 集成
  - 测试升级提案流程

  **Must NOT do**:
  - 不跳过端到端测试

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 治理集成测试复杂
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 19-22)
  - **Blocks**: Tasks 24-27
  - **Blocked By**: Tasks 12-18

  **References**:
  - `.prompts/05-interfaces-and-tests.md:58-62` - 集成测试要求

  **Acceptance Criteria**:
  - [ ] 完整治理流程测试通过
  - [ ] npx hardhat test test/integration/GovernanceIntegration.test.ts 全部通过

  **QA Scenarios**:

  ```
  Scenario: 运行治理集成测试
    Tool: Bash
    Steps:
      1. npx hardhat test test/integration/GovernanceIntegration.test.ts
    Expected Result: "X passing", "0 failing"
    Evidence: .sisyphus/evidence/task-23-integration-test.txt
  ```

  **Commit**: YES (Wave 4 完成提交)
  - Message: `feat(governance): Governor, Timelock, Treasury`
  - Files: contracts/governance/, test/unit/Timelock.test.ts, test/unit/Governor.test.ts, test/unit/Treasury.test.ts, test/integration/GovernanceIntegration.test.ts
  - Pre-commit: npx hardhat test

---

### Wave 5: 工具库和完整集成

- [x] 24. Utils工具库实现

  **What to do**:
  - 创建 contracts/libraries/Utils.sol
  - 实现常用数学运算 (安全除法、精度处理)
  - 实现地址验证
  - 实现时间相关工具

  **Must NOT do**:
  - 不引入复杂的外部依赖

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Tasks 25-27)
  - **Blocks**: Tasks 28-39
  - **Blocked By**: Tasks 19-23

  **References**:
  - `.prompts/01-init-repository.md:39-40` - Utils.sol 位置

  **Acceptance Criteria**:
  - [ ] 工具函数完整
  - [ ] 编译通过

  **QA Scenarios**:

  ```
  Scenario: 验证Utils编译
    Tool: Bash
    Steps:
      1. npx hardhat compile
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-24-compile.txt
  ```

  **Commit**: NO (groups with Wave 5)

- [x] 25. 合约间集成测试

  **What to do**:
  - 创建 test/integration/ProtocolIntegration.test.ts
  - 测试 UsageRegistry → ShareToken 铸造流程
  - 测试 PaymentSettlement → ProviderStaking 集成
  - 测试完整用户旅程: 调用 → 记录 → 结算 → 铸造 → 质押

  **Must NOT do**:
  - 不跳过跨合约交互测试

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 集成测试需要理解所有合约交互
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Tasks 24, 26-27)
  - **Blocks**: Tasks 28-39
  - **Blocked By**: Tasks 19-23

  **References**:
  - `.prompts/05-interfaces-and-tests.md:58-62` - 集成测试要求

  **Acceptance Criteria**:
  - [ ] 所有合约间交互测试通过
  - [ ] npx hardhat test test/integration/ProtocolIntegration.test.ts 全部通过

  **QA Scenarios**:

  ```
  Scenario: 运行协议集成测试
    Tool: Bash
    Steps:
      1. npx hardhat test test/integration/ProtocolIntegration.test.ts
    Expected Result: "X passing", "0 failing"
    Evidence: .sisyphus/evidence/task-25-integration-test.txt
  ```

  **Commit**: NO (groups with Wave 5)

- [x] 26. 完整流程E2E测试

  **What to do**:
  - 创建 test/e2e/FullFlow.test.ts
  - 测试完整生命周期: 部署 → 初始化 → 用户调用 → 结算 → 质押 → 治理
  - 测试Gas消耗
  - 测试边界场景

  **Must NOT do**:
  - 不跳过Gas消耗测试

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: E2E测试覆盖完整流程
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Tasks 24-25, 27)
  - **Blocks**: Tasks 28-39
  - **Blocked By**: Tasks 19-23

  **References**:
  - `.prompts/05-interfaces-and-tests.md:58-62` - 集成测试要求

  **Acceptance Criteria**:
  - [ ] E2E测试覆盖完整流程
  - [ ] Gas消耗在合理范围
  - [ ] npx hardhat test test/e2e/FullFlow.test.ts 全部通过

  **QA Scenarios**:

  ```
  Scenario: 运行E2E测试
    Tool: Bash
    Steps:
      1. npx hardhat test test/e2e/FullFlow.test.ts
    Expected Result: "X passing", "0 failing"
    Evidence: .sisyphus/evidence/task-26-e2e-test.txt
  ```

  **Commit**: NO (groups with Wave 5)

- [x] 27. 升级回归测试

  **What to do**:
  - 创建 test/upgrade/CoreUpgrade.test.ts
  - 测试所有使用代理的合约的升级流程
  - 测试升级后状态保持
  - 测试升级后功能正常

  **Must NOT do**:
  - 不跳过状态保持验证

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Tasks 24-26)
  - **Blocks**: Tasks 28-39
  - **Blocked By**: Tasks 19-23

  **References**:
  - @openzeppelin/hardhat-upgrades 文档

  **Acceptance Criteria**:
  - [ ] 所有代理合约升级测试通过
  - [ ] npx hardhat test test/upgrade/CoreUpgrade.test.ts 全部通过

  **QA Scenarios**:

  ```
  Scenario: 运行升级回归测试
    Tool: Bash
    Steps:
      1. npx hardhat test test/upgrade/CoreUpgrade.test.ts
    Expected Result: "X passing", "0 failing"
    Evidence: .sisyphus/evidence/task-27-upgrade-test.txt
  ```

  **Commit**: YES (Wave 5 完成提交)
  - Message: `feat(libs): Utils library and integration tests`
  - Files: contracts/libraries/Utils.sol, test/integration/ProtocolIntegration.test.ts, test/e2e/FullFlow.test.ts, test/upgrade/CoreUpgrade.test.ts
  - Pre-commit: npx hardhat test

---

### Wave 6: 部署脚本

- [x] 28. deploy-token.ts部署脚本

  **What to do**:
  - 创建 scripts/deploy/deploy-token.ts
  - 使用 hardhat-upgrades 部署 Transparent 代理
  - 初始化铸造系数
  - 设置角色 (treasury, liquidityPool 地址使用占位符)
  - 输出部署地址

  **Must NOT do**:
  - 不使用真实的主网地址

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6 (with Tasks 29-33)
  - **Blocks**: Tasks 34-39
  - **Blocked By**: Tasks 24-27

  **References**:
  - `.prompts/06-deployment-scripts.md:9-14` - 部署脚本要求

  **Acceptance Criteria**:
  - [ ] 代理部署成功
  - [ ] 初始化参数正确
  - [ ] 本地网络测试通过

  **QA Scenarios**:

  ```
  Scenario: 运行Token部署脚本
    Tool: Bash
    Steps:
      1. npx hardhat run scripts/deploy/deploy-token.ts --network hardhat
    Expected Result: 输出包含 ShareToken proxy 和 implementation 地址
    Evidence: .sisyphus/evidence/task-28-deploy-token.txt
  ```

  **Commit**: NO (groups with Wave 6)

- [x] 29. deploy-core.ts部署脚本

  **What to do**:
  - 创建 scripts/deploy/deploy-core.ts
  - 部署 PaymentSettlement, UsageRegistry, ProviderStaking
  - 全部使用 Transparent 代理
  - 设置合约间关系
  - 输出部署地址

  **Must NOT do**:
  - 不部署非代理版本

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6 (with Tasks 28, 30-33)
  - **Blocks**: Tasks 34-39
  - **Blocked By**: Tasks 24-27

  **References**:
  - `.prompts/06-deployment-scripts.md:15-20` - 部署脚本要求

  **Acceptance Criteria**:
  - [ ] 所有核心合约部署成功
  - [ ] 本地网络测试通过

  **QA Scenarios**:

  ```
  Scenario: 运行Core部署脚本
    Tool: Bash
    Steps:
      1. npx hardhat run scripts/deploy/deploy-core.ts --network hardhat
    Expected Result: 输出包含所有核心合约地址
    Evidence: .sisyphus/evidence/task-29-deploy-core.txt
  ```

  **Commit**: NO (groups with Wave 6)

- [x] 30. deploy-governance.ts部署脚本

  **What to do**:
  - 创建 scripts/deploy/deploy-governance.ts
  - 部署 Timelock (非代理)
  - 部署 Governor (非代理)
  - 部署 Treasury (代理)
  - 配置角色关系
  - 输出部署地址

  **Must NOT do**:
  - 对 Governor/Timelock 使用代理

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6 (with Tasks 28-29, 31-33)
  - **Blocks**: Tasks 34-39
  - **Blocked By**: Tasks 24-27

  **References**:
  - `.prompts/06-deployment-scripts.md:21-26` - 部署脚本要求

  **Acceptance Criteria**:
  - [ ] 治理合约部署成功
  - [ ] 角色配置正确
  - [ ] 本地网络测试通过

  **QA Scenarios**:

  ```
  Scenario: 运行Governance部署脚本
    Tool: Bash
    Steps:
      1. npx hardhat run scripts/deploy/deploy-governance.ts --network hardhat
    Expected Result: 输出包含所有治理合约地址
    Evidence: .sisyphus/evidence/task-30-deploy-governance.txt
  ```

  **Commit**: NO (groups with Wave 6)

- [x] 31. deploy-all.ts完整部署脚本

  **What to do**:
  - 创建 scripts/deploy/deploy-all.ts
  - 按依赖顺序部署所有合约
  - 配置所有合约间关系
  - 保存部署记录到 deployments/{network}.json
  - 输出完整部署摘要

  **Must NOT do**:
  - 不跳过部署记录保存

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6 (with Tasks 28-30, 32-33)
  - **Blocks**: Tasks 34-39
  - **Blocked By**: Tasks 24-27

  **References**:
  - `.prompts/06-deployment-scripts.md:27-31` - 部署脚本要求
  - `.prompts/06-deployment-scripts.md:68-84` - 部署记录格式

  **Acceptance Criteria**:
  - [ ] 所有合约按顺序部署
  - [ ] 部署记录保存正确
  - [ ] 本地网络测试通过

  **QA Scenarios**:

  ```
  Scenario: 运行完整部署脚本
    Tool: Bash
    Steps:
      1. npx hardhat run scripts/deploy/deploy-all.ts --network hardhat
      2. test -f deployments/hardhat.json
    Expected Result: 所有合约地址输出，部署记录文件存在
    Evidence: .sisyphus/evidence/task-31-deploy-all.txt
  ```

  **Commit**: NO (groups with Wave 6)

- [x] 32. verify-contracts.ts验证脚本

  **What to do**:
  - 创建 scripts/verify/verify-contracts.ts
  - 读取部署记录
  - 验证合约源码 (hardhat-etherscan)
  - 输出验证结果

  **Must NOT do**:
  - 不假设特定区块浏览器

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6 (with Tasks 28-31, 33)
  - **Blocks**: Tasks 34-39
  - **Blocked By**: Tasks 24-27

  **References**:
  - `.prompts/06-deployment-scripts.md:62-66` - 验证脚本要求

  **Acceptance Criteria**:
  - [ ] 验证脚本完整
  - [ ] 可配置区块浏览器

  **QA Scenarios**:

  ```
  Scenario: 验证脚本语法
    Tool: Bash
    Steps:
      1. npx tsc --noEmit scripts/verify/verify-contracts.ts
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-32-verify-script.txt
  ```

  **Commit**: NO (groups with Wave 6)

- [x] 33. 部署脚本测试

  **What to do**:
  - 创建 test/deployment/DeploymentScripts.test.ts
  - 测试所有部署脚本在本地网络运行
  - 验证部署后的合约状态
  - 验证角色配置

  **Must NOT do**:
  - 不跳过部署后状态验证

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6 (with Tasks 28-32)
  - **Blocks**: Tasks 34-39
  - **Blocked By**: Tasks 24-27

  **References**:
  - `.prompts/06-deployment-scripts.md` - 部署参考

  **Acceptance Criteria**:
  - [ ] 所有部署脚本测试通过
  - [ ] npx hardhat test test/deployment/DeploymentScripts.test.ts 全部通过

  **QA Scenarios**:

  ```
  Scenario: 运行部署脚本测试
    Tool: Bash
    Steps:
      1. npx hardhat test test/deployment/DeploymentScripts.test.ts
    Expected Result: "X passing", "0 failing"
    Evidence: .sisyphus/evidence/task-33-deploy-test.txt
  ```

  **Commit**: YES (Wave 6 完成提交)
  - Message: `feat(deploy): deployment and verification scripts`
  - Files: scripts/deploy/, scripts/verify/, test/deployment/
  - Pre-commit: npx hardhat test test/deployment/

---

### Wave 7: CI/CD和文档

- [ ] 34. test.yml工作流

  **What to do**:
  - 创建 .github/workflows/test.yml
  - 配置 npm install
  - 配置 hardhat compile
  - 配置 hardhat test
  - 配置 forge test
  - 配置覆盖率报告

  **Must NOT do**:
  - 不使用固定版本号

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 7 (with Tasks 35-39)
  - **Blocks**: Final Verification
  - **Blocked By**: Tasks 28-33

  **References**:
  - `.prompts/07-ci-cd-and-docs.md:9-14` - test.yml 要求

  **Acceptance Criteria**:
  - [ ] 工作流语法正确
  - [ ] 包含所有测试步骤

  **QA Scenarios**:

  ```
  Scenario: 验证test.yml语法
    Tool: Bash
    Steps:
      1. python -c "import yaml; yaml.safe_load(open('.github/workflows/test.yml'))"
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-34-test-yml.txt
  ```

  **Commit**: NO (groups with Wave 7)

- [ ] 35. lint.yml工作流

  **What to do**:
  - 创建 .github/workflows/lint.yml
  - 配置 solhint 检查
  - 配置 prettier 格式化检查
  - 配置 TypeScript 检查

  **Must NOT do**:
  - 不跳过任何检查步骤

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 7 (with Tasks 34, 36-39)
  - **Blocks**: Final Verification
  - **Blocked By**: Tasks 28-33

  **References**:
  - `.prompts/07-ci-cd-and-docs.md:15-19` - lint.yml 要求

  **Acceptance Criteria**:
  - [ ] 工作流语法正确
  - [ ] 包含所有检查步骤

  **QA Scenarios**:

  ```
  Scenario: 验证lint.yml语法
    Tool: Bash
    Steps:
      1. python -c "import yaml; yaml.safe_load(open('.github/workflows/lint.yml'))"
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-35-lint-yml.txt
  ```

  **Commit**: NO (groups with Wave 7)

- [ ] 36. security.yml工作流

  **What to do**:
  - 创建 .github/workflows/security.yml
  - 配置 Slither 静态分析
  - 配置依赖漏洞扫描 (npm audit)
  - 输出安全报告

  **Must NOT do**:
  - 不跳过高危漏洞检查

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 7 (with Tasks 34-35, 37-39)
  - **Blocks**: Final Verification
  - **Blocked By**: Tasks 28-33

  **References**:
  - `.prompts/07-ci-cd-and-docs.md:20-24` - security.yml 要求

  **Acceptance Criteria**:
  - [ ] 工作流语法正确
  - [ ] 包含安全扫描步骤

  **QA Scenarios**:

  ```
  Scenario: 验证security.yml语法
    Tool: Bash
    Steps:
      1. python -c "import yaml; yaml.safe_load(open('.github/workflows/security.yml'))"
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-36-security-yml.txt
  ```

  **Commit**: NO (groups with Wave 7)

- [ ] 37. deploy-testnet.yml工作流

  **What to do**:
  - 创建 .github/workflows/deploy-testnet.yml
  - 配置手动触发 (workflow_dispatch)
  - 配置部署到测试网
  - 配置合约验证
  - 配置部署记录更新

  **Must NOT do**:
  - 不使用自动触发
  - 不暴露私钥

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 7 (with Tasks 34-36, 38-39)
  - **Blocks**: Final Verification
  - **Blocked By**: Tasks 28-33

  **References**:
  - `.prompts/07-ci-cd-and-docs.md:25-29` - deploy-testnet.yml 要求

  **Acceptance Criteria**:
  - [ ] 工作流语法正确
  - [ ] 使用 secrets 管理敏感信息
  - [ ] 手动触发配置

  **QA Scenarios**:

  ```
  Scenario: 验证deploy-testnet.yml语法
    Tool: Bash
    Steps:
      1. python -c "import yaml; yaml.safe_load(open('.github/workflows/deploy-testnet.yml'))"
    Expected Result: exit code 0
    Evidence: .sisyphus/evidence/task-37-deploy-yml.txt
  ```

  **Commit**: NO (groups with Wave 7)

- [ ] 38. GitHub Issue/PR模板

  **What to do**:
  - 创建 .github/ISSUE_TEMPLATE/bug_report.md
  - 创建 .github/ISSUE_TEMPLATE/feature_request.md
  - 创建 .github/ISSUE_TEMPLATE/security_issue.md
  - 创建 .github/PULL_REQUEST_TEMPLATE.md

  **Must NOT do**:
  - 不创建过于复杂的模板

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 7 (with Tasks 34-37, 39)
  - **Blocks**: Final Verification
  - **Blocked By**: Tasks 28-33

  **References**:
  - `.prompts/07-ci-cd-and-docs.md:44-52` - GitHub模板要求

  **Acceptance Criteria**:
  - [ ] 所有模板文件存在
  - [ ] 模板内容完整

  **QA Scenarios**:

  ```
  Scenario: 验证GitHub模板
    Tool: Bash
    Steps:
      1. test -f .github/ISSUE_TEMPLATE/bug_report.md
      2. test -f .github/ISSUE_TEMPLATE/feature_request.md
      3. test -f .github/ISSUE_TEMPLATE/security_issue.md
      4. test -f .github/PULL_REQUEST_TEMPLATE.md
    Expected Result: 所有文件存在
    Evidence: .sisyphus/evidence/task-38-templates.txt
  ```

  **Commit**: NO (groups with Wave 7)

- [ ] 39. 完整架构文档

  **What to do**:
  - 更新 docs/architecture.md
  - 绘制合约架构图 (使用 Mermaid)
  - 描述合约关系
  - 描述调用流程
  - 描述安全模型
  - 描述升级策略

  **Must NOT do**:
  - 不使用过时的信息

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: 技术文档编写
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 7 (with Tasks 34-38)
  - **Blocks**: Final Verification
  - **Blocked By**: Tasks 28-33

  **References**:
  - `.prompts/07-ci-cd-and-docs.md:31-43` - 文档要求
  - `.prompts/system-prompt.md` - 系统架构参考

  **Acceptance Criteria**:
  - [ ] 架构图完整
  - [ ] 合约关系描述清晰
  - [ ] 安全模型文档化

  **QA Scenarios**:

  ````
  Scenario: 验证架构文档
    Tool: Bash
    Steps:
      1. grep -q "```mermaid" docs/architecture.md
      2. grep -q "合约架构" docs/architecture.md
    Expected Result: 文档包含架构图和描述
    Evidence: .sisyphus/evidence/task-39-architecture.txt
  ````

  **Commit**: YES (Wave 7 完成提交)
  - Message: `ci: GitHub Actions workflows and documentation`
  - Files: .github/, docs/architecture.md
  - Pre-commit: npm run lint

---

## Final Verification Wave (MANDATORY)

- [ ] F1. **Plan Compliance Audit** — `oracle`
      Verify all Must Have deliverables exist, all Must NOT Have absent.
      Output: `Must Have [N/N] | Must NOT Have [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
      Run `npx hardhat compile` + `forge build` + `npx hardhat test` + `forge test` + `npm run lint`.
      Output: `Build [PASS/FAIL] | Tests [N pass/N fail] | Lint [PASS/FAIL] | VERDICT`

- [ ] F3. **Integration QA** — `unspecified-high`
      Execute complete deployment flow on local network, verify all contracts deployed.
      Output: `Deployment [N/N contracts] | Upgrade [PASS/FAIL] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
      Verify no scope creep, all guardrails respected.
      Output: `Guardrails [N/N compliant] | Scope Creep [CLEAN/N issues] | VERDICT`

---

## Commit Strategy

每个Wave完成后单独提交：

- **Wave 1**: `chore(init): project scaffolding and configuration`
- **Wave 2**: `feat(token): ShareToken implementation with tests`
- **Wave 3**: `feat(core): PaymentSettlement, UsageRegistry, ProviderStaking`
- **Wave 4**: `feat(governance): Governor, Timelock, Treasury`
- **Wave 5**: `feat(libs): Utils library and integration tests`
- **Wave 6**: `feat(deploy): deployment and verification scripts`
- **Wave 7**: `ci: GitHub Actions workflows and documentation`

---

## Success Criteria

### Verification Commands

```bash
# 编译检查
npx hardhat compile  # Expected: exit code 0
forge build          # Expected: exit code 0

# 测试检查
npx hardhat test     # Expected: 0 failing
forge test -vvv      # Expected: "0 failed"

# 代码风格检查
npm run lint         # Expected: exit code 0
npx solhint "contracts/**/*.sol"  # Expected: exit code 0

# 本地部署检查
npx hardhat run scripts/deploy/deploy-all.ts --network hardhat  # Expected: all contract addresses printed
```

### Final Checklist

- [ ] 所有7个核心合约实现完成
- [ ] 所有3个接口定义完成
- [ ] Hardhat + Foundry 测试全部通过
- [ ] 代码风格检查通过
- [ ] 部署脚本在本地网络运行成功
- [ ] CI/CD工作流配置完成
- [ ] 架构文档完成
