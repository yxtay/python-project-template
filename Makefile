MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

SOURCE_DIR = src
TEST_DIR = tests

## main

.PHONY: install
install: install-requirements  # test

.PHONY: ci
ci: install check test

run: task

serve: gunicorn

## dependencies

.PHONY: update-requirements
update-requirements:
	pip install --upgrade pip setuptools pip-tools
	pip-compile --upgrade --build-isolation --output-file requirements/main.txt requirements/main.in
	pip-compile --upgrade --build-isolation --output-file requirements/dev.txt requirements/dev.in

.PHONY: install-requirements
install-requirements:
	pip install -r requirements/main.txt -r requirements/dev.txt

## checks

.PHONY: format
format:
	black $(SOURCE_DIR) $(TEST_DIR)

.PHONY: check
check:
	black $(SOURCE_DIR) $(TEST_DIR) --diff
	isort --check-only
	flake8 $(SOURCE_DIR) $(TEST_DIR)
	mypy $(SOURCE_DIR)

.PHONY: test
test:
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
