# Easyntropy

Mainnet address: [`0x2a9adbbad92f37670e8E98fe86a8B2fb07681690`](https://etherscan.io/address/0x2a9adbbad92f37670e8E98fe86a8B2fb07681690)

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
