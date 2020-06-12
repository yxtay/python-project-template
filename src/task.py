import typer

app = typer.Typer()


@app.command()
def main(name: str = typer.Argument("World")) -> None:
    """
    Print hello message

    name - name to be greeted; default: "World"
    """
    message = f"Hello {name}!"
    typer.echo(message)


if __name__ == "__main__":
    app()
