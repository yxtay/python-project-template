ARG PYTHON_VERSION=3.12

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
ENV PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=${HOME}/.venv
ENV PATH=${VIRTUAL_ENV}/bin:${PATH}

ARG WORKDIR=${HOME}/app
WORKDIR ${WORKDIR}

##
# dev
##
FROM base AS dev

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        build-essential \
        curl \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_COMPILE=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=0

# set up python
RUN --mount=type=cache,target=${HOME}/.cache/pip \
    pip install poetry && \
    python -m venv --upgrade-deps ${VIRTUAL_ENV} && \
    chown -R ${USER}:${USER} ${HOME}
COPY --chown=${USER}:${USER} pyproject.toml poetry.lock ./
RUN --mount=type=cache,target=${HOME}/.cache/pypoetry \
    poetry install --only main && \
    python --version && \
    pip list

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
    poetry install && \
    pip list

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
COPY --from=dev --chown=${USER}:${USER} ${VIRTUAL_ENV} ${VIRTUAL_ENV}
COPY --from=dev --chown=${USER}:${USER} ${WORKDIR} ${WORKDIR}

EXPOSE 8000
ARG ENVIRONMENT=prod
ENV ENVIRONMENT=${ENVIRONMENT}
CMD ["gunicorn", "src.web:app", "-c", "src/gunicorn_conf.py"]
