from itertools import product

import pytest
from fastapi import status
from fastapi.testclient import TestClient

from src.web import app

client = TestClient(app)

greetings = ["Hello", "Hi", "Hola"]
names = ["World", "Name", "name", "NAME"]


def test_base() -> None:
    message = "Hello World!"
    expected = {"message": message}

    response = client.get("/")
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == expected


@pytest.mark.parametrize("greeting", greetings)
def test_greeting(greeting: str) -> None:
    message = f"{greeting} World!"
    expected = {"message": message}

    params = {"greeting": greeting}
    response = client.get("/", params=params)
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == expected


@pytest.mark.parametrize("name", names)
def test_name(name: str) -> None:
    message = f"Hello {name}!"
    expected = {"message": message}

    params = {"name": name}
    response = client.get("/", params=params)
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == expected


@pytest.mark.parametrize(("greeting", "name"), product(greetings, names))
def test_greeting_name(greeting: str, name: str) -> None:
    message = f"{greeting} {name}!"
    expected = {"message": message}

    params = {"greeting": greeting, "name": name}
    response = client.get("/", params=params)
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == expected
