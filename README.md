# Easyntropy

Mainnet address: [`0x8EAfe1cBaE6426aa84AFf6D97ea48029d92a5767`](https://etherscan.io/address/0x8EAfe1cBaE6426aa84AFf6D97ea48029d92a5767)

Testnet address: [`0xFc3f5cDAE509d98d8Ef6e1bdCB335ba55Cf68628`](https://sepolia.etherscan.io/address/0xFc3f5cDAE509d98d8Ef6e1bdCB335ba55Cf68628)

### Development

Installation:

```bash
git submodule update --init --recursive
```

Run local anvil:

```bash
./scripts/run-dev-env-docker.sh support
```

Tests:

```bash
  ./scripts/run-dev-env-docker.sh shell yarn
  ./scripts/run-dev-env-docker.sh shell yarn run lint

  ./scripts/run-dev-env-docker.sh shell forge test --summary --detailed -vvv
```
