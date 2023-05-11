# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11

##
# dev
##
FROM python:${PYTHON_VERSION} AS dev
LABEL maintainer="wyextay@gmail.com"

# set up user
ARG USER=user
ARG UID=1000
ARG HOME=/home/${USER}
RUN useradd --uid ${UID} --user-group ${USER}

# set up python
ARG VIRTUAL_ENV=${HOME}/.venv
ENV PATH=${VIRTUAL_ENV}/bin:${HOME}/.local/bin:${PATH} \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1
WORKDIR ${HOME}
COPY pyproject.toml poetry.lock ./
RUN --mount=type=cache,target=${HOME}/.cache \
    pip install --no-compile poetry \
    && python -m poetry install --only main --no-root \
    && python --version \
    && pip list

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
FROM python:${PYTHON_VERSION}-slim AS prod
LABEL maintainer="wyextay@gmail.com"

# set up user
ARG USER=user
ARG UID=1000
ARG HOME=/home/${USER}
RUN useradd --uid ${UID} --user-group ${USER}

# set up python
ARG VIRTUAL_ENV=${HOME}/.venv
ENV PATH=${VIRTUAL_ENV}/bin:${PATH} \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1
COPY --from=dev ${VIRTUAL_ENV} ${VIRTUAL_ENV}

# set up project
USER ${USER}
WORKDIR ${HOME}/app
COPY --from=dev ${HOME}/app ${HOME}/app

EXPOSE 8000
ARG ENVIRONMENT=prod
ENV ENVIRONMENT=${ENVIRONMENT}
CMD ["gunicorn", "src.web:app", "-c", "src/gunicorn_conf.py"]
