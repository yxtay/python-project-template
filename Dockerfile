##
# base
##
FROM python:3.7.6-slim AS base
MAINTAINER wyextay@gmail.com

RUN apt-get update && apt-get install --no-install-recommends --yes \
    make \
    && rm -rf /var/lib/apt/lists/*

# set up user
RUN groupadd -g 999 appuser && \
    useradd -r -u 999 -g appuser --create-home appuser

# set up environment
ENV HOME=/home/appuser
ENV VIRTUAL_ENV=$HOME/.venv
ENV PATH=$VIRTUAL_ENV/bin:$PATH
WORKDIR $HOME

# set up python
USER appuser
RUN python -m venv $VIRTUAL_ENV && \
    pip install --no-cache-dir --upgrade pip

##
# builder
##
FROM base as builder
USER root

USER appuser
COPY requirements/main.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt && \
    python --version && \
    pip freeze

COPY Makefile Makefile
COPY src src

ARG ENVIRONMENT=prod
ENV ENVIRONMENT $ENVIRONMENT
CMD ["make", "serve"]

##
# app
##
FROM base AS app
USER appuser

COPY --from=builder --chown=appuser:appuser $HOME $HOME

ARG ENVIRONMENT=prod
ENV ENVIRONMENT=$ENVIRONMENT
EXPOSE 8000
CMD ["make", "serve"]
