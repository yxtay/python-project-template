from typing import Dict

from fastapi import FastAPI
from pydantic.main import BaseModel

from src.config import logger

app = FastAPI()


class HelloResponse(BaseModel):
    message: str


@app.get("/", response_model=HelloResponse, summary="Greetings")
async def hello(greeting: str = "Hello", name: str = "World") -> Dict[str, str]:
    """
    Returns greeting message.
    """
    message = f"{greeting} {name}!"
    response = {"message": message}
    logger.info("hello response", extra={"response": response})
    return response
