import os

import typer
from pydantic import BaseSettings


class DevelopmentConfig(BaseSettings):
    environment: str = "dev"
    name: str

    class Config:
        env_file = ".env"


class StagingConfig(DevelopmentConfig):
    environment: str = "stg"


class ProductionConfig(DevelopmentConfig):
    environment: str = "prod"


def get_config(environment: str = os.environ.get("ENVIRONMENT", "dev")):
    configs = {
        "dev": DevelopmentConfig(),
        "stg": StagingConfig(),
        "prod": ProductionConfig(),
    }
    return configs[environment]


config = get_config()
app = typer.Typer()


@app.command()
def main(key: str):
    """
    Print config value of specified key.
    """
    typer.echo(config.dict().get(key))


if __name__ == "__main__":
    app()
