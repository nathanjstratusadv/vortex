struct HttpHeader:
    var keys_values: Dict[String, String]
    var raw: String

    def __init__(out self, raw_http_request: String):
        self.keys_values = Dict[String, String]()

        var separator_position = raw_http_request.find('\r\n\r\n')
        var request_head: String

        if separator_position < 0:
            request_head = raw_http_request
        else:
            request_head = String(raw_http_request[byte=0:separator_position])

        self.raw = request_head

        var lines = request_head.split('\r\n')

        for index in range(1, len(lines)):
            var header_line = lines[index]
            var colon_position = header_line.find(String(':'))
            if colon_position < 0:
                continue
            var header_name = String(header_line[byte=0:colon_position])
            var header_value = String(header_line[byte=(colon_position + 2):])

            self.keys_values[header_name] = header_value
