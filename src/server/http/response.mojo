from server.http.status import Status
from server.http.body import HttpBody
from server.http.header import HttpHeader

struct HttpResponse:
    var status: Status
    var header: HttpHeader
    var body: HttpBody

    def __init__(out self, status_code: Int = 200):
        self.status = Status(code=status_code)
        self.header = HttpHeader(String())
        self.body = HttpBody(String())

    def set_header(mut self, name: String, value: String) raises:
        self.header.keys_values[name] = value

    def serialize(self) raises -> String:
        var wire_representation = (
            String('HTTP/1.1 ')
            + String(self.status.code)
            + ' '
            + String(self.status.verbose())
            + '\r\n'
        )
        wire_representation += 'Content-Length: ' + String(
            self.body.data.byte_length()
        ) + '\r\n'
        for header_name in self.header.keys_values.keys():
            wire_representation += (
                header_name + ': ' + String(self.header.keys_values[header_name]) + '\r\n'
            )
        wire_representation += '\r\n'
        wire_representation += self.body.data
        return wire_representation
