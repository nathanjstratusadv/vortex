struct Database:
    var data: Dict[String, String]

    def __init__(out self):
        self.data = Dict[String, String]()

    def process(mut self, input: String) raises -> String:
        var input_parts = input.split(None, maxsplit=2)
        var command = String()

        if len(input_parts) > 0:
            command = String(input_parts[0])

        if command == String('store'):
            if len(input_parts) >= 3:
                var key = String(input_parts[1])
                self.data[key] = String(input_parts[2])
                return String('stored ') + key
            return String('usage: store KEY VALUE...')

        elif command == String('fetch'):
            if len(input_parts) >= 2:
                var key = String(input_parts[1])

                if key in self.data:
                    return String(self.data[key])
                return String('not found: ') + key
            return String('usage: fetch KEY')

        elif command == String('delete'):
            if len(input_parts) >= 2:
                var key = String(input_parts[1])

                if key in self.data:
                    var remaining_entries = Dict[String, String]()
                    for stored_key in self.data.keys():
                        if stored_key != key:
                            remaining_entries[stored_key] = self.data[stored_key]
                    self.data = remaining_entries^
                    return String('deleted ') + key
                return String('not found: ') + key
            return String('usage: delete KEY')

        elif command == String('keys'):
            var result = String()
            var first = True
            for key in self.data.keys():
                if not first:
                    result += String('\n')
                result += key
                first = False
            return result

        elif command == String(''):
            return String('empty command. usage: store/fetch/delete/keys')

        else:
            return String('unknown command: ') + command
