from server.server import HttpServer
from server.router import Router
from server.http.request import HttpRequest
from server.http.response import HttpResponse
from database.database import Database


def welcome_controller(
    mut http_request: HttpRequest,
    mut http_response: HttpResponse,
) raises -> None:
    http_response.body.data = (
        String("vortex: a string-in / string-out database over HTTP.\n")
        + String("POST a command in the body:\n")
        + String("  store KEY VALUE...   save VALUE under KEY\n")
        + String("  fetch KEY            retrieve VALUE for KEY\n")
        + String("  delete KEY           remove KEY\n")
        + String("  keys                 list all keys (one per line)\n")
    )

    http_response.set_header(String("Content-Type"), String("text/plain"))


def main() raises:
    var router = Router()

    router.add("GET", "/", welcome_controller)

    var database = Database()

    var server = HttpServer(port=8000, router=router^, database=database^)

    server.serve()
