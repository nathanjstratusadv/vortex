"""Blocking HTTP server.

Accepts connections, reads the request head into a byte list, converts it to a
text `String`, parses it into a `Request`, dispatches it through the `Router`,
and writes the serialized `Response` back to the socket.  One request per
connection for now (`Connection: close`).
"""

from std.memory import alloc, Layout
from server.http import (
    Request,
    Response,
    STATUS_BAD_REQUEST,
    STATUS_NOT_FOUND,
)
from consts import __VERSION__
from server import parser
from server.db import VortexDb
from server.router import Router
from server.sockets import (
    socket,
    bind,
    listen,
    accept,
    recv,
    send,
    close,
    fill_sockaddr_in,
    get_errno,
)


def _read_request(
    file_descriptor: Int32, buffer_size: Int = 8192
) raises -> String:
    """Read as many request bytes as arrive, returned as a `String`."""
    var read_buffer_layout = Layout[UInt8](count=buffer_size)
    var read_buffer_allocation = alloc(read_buffer_layout)
    var read_buffer = read_buffer_allocation^.unsafe_leak()
    var received_bytes = List[UInt8]()
    try:
        var bytes_received = recv(file_descriptor, read_buffer, buffer_size)
        if bytes_received > 0:
            for index in range(bytes_received):
                received_bytes.append(read_buffer.unsafe_load(index))
    finally:
        read_buffer.unsafe_free()
    return String(from_utf8=received_bytes)


struct HttpServer:
    """Listens on a port and serves HTTP through a `Router`."""

    var port: Int
    var router: Router
    var database: VortexDb
    var backlog: Int32

    def __init__(
        out self,
        var router: Router,
        var database: VortexDb,
        port: Int = 8000,
        backlog: Int32 = 128,
    ):
        self.port = port
        self.router = router^
        self.database = database^
        self.backlog = backlog

    def serve(mut self) raises:
        """Bind, listen, then accept and dispatch requests forever."""
        var server_file_descriptor = socket()
        if server_file_descriptor < 0:
            raise Error(
                'socket() failed: errno=', String(get_errno())
            )

        var socket_address = fill_sockaddr_in(self.port)
        var return_code = bind(server_file_descriptor, socket_address, 16)
        socket_address.unsafe_free()
        if return_code < 0:
            _ = close(server_file_descriptor)
            raise Error('bind() failed: errno=', String(get_errno()))

        return_code = listen(server_file_descriptor, self.backlog)
        if return_code < 0:
            _ = close(server_file_descriptor)
            raise Error('listen() failed: errno=', String(get_errno()))

        print(t'Vortex {__VERSION__}')
        print('listening on http://127.0.0.1:', self.port)

        while True:
            var client_file_descriptor = accept(server_file_descriptor)
            if client_file_descriptor < 0:
                continue

            self._handle(client_file_descriptor)
            _ = close(client_file_descriptor)

    def _handle(mut self, client_file_descriptor: Int32) raises:
        """Serve a single client connection."""
        var raw_request_text = _read_request(client_file_descriptor)
        var request = parser.RequestParser.parse(raw_request_text)
        var response = Response()

        # Let the router (and its handler) fill in the response.
        var route_matched = self.router.dispatch(request, response)
        if not route_matched and request.method == String('POST'):
            # The command endpoint isn't in the (stateless) router; the
            # database is server-owned, so dispatch it here as a method.
            self._dispatch_command(request, response)
        elif not route_matched:
            response.status = STATUS_NOT_FOUND
            response.body = (
                String('<h1>404 Not Found</h1><p>No route for <code>')
                + request.path
                + String('</code>.</p>')
            )

        var serialized_response = response.serialize()
        var serialized_response_byte_count = serialized_response.byte_length()
        var output_buffer_layout = Layout[UInt8](
            count=serialized_response_byte_count
        )
        var output_buffer_allocation = alloc(output_buffer_layout)
        var output_buffer = output_buffer_allocation^.unsafe_leak()
        var serialized_response_bytes = serialized_response.as_bytes()
        for index in range(serialized_response_byte_count):
            output_buffer.unsafe_store(
                index, serialized_response_bytes[index]
            )

        var bytes_sent = send(
            client_file_descriptor,
            output_buffer,
            serialized_response_byte_count,
        )
        _ = bytes_sent

        output_buffer.unsafe_free()

    def _dispatch_command(
        mut self,
        mut request: Request,
        mut response: Response,
    ) raises:
        """The Controller for the freeform command endpoint (POST / or /cmd).

        Parses a single command out of the request body and coordinates the
        `VortexDb` (Model) to build a plain-text response (View).
        """
        if (
            request.path != String('/')
            and request.path != String('/cmd')
        ):
            response.status = STATUS_NOT_FOUND
            response.body = (
                String('<h1>404 Not Found</h1><p>No command route at <code>')
                + request.path
                + String('</code>.</p>')
            )
            return

        var command_parts = request.body.split(None, maxsplit=2)
        var command = String()
        if len(command_parts) > 0:
            command = String(command_parts[0])

        if command == String('store'):
            if len(command_parts) >= 3:
                var key = String(command_parts[1])
                self.database.store(key, String(command_parts[2]))
                response.body = String('stored ') + key
            else:
                response.status = STATUS_BAD_REQUEST
                response.body = String('usage: store KEY VALUE...')
        elif command == String('fetch'):
            if len(command_parts) >= 2:
                var key = String(command_parts[1])
                if self.database.contains(key):
                    response.body = self.database.fetch(key)
                else:
                    response.status = STATUS_NOT_FOUND
                    response.body = String('not found: ') + key
            else:
                response.status = STATUS_BAD_REQUEST
                response.body = String('usage: fetch KEY')
        elif command == String('delete'):
            if len(command_parts) >= 2:
                var key = String(command_parts[1])
                if self.database.delete(key):
                    response.body = String('deleted ') + key
                else:
                    response.status = STATUS_NOT_FOUND
                    response.body = String('not found: ') + key
            else:
                response.status = STATUS_BAD_REQUEST
                response.body = String('usage: delete KEY')
        elif command == String('keys'):
            response.body = self.database.all_keys()
        elif command == String(''):
            response.status = STATUS_BAD_REQUEST
            response.body = (
                String('empty command. usage: store/fetch/delete/keys')
            )
        else:
            response.status = STATUS_BAD_REQUEST
            response.body = String('unknown command: ') + command

        response.set_header(String('Content-Type'), String('text/plain'))
