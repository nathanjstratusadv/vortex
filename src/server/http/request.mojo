from server.http.header import HttpHeader
from server.http.body import HttpBody


struct HttpRequest:
    var method: String
    var path: String
    var query: Dict[String, String]
    var header: HttpHeader
    var body: HttpBody
    var _raw: String

    def __init__(out self, raw_http_request: String):
        self.method = String()
        self.path = String()
        self.query = Dict[String, String]()
        self.header = HttpHeader(raw_http_request)
        self.body = HttpBody(raw_http_request)
        self._raw = raw_http_request

        var lines = self.header.raw.split(String("\r\n"))

        if len(lines) > 0:
            var request_line_parts = lines[0].split(String(" "))

            if len(request_line_parts) >= 1:
                self.method = String(request_line_parts[0])

            if len(request_line_parts) >= 2:
                var target = String(request_line_parts[1])
                var query_delimiter_position = target.find(String("?"))

                if query_delimiter_position < 0:
                    self.path = target
                else:
                    self.path = String(target[byte=0:query_delimiter_position])

                    var query = String(
                        target[byte = (query_delimiter_position + 1) :]
                    )

                    var query_parameter_pairs = query.split(String("&"))

                    for key_value_pair in query_parameter_pairs:
                        var equals_position = key_value_pair.find(String("="))

                        if equals_position < 0:
                            self.query[String(key_value_pair)] = String()
                        else:
                            self.query[
                                String(key_value_pair[byte=0:equals_position])
                            ] = String(
                                key_value_pair[byte = (equals_position + 1) :]
                            )

    def get_query(self, key: String) raises -> String:
        if key in self.query:
            return String(self.query[key])
        return String()
