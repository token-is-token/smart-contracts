# Issues - LLM Share Network Smart Contracts

## Template

```
## [Date] Issue: [Title]
- **Severity**: Critical/High/Medium/Low
- **Status**: Open/In Progress/Resolved
- **Description**:
- **Solution**:
```

---

(No issues yet - starting fresh project)

## [2026-02-21] Issue: OpenZeppelin v5.4.0 requires Solidity ^0.8.20 (Hardhat/Foundry configured for 0.8.19)
- **Severity**: Critical
- **Status**: Open
- **Description**: `npx hardhat compile` fails with HH606 because `@openzeppelin/contracts(-upgradeable)@5.4.0` sources use `pragma solidity ^0.8.20`, while `hardhat.config.ts` pins compiler to `0.8.19` (Foundry also `solc_version = '0.8.19'`). Any contract importing OZ v5 cannot compile under 0.8.19.
- **Solution**: Bump Hardhat compiler version (and Foundry `solc_version`) to `0.8.20` (or configure multi-compiler with 0.8.20), or downgrade OZ dependencies to a 0.8.19-compatible major version.

## [2026-02-21] Issue: 本地环境缺少 forge + Solidity LSP，无法执行 Foundry 验证与 lsp_diagnostics
- **Severity**: Medium
- **Status**: Open
- **Description**:
  - `forge` 命令不存在，无法运行 `forge test --match-contract ShareTokenFuzz`。
  - 当前 OpenCode 环境未配置 .sol 的 LSP server，`lsp_diagnostics` 无法对 Solidity 文件出诊断。
- **Solution**:
  - 安装 Foundry（forge/cast/anvil），再运行目标测试命令。
  - 选用 solidity-language-server / solc LSP，并在 `oh-my-opencode.json` 里为 `.sol` 配置 LSP（或在 CI 中用 `forge build/test` 作为语法与类型检查替代）。
