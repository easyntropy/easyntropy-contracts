# Easyntropy

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
