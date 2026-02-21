# Deployment Records

This directory contains the deployment records for the smart contracts.

## Record Format

Each deployment should be recorded in a JSON file named after the network (e.g., `mainnet.json`, `sepolia.json`).

The format for each entry should be:

```json
{
  "contractName": "ContractName",
  "address": "0x...",
  "transactionHash": "0x...",
  "args": [],
  "implementation": "0x...",
  "version": "1.0.0",
  "timestamp": "2026-02-21T..."
}
```

- `contractName`: The name of the deployed contract.
- `address`: The address of the deployed contract (proxy address if applicable).
- `transactionHash`: The hash of the deployment transaction.
- `args`: Constructor or initializer arguments.
- `implementation`: The address of the implementation contract (for upgradeable contracts).
- `version`: The version of the contract.
- `timestamp`: ISO 8601 timestamp of the deployment.
