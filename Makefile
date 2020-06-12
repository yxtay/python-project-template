MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

ENVIRONMENT ?= dev
ARGS =
APP_NAME = $(shell python -m src.config app_name)
SOURCE_DIR = src
TEST_DIR = tests

IMAGE_HOST := docker.io
IMAGE_REPO := yxtay
IMAGE_NAME := $(IMAGE_HOST)/$(IMAGE_REPO)/$(APP_NAME)
IMAGE_TAG ?= latest

## main

.PHONY: install
install: install-requirements  ## install requirements

.PHONY: ci
ci: install check test  ## steps to complete CI

.PHONY: run
run: task  ## run main task

.PHONY: serve
serve: gunicorn  ## serve web application

.PHONY: container-run
container-run: docker-run  ## run app in container image

## dependencies

.PHONY: update-requirements
update-requirements:  ## update requirements
	pip install --upgrade pip setuptools pip-tools
	pip-compile --upgrade --build-isolation --output-file requirements/main.txt requirements/main.in
	pip-compile --upgrade --build-isolation --output-file requirements/dev.txt requirements/dev.in

.PHONY: install-requirements
install-requirements:  ## install requirements
	pip install -r requirements/main.txt -r requirements/dev.txt

## checks

.PHONY: format
format:  ## python formatter
	black $(SOURCE_DIR) $(TEST_DIR)

.PHONY: check
check:  ## python linter
	black $(SOURCE_DIR) $(TEST_DIR) --diff
	isort --check-only
	flake8 $(SOURCE_DIR) $(TEST_DIR)
	mypy $(SOURCE_DIR)

.PHONY: test
test:  ## python test
	pytest $(TEST_DIR) --cov $(SOURCE_DIR)

## app

.PHONY: task
task:
	python -m src.task

.PHONY: web
web:
	python -m src.web

.PHONY: gunicorn
gunicorn:
	gunicorn src.web:app -c src/gunicorn_conf.py

## dockerm

.PHONY: docker-build
docker-builder:  ## build app image builder
	docker pull $(IMAGE_NAME):builder || true
	docker build . \
		--build-arg ENVIRONMENT=$(ENVIRONMENT) \
		--cache-from $(IMAGE_NAME):builder \
		--tag $(IMAGE_NAME):builder \
		--target builder

.PHONY: docker-build
docker-build:  ## build app image
	docker pull $(IMAGE_NAME):builder || true
	docker pull $(IMAGE_NAME):latest || true
	docker build . \
		--build-arg ENVIRONMENT=$(ENVIRONMENT) \
		--cache-from $(IMAGE_NAME):builder \
		--cache-from $(IMAGE_NAME):latest \
		--tag $(IMAGE_NAME):$(IMAGE_TAG) \
		--target app

.PHONY: docker-push
docker-push:  ## push app image
	docker push $(IMAGE_NAME):builder || true
	docker push $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: docker-run
docker-run:  ## run app image
	docker run --rm \
		-e ENVIRONMENT=$(ENVIRONMENT) \
		-p 8000:8000 \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		$(ARGS)

.PHONY: docker-exec
docker-exec:  ## exec app image
	docker exec -it \
		$(shell docker ps -q  --filter ancestor=$(IMAGE_NAME):$(IMAGE_TAG)) \
		/bin/bash

.PHONY: docker-stop
docker-stop:  ## terminate app image run
	docker stop \
	  $(shell docker ps -q  --filter ancestor=$(IMAGE_NAME):$(IMAGE_TAG))
