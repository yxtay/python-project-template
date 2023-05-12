# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11

##
# base
##
FROM python:${PYTHON_VERSION}-slim AS base
LABEL maintainer="wyextay@gmail.com"

# set up user
ARG USER=user
ARG UID=1000
ARG HOME=/home/${USER}
RUN useradd --create-home --uid ${UID} --user-group ${USER}

# set up environment
ARG VIRTUAL_ENV=${HOME}/.venv
ENV PATH=${VIRTUAL_ENV}/bin:${HOME}/.local/bin:${PATH} \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1

##
# dev
##
FROM base AS dev

RUN target=/var/cache/apt \
    apt-get update \
    && apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# set up python
WORKDIR ${HOME}
COPY pyproject.toml poetry.lock ./
RUN --mount=type=cache,target=${HOME}/.cache/pypoetry \
    curl -sSL https://install.python-poetry.org | python \
    && poetry config virtualenvs.in-project true \
    && poetry install --only main --no-root \
    && python --version \
    && poetry show

# set up project
USER ${USER}
WORKDIR ${HOME}/app
COPY configs configs
COPY src src

EXPOSE 8000
ARG ENVIRONMENT=dev
ENV ENVIRONMENT ${ENVIRONMENT}
CMD ["gunicorn", "src.web:app", "-c", "src/gunicorn_conf.py"]

##
# prod
##
FROM base AS prod

# set up project
USER ${USER}
WORKDIR ${HOME}/app
COPY --from=dev --chown=${USER}:${USER} ${VIRTUAL_ENV} ${VIRTUAL_ENV}
COPY --from=dev ${HOME}/app ${HOME}/app

EXPOSE 8000
ARG ENVIRONMENT=prod
ENV ENVIRONMENT=${ENVIRONMENT}
CMD ["gunicorn", "src.web:app", "-c", "src/gunicorn_conf.py"]
