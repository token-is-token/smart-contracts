# Problems - LLM Share Network Smart Contracts

## Template

```
## [Date] Problem: [Title]
- **Context**:
- **Attempted Solutions**:
- **Current Blocker**:
- **Next Steps**:
```

---

(No problems yet - starting fresh project)

## [2026-02-21] Problem: Foundry fuzz 测试在缺少 forge-std / forge 的环境下如何落地
- **Context**: 需要新增 Foundry fuzz 测试，但环境中 `forge` 未安装，仓库也未 vendor `forge-std`。
- **Attempted Solutions**:
  - 直接运行 `forge test`（失败：command not found）。
  - 使用 OpenCode `lsp_diagnostics` 检查 .sol（失败：未配置 Solidity LSP）。
- **Current Blocker**: 无法在当前环境执行实际编译/测试验证。
- **Next Steps**:
  - 安装 Foundry 后运行 `forge test --match-contract ShareTokenFuzz`。
  - 如需要更标准的断言/cheatcodes API，可再引入 `forge-std` 并将测试继承 `forge-std/Test.sol`。
