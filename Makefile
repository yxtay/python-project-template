MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

ENVIRONMENT ?= dev
ARGS =
APP_NAME = $(shell python -m src.config app_name)
SOURCE_DIR := src
TEST_DIR := tests

IMAGE_HOST := docker.io
IMAGE_REPO := yxtay
IMAGE_NAME = $(IMAGE_HOST)/$(IMAGE_REPO)/$(APP_NAME)
IMAGE_TAG ?= latest

.PHONY: help
help:  ## print help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

## dependencies

.PHONY: deps-install
deps-install:  ## install dependencies
	pip install poetry
	poetry install --no-root

.PHONY: deps-update
deps-update:
	pip install poetry
	poetry update

requirements.txt: poetry.lock
	poetry export --format requirements.txt --output requirements.txt --without-hashes

## checks

.PHONY: format
format:
	isort --apply
	black $(SOURCE_DIR) $(TEST_DIR)

.PHONY: lint
lint:
	isort --check-only
	black $(SOURCE_DIR) $(TEST_DIR) --diff
	flake8 $(SOURCE_DIR) $(TEST_DIR)
	mypy $(SOURCE_DIR)

.PHONY: test
test:
	pytest $(TEST_DIR) --cov $(SOURCE_DIR)

.PHONY: run-ci
run-ci: deps-install lint test  ## run ci

## app

.PHONY: run-task
run-task:  ## run python task
	python -m src.task

.PHONY: run-web-dev
run-web-dev:
	uvicorn src.web:app --reload

.PHONY: run-web
run-web:  ## run python web
	gunicorn src.web:app -c src/gunicorn_conf.py

.PHONY: run
run: run-web  ## run main python app

## docker

.PHONY: docker-build
docker-build: requirements.txt  ## build app image
	docker pull $(IMAGE_NAME):dev || true
	docker build . \
		--build-arg ENVIRONMENT=$(ENVIRONMENT) \
		--cache-from $(IMAGE_NAME):dev \
		--tag $(IMAGE_NAME):dev \
		--target dev
	docker pull $(IMAGE_NAME):latest || true
	docker build . \
		--build-arg ENVIRONMENT=$(ENVIRONMENT) \
		--cache-from $(IMAGE_NAME):dev \
		--cache-from $(IMAGE_NAME):latest \
		--tag $(IMAGE_NAME):$(IMAGE_TAG) \
		--target prod

.PHONY: docker-push
docker-push:
	docker push $(IMAGE_NAME):dev || true
	docker push $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: docker-run
docker-run:  ## run app image
	docker run --rm \
	    --mount type=bind,source=$(shell pwd),target=/home/app \
		-e ENVIRONMENT=$(ENVIRONMENT) \
		-p 8000:8000 \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		$(ARGS)

.PHONY: docker-exec
docker-exec:
	docker exec -it \
		$(shell docker ps -q  --filter ancestor=$(IMAGE_NAME):$(IMAGE_TAG)) \
		/bin/bash

.PHONY: docker-stop
docker-stop:
	docker stop \
		$(shell docker ps -q  --filter ancestor=$(IMAGE_NAME):$(IMAGE_TAG))
