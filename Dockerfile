# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11

##
# dev
##
FROM python:${PYTHON_VERSION} AS dev
LABEL maintainer="wyextay@gmail.com"

# set up user
ARG USER=app
ARG GROUP=${USER}
ARG UID=1000
ARG GID=${UID}
ARG WORKDIR=/home/${USER}/app
RUN groupadd --gid ${GID} ${GROUP} \
    && useradd --gid ${GID} --uid ${UID} ${USER}
USER ${USER}
WORKDIR ${WORKDIR}

# set up python
ARG VIRTUAL_ENV=/home/${USER}/.venv
ENV PATH=${VIRTUAL_ENV}/bin:${PATH} \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1
RUN python -m venv ${VIRTUAL_ENV}

# install dependencies
COPY requirements.txt requirements.txt
RUN --mount=type=cache,target=/root/.cache \
    python -m pip install --no-compile -r requirements.txt \
    && python --version \
    && pip list

# copy project files
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
ARG USER=app
ARG GROUP=${USER}
ARG UID=1000
ARG GID=${UID}
ARG WORKDIR=/home/${USER}/app
RUN groupadd --gid ${GID} ${GROUP} \
    && useradd --gid ${GID} --uid ${UID} ${USER}
USER ${USER}
WORKDIR ${WORKDIR}

# set up python
ARG VIRTUAL_ENV=/home/${USER}/.venv
ENV PATH=${VIRTUAL_ENV}/bin:${PATH} \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1
COPY --from=dev ${VIRTUAL_ENV} ${VIRTUAL_ENV}
RUN python --version && pip list

COPY --from=dev ${WORKDIR} ${WORKDIR}

ARG ENVIRONMENT=prod
ENV ENVIRONMENT=${ENVIRONMENT}
EXPOSE 8000
CMD ["gunicorn", "src.web:app", "-c", "src/gunicorn_conf.py"]
