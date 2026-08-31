from std import os

from config.consts import __BASE_DIR__, __DB_DIR__

struct FileHandler:
    var is_initialized: Bool

    def __init__(out self):
        self.is_initialized = False

        self._setup_base_dir()
        self._setup_db_dir()

        self.is_initialized = True

    def _setup_base_dir(self):
        try:
            os.mkdir(__BASE_DIR__)
        except e:
            print(t'Failed to create base directory "{__BASE_DIR__}"')

    def _setup_db_dir(self):
        var db_dir = os.path.join(__BASE_DIR__, __DB_DIR__)
        try:
            os.mkdir(db_dir)
        except e:
            print(t'Failed to create base directory "{db_dir}"')
