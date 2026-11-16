# dx.server: the same commands as every DX repo (`make help`).
# `make setup` once, then `make dev` runs the server on this machine. To run the
# whole DX stack, in Docker or not, use infra.dx.

IMAGE ?= dx-server:local
# The chart renderer imports rawgraphs-charts/lib. By default `make charts`
# builds the commit the Dockerfile pins; RAWGRAPHS_DIR=../rawgraphs-charts
# builds your own checkout instead, to try chart changes.
RAWGRAPHS_REPO := https://github.com/zimmerman-team/rawgraphs-charts.git
RAWGRAPHS_REF := $(shell sed -n 's/^ARG RAWGRAPHS_REF=//p' Dockerfile)
RAWGRAPHS_DIR ?=

.DEFAULT_GOAL := help
.PHONY: help setup charts dev build logs migrate lint node-version

help: ## List the commands
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-10s %s\n", $$1, $$2}'

setup: node-version ## Install dependencies, build rawgraphs-charts, create .env
	yarn install
	@$(MAKE) --no-print-directory charts
	@[ -f .env ] || { cp .env.example .env && echo "Created .env from .env.example"; }

charts: ## Build rawgraphs-charts into rawgraphs-charts/ (RAWGRAPHS_DIR=../rawgraphs-charts for your checkout)
ifeq ($(RAWGRAPHS_DIR),)
	@if [ "$$(git -C rawgraphs-charts rev-parse HEAD 2>/dev/null)" != "$(RAWGRAPHS_REF)" ]; then \
	  rm -rf rawgraphs-charts && mkdir rawgraphs-charts && cd rawgraphs-charts && \
	  git init -q && git remote add origin $(RAWGRAPHS_REPO) && \
	  git fetch -q --depth 1 origin $(RAWGRAPHS_REF) && git checkout -q FETCH_HEAD && \
	  echo "rawgraphs-charts: checked out $(RAWGRAPHS_REF)"; \
	fi
	cd rawgraphs-charts && yarn install && npx rollup -c
else
	@[ -d "$(RAWGRAPHS_DIR)" ] || { echo "No $(RAWGRAPHS_DIR)." >&2; exit 1; }
	cd "$(RAWGRAPHS_DIR)" && yarn install && npx rollup -c
	rm -rf rawgraphs-charts
	cp -R "$(RAWGRAPHS_DIR)" rawgraphs-charts
endif

dev: ## Run the server on http://localhost:4200, restarting on changes
	@[ -f .env ] || { echo "No .env yet: run make setup." >&2; exit 1; }
	@[ -f rawgraphs-charts/lib/index.es.js ] || { echo "rawgraphs-charts isn't built: run make setup." >&2; exit 1; }
	yarn dev

build: ## Build the Docker image, as CI does
	docker build -t $(IMAGE) .

logs: ## Follow the server's log file
	tail -f logging/dx_server.log

migrate: ## Update the database schema (ARGS=--rebuild drops and recreates it)
	yarn migrate $(ARGS)

lint: ## Check code style
	yarn lint

node-version:
	@want="$$(cut -d. -f1 .nvmrc)"; have="$$(node --version 2>/dev/null | sed 's/^v//; s/\..*//')"; \
	[ "$$want" = "$$have" ] || echo "Note: this repo uses Node $$(cat .nvmrc) (.nvmrc) and you have $$(node --version 2>/dev/null || echo none). Run: nvm use"
