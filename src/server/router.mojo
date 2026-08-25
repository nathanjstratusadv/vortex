"""MVC Router.

Maps an HTTP request (method + path) to the controller `def` that handles it.
Routes are stored in a dictionary keyed by `"METHOD /path"` so dispatch is a
single lookup.  A handler is a thin function pointer that mutates a caller
provided `Request` and `Response` in place.

This is the Controller-dispatch half of MVC: the router decides which handler
owns a request, and the handler itself is the Controller that coordinates the
Model and the View.
"""

from .http import Request, Response

comptime Handler = def(
    mut request: Request,
    mut response: Response,
) raises thin -> None


struct Router:
    """A table of `METHOD path -> handler` routes."""

    var table: Dict[String, Handler]

    def __init__(out self):
        self.table = Dict[String, Handler]()

    def add(mut self, method: String, path: String, handler: Handler):
        """Register `handler` to serve `method` requests at `path`."""
        var key = method + ' ' + path
        self.table[key] = handler

    def dispatch(
        mut self,
        mut request: Request,
        mut response: Response,
    ) raises -> Bool:
        """Route a request to its handler.

        Mutates `response` if a route matched and returns `True`; otherwise
        leaves the response untouched and returns `False`.
        """
        var key = request.method + ' ' + request.path
        if key in self.table:
            var handler: Handler = self.table[key]
            handler(request, response)
            return True
        return False
