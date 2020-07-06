# Python Project Template

Starter template for python projects

## Features

- environment, packages and dependency management
- continuous integration
  - code formatting with isort and black
  - code linting with isort, black, flake8 and mypy
  - unit tests with pytest
  - pre-commit hooks
- application
  - logging with standard logging and python-json-logger
  - configuration with standard configparser, python-dotenv and pydantic
  - command line with typer
  - web service with fastapi, uvicorn and gunicorn
  - commands managed with make
- deployment with Docker

## Environment, package and dependency management

Use Conda to create a virtual environment and activate it for the project.

```bash
PROJECT_NAME = python-project-template
PYTHON_VERSION = 3.7
conda create --name $PROJECT_NAME --yes python=$PYTHON_VERSION

conda activate $PROJECT_NAME
```

Install Poetry with pip and use it to install packages and manage 
dependencies. While this is not the recommended usage of Poetry, it 
makes fewer assumption on the tools installed on the developer's 
machine and better facilitates collaboration. 

Developers may easily install all project dependencies with Poetry 
and start collaborating.

```bash
pip install Poetry
poetry install

# using make
make deps-install
```

Dependencies are tracked in `pyproject.toml`. Use Poetry to add them. 
Poetry will resolve the dependency graph of all the dependencies, 
install/uninstall them in the environment and track them in `poetry.lock`.

NOTE: Poetry must be included as a development dependency to prevent
Poetry from uninstalling its own dependencies.

```bash
# development dependency
poetry add --dev poetry

# project dependency
poetry add pydantic
``` 
