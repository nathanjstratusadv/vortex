comptime _VALID_STATUS_CODES: List[Int] = [200, 400, 403, 404, 405, 500]

comptime STATUS_OK: Int = 200
comptime STATUS_BAD_REQUEST: Int = 400
comptime STATUS_PERMISSION_DENIED: Int = 403
comptime STATUS_NOT_FOUND: Int = 404
comptime STATUS_METHOD_NOT_ALLOWED: Int = 405
comptime STATUS_INTERNAL_ERROR: Int = 500


struct Status:
    var code: Int

    def __init__(out self, code: Int):
        if code in materialize[_VALID_STATUS_CODES]():
            self.code = code
        else:
            self.code = 400

    def verbose(self) -> String:
        if self.code == 200:
            return String('OK')
        elif self.code == 400:
            return String('Bad Request')
        elif self.code == 403:
            return String('Permission Denied')
        elif self.code == 404:
            return String('Not Found')
        elif self.code == 405:
            return String('Method Not Allowed')
        elif self.code == 500:
            return String('Internal Server Error')
        else:
            return String('Unknown')
