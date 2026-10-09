from vortex.file.handler import FileHandler
from vortex.server.server import HttpServer
from vortex.server.router import Router
from vortex.server.http.request import HttpRequest
from vortex.server.http.response import HttpResponse
from vortex.database.database import Database


def welcome_controller(
    mut http_request: HttpRequest,
    mut http_response: HttpResponse,
) raises -> None:
    http_response.body.data = (
        String('vortex: a string-in / string-out database over HTTP.\n')
        + String('POST a command in the body:\n')
        + String('  store KEY VALUE...   save VALUE under KEY\n')
        + String('  fetch KEY            retrieve VALUE for KEY\n')
        + String('  delete KEY           remove KEY\n')
        + String('  keys                 list all keys (one per line)\n')
    )

    http_response.set_header('Content-Type', 'text/plain')


def main() raises:
    var _ = FileHandler()

    var router = Router()

    router.add('GET', '/', welcome_controller)

    var database = Database()

    var server = HttpServer(router=router^, database=database^)

    server.serve()
