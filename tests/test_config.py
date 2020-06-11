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
