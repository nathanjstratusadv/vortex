from server.http.response import HttpResponse
from server.http.request import HttpRequest

comptime Handler = def(
    mut request: HttpRequest,
    mut response: HttpResponse,
) raises thin -> None


struct Router:
    var table: Dict[String, Handler]

    def __init__(out self):
        self.table = Dict[String, Handler]()

    def add(mut self, method: String, path: String, handler: Handler):
        var key = method + ' ' + path
        self.table[key] = handler

    def dispatch(
        mut self,
        mut request: HttpRequest,
        mut response: HttpResponse,
    ) raises -> Bool:
        var key = request.method + ' ' + request.path
        if key in self.table:
            var handler: Handler = self.table[key]
            handler(request, response)
            return True
        return False
