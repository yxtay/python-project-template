## options
# based on https://tech.davis-hansson.com/p/make/
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

## variables

ENVIRONMENT ?= dev
ARGS =
APP_NAME = $(shell python -m src.config app_name)
SOURCE_DIR := src
TEST_DIR := tests

IMAGE_HOST = $(shell python -m src.config image_host)
IMAGE_REPO = $(shell python -m src.config image_repo)
IMAGE_NAME = $(IMAGE_HOST)/$(IMAGE_REPO)/$(APP_NAME)
IMAGE_TAG ?= latest

## formula

# based on https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help:  ## print help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

## dependencies

.PHONY: deps-install
deps-install:  ## install dependencies
	python -m pip install poetry
	python -m poetry install --no-root

.PHONY: deps-install-ci
deps-install-ci:
	python -m pip install poetry
	python -m poetry config virtualenvs.create false
	python -m poetry install --no-root
	python -m poetry show

.PHONY: deps-update
deps-update:
	python -m poetry update
	python -m poetry export --format requirements.txt --output requirements.txt --without-hashes

requirements.txt: poetry.lock
	python -m poetry export --format requirements.txt --output requirements.txt --without-hashes

requirements-dev.txt: poetry.lock
	python -m poetry export --with dev --format requirements.txt --output requirements-dev.txt --without-hashes

## checks

.PHONY: format
format:
	python -m ruff check --fix .
	python -m isort .
	python -m black $(SOURCE_DIR) $(TEST_DIR)

.PHONY: lint
lint:
	python -m ruff check .
	python -m isort . --check --diff
	python -m black $(SOURCE_DIR) $(TEST_DIR) --diff
	python -m bandit -r $(SOURCE_DIR) -lll -iii
	python -m mypy $(SOURCE_DIR)

.PHONY: test
test:
	python -m pytest $(TEST_DIR) --cov $(SOURCE_DIR)

.PHONY: run-ci
run-ci: deps-install-ci lint test  ## run ci

## app

.PHONY: run-task
run-task:  ## run python task
	python -m src.task

.PHONY: run-web-dev
run-web-dev:
	python -m uvicorn src.web:app --reload

.PHONY: run-web
run-web:  ## run python web
	python -m gunicorn src.web:app -c src/gunicorn_conf.py

.PHONY: run
run: run-web  ## run main python app

## docker-compose

.PHONY: dc-build
dc-build: requirements.txt  ## build app image
	IMAGE_TAG=$(IMAGE_TAG) docker compose build

.PHONY: dc-push
dc-push:
	IMAGE_TAG=$(IMAGE_TAG) docker compose push

.PHONY: dc-up
dc-up:  ## run app image
	docker compose up web_dev

.PHONY: dc-exec
dc-exec:
	docker compose exec web_dev /bin/bash

.PHONY: dc-stop
dc-stop:
	docker compose stop

.PHONY: dc-down
dc-down:
	docker compose down
