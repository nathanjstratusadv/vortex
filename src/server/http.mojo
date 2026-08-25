"""HTTP request/response value types.

These are the plain data carriers of the framework.  `Request` is produced by
the server from the raw bytes on the wire; `Response` is produced by a
controller and serialized back onto the wire by the server.
"""

comptime STATUS_OK = 200
comptime STATUS_BAD_REQUEST = 400
comptime STATUS_NOT_FOUND = 404
comptime STATUS_METHOD_NOT_ALLOWED = 405
comptime STATUS_INTERNAL_ERROR = 500


def _reason(status: Int) -> String:
    """Map an HTTP status code to its reason phrase."""
    if status == 200:
        return String('OK')
    elif status == 400:
        return String('Bad Request')
    elif status == 404:
        return String('Not Found')
    elif status == 405:
        return String('Method Not Allowed')
    elif status == 500:
        return String('Internal Server Error')
    else:
        return String('Unknown')


struct Request:
    """A parsed incoming HTTP request."""

    var method: String
    var path: String
    var query: Dict[String, String]
    var headers: Dict[String, String]
    var body: String

    def __init__(out self):
        self.method = String()
        self.path = String()
        self.query = Dict[String, String]()
        self.headers = Dict[String, String]()
        self.body = String()

    def __init__(out self, method: String, path: String):
        self.method = method
        self.path = path
        self.query = Dict[String, String]()
        self.headers = Dict[String, String]()
        self.body = String()

    def get_query(self, key: String) raises -> String:
        """Return a query parameter value or an empty string."""
        if key in self.query:
            return String(self.query[key])
        return String()


struct Response:
    """An outgoing HTTP response."""

    var status: Int
    var headers: Dict[String, String]
    var body: String

    def __init__(out self, status: Int = STATUS_OK):
        self.status = status
        self.headers = Dict[String, String]()
        self.body = String()

    def set_header(mut self, name: String, value: String) raises:
        self.headers[name] = value

    def serialize(self) raises -> String:
        """Build the full HTTP/1.1 wire representation of this response."""
        var wire_representation = (
            String('HTTP/1.1 ')
            + String(self.status)
            + ' '
            + _reason(self.status)
            + '\r\n'
        )
        wire_representation += 'Content-Length: ' + String(
            self.body.byte_length()
        ) + '\r\n'
        for header_name in self.headers.keys():
            wire_representation += (
                header_name + ': ' + String(self.headers[header_name]) + '\r\n'
            )
        wire_representation += '\r\n'
        wire_representation += self.body
        return wire_representation
