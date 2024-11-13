#!/bin/bash

COMPOSE_MENU=0 docker compose -f ./scripts/support/dev-env-docker-compose.yml up --build
COMPOSE_MENU=0 docker compose -f ./scripts/support/dev-env-docker-compose.yml down