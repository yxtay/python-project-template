ARG PYTHON_VERSION=3.8

##
# dev
##
FROM python:${PYTHON_VERSION} AS dev
LABEL maintainer="wyextay@gmail.com"

# set up user
ARG USER=nonroot
RUN useradd --create-home --no-log-init --system --user-group ${USER}
USER ${USER}
ARG HOME=/home/${USER}
WORKDIR ${HOME}/app

# set up python
ARG VIRTUAL_ENV=${HOME}/.venv
ENV PATH=${VIRTUAL_ENV}/bin:${PATH} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=60 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1
RUN python -m venv ${VIRTUAL_ENV} && \
    pip install --upgrade pip

# install dependencies
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt && \
    python --version && pip list

# copy project files
COPY Makefile Makefile
COPY configs configs
COPY src src

EXPOSE 8000
ARG ENVIRONMENT=dev
ENV ENVIRONMENT ${ENVIRONMENT}
CMD ["make", "run"]

##
# prod
##
FROM python:${PYTHON_VERSION}-slim AS prod
LABEL maintainer="wyextay@gmail.com"

RUN apt-get update && apt-get install --no-install-recommends --yes make && \
    rm -rf /var/lib/apt/lists/*

# set up user
ARG USER=nonroot
RUN useradd --create-home --no-log-init --system --user-group ${USER}
USER ${USER}
ARG HOME=/home/${USER}
WORKDIR ${HOME}/app

ARG VIRTUAL_ENV=${HOME}/.venv
ENV PATH=${VIRTUAL_ENV}/bin:${PATH} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=60 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1
COPY --from=dev --chown=${USER}:${USER} ${HOME} ${HOME}
RUN python --version && pip list

EXPOSE 8000
ARG ENVIRONMENT=prod
ENV ENVIRONMENT=${ENVIRONMENT}
CMD ["make", "run"]
