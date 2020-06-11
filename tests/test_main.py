import pytest
from typer.testing import CliRunner

from src.main import app

runner = CliRunner()


def test_base():
    result = runner.invoke(app)
    assert result.exit_code == 0
    assert "Hello World!" == result.stdout.strip()


cases = ["World", "Name", "name", "NAME"]


@pytest.mark.parametrize("name", cases)
def test_arg(name):
    expected = f"Hello {name}!"

    result = runner.invoke(app, [name])
    assert result.exit_code == 0
    assert expected == result.stdout.strip()
