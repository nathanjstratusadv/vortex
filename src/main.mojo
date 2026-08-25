"""A string-in / string-out database over HTTP (the vortex server).

POST a freeform command in the request body (see the command grammar in
`server.db`); the server replies with a plain-text string.  `GET /` and
`GET /hello` print usage.  The data is an in-memory key/value map owned by the
server; it resets when the process restarts.
"""

from server.server import HttpServer
from server.router import Router
from server.http import Request, Response
from server.db import VortexDb


def welcome_controller(
    mut request: Request,
    mut response: Response,
) raises -> None:
    """GET / and GET /hello: print usage."""
    response.body = (
        String('vortex: a string-in / string-out database over HTTP.\n')
        + String('POST a command in the body:\n')
        + String('  store KEY VALUE...   save VALUE under KEY\n')
        + String('  fetch KEY            retrieve VALUE for KEY\n')
        + String('  delete KEY           remove KEY\n')
        + String('  keys                 list all keys (one per line)\n')
    )
    response.set_header(String('Content-Type'), String('text/plain'))


def main() raises:
    var router = Router()
    router.add('GET', '/', welcome_controller)

    var database = VortexDb()
    var server = HttpServer(port=8000, router=router^, database=database^)
    server.serve()
