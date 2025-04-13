#!/bin/bash

COMMAND=$1
shift
ARGS="$@"


case "$COMMAND" in
  shell)
    if [ -z "$ARGS" ]; then
      COMPOSE_MENU=0 docker compose -f ./scripts/support/dev-env-docker-compose.yml run $([ -z "$NO_PORT" ] && echo '-p 3000:3000 -p 3001:3001') --remove-orphans shell bash
    else
      COMPOSE_MENU=0 docker compose -f ./scripts/support/dev-env-docker-compose.yml run $([ -z "$NO_PORT" ] && echo '-p 3000:3000 -p 3001:3001') --remove-orphans shell "$ARGS"
    fi
    ;;

  support)
    COMPOSE_MENU=0 docker compose -f ./scripts/support/dev-env-docker-compose.yml up --build anvil
    COMPOSE_MENU=0 docker compose -f ./scripts/support/dev-env-docker-compose.yml down
    ;;

  *)
    echo "Usage: $0 {shell|support}"
    ;;
esac
