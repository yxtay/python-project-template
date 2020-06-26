ARG PYTHON_VERSION=3.7.7

##
# dev
##
FROM python:$PYTHON_VERSION AS dev
MAINTAINER wyextay@gmail.com

# set up user
ARG USER=app
RUN useradd --create-home --no-log-init --system --user-group $USER
USER $USER
ARG HOME=/home/$USER
WORKDIR $HOME

# set up python
ARG VIRTUAL_ENV=$HOME/.venv
ENV PATH=$VIRTUAL_ENV/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=60 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1
RUN python -m venv $VIRTUAL_ENV && \
    pip install --no-cache-dir --upgrade pip

# install dependencies
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt && \
    python --version && pip freeze

# copy project files
COPY Makefile Makefile
COPY src src

EXPOSE 8000
ARG ENVIRONMENT=dev
ENV ENVIRONMENT $ENVIRONMENT
CMD ["make", "run-web"]

##
# prod
##
FROM python:$PYTHON_VERSION-slim AS prod
MAINTAINER wyextay@gmail.com

RUN apt-get update && apt-get install --no-install-recommends --yes make && \
    rm -rf /var/lib/apt/lists/*

# set up user
ARG USER=app
RUN useradd --create-home --no-log-init --system --user-group $USER
USER $USER
ARG HOME=/home/$USER
WORKDIR $HOME

ARG VIRTUAL_ENV=$HOME/.venv
ENV PATH=$VIRTUAL_ENV/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=60 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1
COPY --from=dev --chown=$USER:$USER $HOME $HOME
RUN python --version && pip freeze

EXPOSE 8000
ARG ENVIRONMENT=prod
ENV ENVIRONMENT=$ENVIRONMENT
CMD ["make", "run-web"]
