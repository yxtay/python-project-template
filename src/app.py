import uvicorn
from fastapi import FastAPI
from pydantic.main import BaseModel

app = FastAPI()


class HelloResponse(BaseModel):
    message: str


@app.get("/", response_model=HelloResponse, summary="Greetings")
async def root(greeting: str = "Hello", name: str = "World"):
    """
    Returns greeting message.
    """
    message = f"{greeting} {name}!"
    response = {"message": message}
    return response


if __name__ == "__main__":
    uvicorn.run("src.app:app", reload=True)
