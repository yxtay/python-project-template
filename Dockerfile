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
ENV PATH=${VIRTUAL_ENV}/bin:${PATH} \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1

##
# dev
##
FROM base AS dev

RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update \
    && apt-get install --no-install-recommends -y \
        build-essential \
    curl

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_COMPILE=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=0

# set up python
WORKDIR ${HOME}/app
COPY --chown=${USER}:${USER} pyproject.toml poetry.lock ./
RUN --mount=type=cache,target=${HOME}/.cache/pip \
    python -m pip install poetry \
    && python -m venv ${VIRTUAL_ENV} \
    && chown -R ${USER}:${USER} ${HOME}
RUN --mount=type=cache,target=${HOME}/.cache/pypoetry \
    poetry install --only main \
    && python --version \
    && pip list

# set up project
USER ${USER}
COPY --chown=${USER}:${USER} configs configs
COPY --chown=${USER}:${USER} src src

EXPOSE 8000
ARG ENVIRONMENT=dev
ENV ENVIRONMENT ${ENVIRONMENT}
CMD ["gunicorn", "src.web:app", "-c", "src/gunicorn_conf.py"]

##
# ci
##
FROM dev AS ci

USER root
RUN --mount=type=cache,target=${HOME}/.cache/pypoetry \
    poetry install \
    && pip list

USER ${USER}
COPY --chown=${USER}:${USER} tests tests
COPY --chown=${USER}:${USER} Makefile Makefile

CMD ["make", "lint", "test"]

##
# prod
##
FROM base AS prod

# set up project
USER ${USER}
WORKDIR ${HOME}/app
COPY --from=dev --chown=${USER}:${USER} ${VIRTUAL_ENV} ${VIRTUAL_ENV}
COPY --from=dev --chown=${USER}:${USER} ${HOME}/app ${HOME}/app

EXPOSE 8000
ARG ENVIRONMENT=prod
ENV ENVIRONMENT=${ENVIRONMENT}
CMD ["gunicorn", "src.web:app", "-c", "src/gunicorn_conf.py"]
