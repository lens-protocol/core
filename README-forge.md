1. Start a local node in one terminal:
```bash
anvil
```

2. In another terminal, deploy the contracts:
```bash
forge script scripts/Deploy.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```
