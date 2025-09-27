# Easyntropy

Mainnet address: [`0x8EAfe1cBaE6426aa84AFf6D97ea48029d92a5767`](https://etherscan.io/address/0x8EAfe1cBaE6426aa84AFf6D97ea48029d92a5767)

Testnet address: [`0x62AdC8dd46E71E6dc04A8EC5304e9E9521A9D436`](https://sepolia.etherscan.io/address/0x62AdC8dd46E71E6dc04A8EC5304e9E9521A9D436)

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
