import pytest
from typer.testing import CliRunner

from src.config import app

runner = CliRunner()


def test_base():
    result = runner.invoke(app, ["environment"])
    assert result.exit_code == 0
    assert "dev" == result.stdout.strip()

    result = runner.invoke(app, ["name"])
    assert result.exit_code == 0
    assert "World" == result.stdout.strip()


case = ["dev", "stg", "prod"]


@pytest.mark.parametrize("environment", case)
def test_env(environment):
    env = {"ENVIRONMENT": environment}

    result = runner.invoke(app, ["environment"], env=env)
    assert result.exit_code == 0
    assert environment == result.stdout.strip()

    result = runner.invoke(app, ["name"])
    assert result.exit_code == 0
    assert "World" == result.stdout.strip()
