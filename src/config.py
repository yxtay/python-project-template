import os
from functools import lru_cache
from typing import Any

import typer
from pydantic import BaseSettings

from src.logger import configure_log_handlers, get_logger


class DevelopmentConfig(BaseSettings):
    app_name: str = "python-project-template"
    environment: str = "dev"

    # logging
    log_console: bool = True
    log_file: str = "main.log"

    message: str = "default message"

    class Config:
        env_file = ".env"


class StagingConfig(DevelopmentConfig):
    environment = "stg"
    log_file = ""


class ProductionConfig(DevelopmentConfig):
    environment = "prod"
    log_file = ""


@lru_cache(128)
def get_config(
    environment: str = os.environ.get("ENVIRONMENT", "dev"), **kwargs: Any
) -> DevelopmentConfig:
    configs = {
        "dev": DevelopmentConfig,
        "stg": StagingConfig,
        "prod": ProductionConfig,
    }
    return configs[environment](**kwargs)


config = get_config()

# config logger
configure_log_handlers(config.log_console, config.log_file)
logger = get_logger(config.app_name)
logger.debug("config", extra={"config": config.dict()})


def main(key: str) -> None:
    """
    Print config value of specified key.
    """
    typer.echo(config.dict().get(key))


if __name__ == "__main__":
    typer.run(main)
