struct HttpBody:
    var data: String

    def __init__(out self, raw_http_request: String):
        var separator_position = raw_http_request.find('\r\n\r\n')

        if separator_position > 0:
            self.data = String(
                raw_http_request[byte=(separator_position + 4):]
            )
        else:
            self.data = String()