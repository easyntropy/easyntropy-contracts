#!/bin/bash

COMMAND="$@"

COMPOSE_MENU=0 \
docker compose \
  -f ./scripts/support/dev-env-docker-compose.yml \
  run --remove-orphans shell -lc "${COMMAND:-/bin/bash}"