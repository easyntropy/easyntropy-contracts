# Easyntropy

### Development

Installation:

```bash
git submodule update --init --recursive
```

Dev env:

```bash
./scripts/run-dev-env-docker.sh
```

Tests:

```bash
./scripts/shell-docker.sh forge test -vvv
./scripts/linters-check-docker.sh
```

#### Remix IDE

Remix IDE is available at `http://localhost:8001` with access to anvil chain and local files.

- Click "Connect to Localhost" to have access to local files.
- Use Environment: "Web3 Provider" - http://127.0.0.1:8545 (default) to use local anvil chain
