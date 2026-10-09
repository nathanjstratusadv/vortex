struct Database:
    var data: Dict[String, String]

    def __init__(out self):
        self.data = Dict[String, String]()

    def store(mut self, key: String, value: String) raises:
        self.data[key] = value

    def contains(self, key: String) -> Bool:
        return key in self.data

    def fetch(self, key: String) raises -> String:
        if key in self.data:
            return String(self.data[key])
        return String()

    def delete(mut self, key: String) raises -> Bool:
        if key not in self.data:
            return False
        var remaining_entries = Dict[String, String]()
        for stored_key in self.data.keys():
            if stored_key != key:
                remaining_entries[stored_key] = self.data[stored_key]
        self.data = remaining_entries^
        return True

    def all_keys(self) raises -> String:
        var result = String()
        var first = True
        for key in self.data.keys():
            if not first:
                result += String('\n')
            result += key
            first = False
        return result
