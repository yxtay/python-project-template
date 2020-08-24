import pytest  # type: ignore
from typer.testing import CliRunner

from src.task import app

runner = CliRunner()
cases = ["World", "Name", "name", "NAME"]


def test_base():
    expected = "Hello World!"

    result = runner.invoke(app)
    assert result.exit_code == 0
    assert result.stdout.strip() == expected


@pytest.mark.parametrize("name", cases)
def test_arg(name: str):
    expected = f"Hello {name}!"

    result = runner.invoke(app, [name])
    assert result.exit_code == 0
    assert result.stdout.strip() == expected
