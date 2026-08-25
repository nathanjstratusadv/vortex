"""In-memory string database (the Model).

A key -> value map of strings.  State lives in a `VortexDb` struct instance
owned by the `HttpServer`.  Mojo 1.0 has no module-level globals, `static`
locals, or capturing closures, so a long-lived server-owned object is the only
place persistent request-to-request state can live; handlers reach it through
the server that owns it.

Command grammar (freeform; one command per request body):

    store KEY VALUE...   save VALUE (may contain spaces) under KEY
    fetch KEY            retrieve the value saved under KEY
    delete KEY           remove KEY
    keys                 list all keys, one per line
"""


struct VortexDb:
    """An in-memory key -> value map of strings."""

    var data: Dict[String, String]

    def __init__(out self):
        self.data = Dict[String, String]()

    def store(mut self, key: String, value: String) raises:
        """Save `value` under `key`, overwriting any existing value."""
        self.data[key] = value

    def contains(self, key: String) -> Bool:
        """Return `True` if `key` is present."""
        return key in self.data

    def fetch(self, key: String) raises -> String:
        """Return the value stored under `key`, or an empty string if absent."""
        if key in self.data:
            return String(self.data[key])
        return String()

    def delete(mut self, key: String) raises -> Bool:
        """Remove `key`; return `True` if it was present."""
        if key not in self.data:
            return False
        var remaining_entries = Dict[String, String]()
        for stored_key in self.data.keys():
            if stored_key != key:
                remaining_entries[stored_key] = self.data[stored_key]
        self.data = remaining_entries^
        return True

    def all_keys(self) raises -> String:
        """Return all keys joined by newlines (empty string if none)."""
        var result = String()
        var first = True
        for key in self.data.keys():
            if not first:
                result += String('\n')
            result += key
            first = False
        return result
