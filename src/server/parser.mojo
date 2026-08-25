"""HTTP request parser.

Turns the raw request bytes (read off the socket) into a structured `Request`.
Only the pieces we need for routing and simple controllers are parsed: the
request line (method + path + query), the headers, and the body.
"""

from .http import Request


struct RequestParser:
    """Parses raw HTTP text into a `Request`."""

    @staticmethod
    def parse(raw_request_text: String) raises -> Request:
        """Parse `raw_request_text` (a full HTTP request head + body)."""
        var request = Request()

        # Split headers from body at the blank line.
        var header_body_separator = String('\r\n\r\n')
        var separator_position = raw_request_text.find(header_body_separator)
        var request_head: String
        var body = String()
        if separator_position < 0:
            request_head = raw_request_text
        else:
            request_head = String(raw_request_text[byte=0:separator_position])
            body = String(
                raw_request_text[byte=(separator_position + 4):]
            )
        request.body = body

        var lines = request_head.split(String('\r\n'))
        if len(lines) == 0:
            return request^

        # Request line: METHOD SP TARGET SP VERSION
        var request_line_parts = lines[0].split(String(' '))
        if len(request_line_parts) >= 1:
            request.method = String(request_line_parts[0])
        if len(request_line_parts) >= 2:
            var target = String(request_line_parts[1])
            var query_delimiter_position = target.find(String('?'))
            if query_delimiter_position < 0:
                request.path = target
            else:
                request.path = String(
                    target[byte=0:query_delimiter_position]
                )
                var query = String(
                    target[byte=(query_delimiter_position + 1):]
                )
                var query_parameter_pairs = query.split(String('&'))
                for key_value_pair in query_parameter_pairs:
                    var equals_position = key_value_pair.find(String('='))
                    if equals_position < 0:
                        request.query[String(key_value_pair)] = String()
                    else:
                        request.query[String(
                            key_value_pair[byte=0:equals_position]
                        )] = String(key_value_pair[byte=(equals_position + 1):])

        # Headers.
        for index in range(1, len(lines)):
            var header_line = lines[index]
            var colon_position = header_line.find(String(':'))
            if colon_position < 0:
                continue
            var header_name = String(header_line[byte=0:colon_position])
            var header_value = String(header_line[byte=(colon_position + 2):])
            request.headers[header_name] = header_value

        return request^
