##
# builder
##
FROM python:3.8.3 AS builder
MAINTAINER wyextay@gmail.com

# set up user
ARG USER=app
RUN useradd --create-home --no-log-init --system --user-group $USER
USER $USER
ARG HOME=/home/$USER
WORKDIR $HOME

# set up python
ARG VIRTUAL_ENV=$HOME/.venv
ENV PATH=$VIRTUAL_ENV/bin:$PATH
RUN python -m venv $VIRTUAL_ENV && \
    pip install --no-cache-dir --upgrade pip

# install dependencies
COPY requirements/main.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt && \
    python --version && \
    pip freeze

# copy project files
COPY Makefile Makefile
COPY src src

EXPOSE 8000
ARG ENVIRONMENT=prod
ENV ENVIRONMENT $ENVIRONMENT
CMD ["make", "run-web"]

##
# app
##
FROM python:3.8.3-slim AS app
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
ENV PATH=$VIRTUAL_ENV/bin:$PATH
COPY --from=builder --chown=$USER:$USER $HOME $HOME

EXPOSE 8000
ARG ENVIRONMENT=prod
ENV ENVIRONMENT=$ENVIRONMENT
CMD ["make", "run-web"]
