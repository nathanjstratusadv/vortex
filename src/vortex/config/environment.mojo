from std.os.env import getenv

comptime _DEFAULT_PORT = 8700

def get_port() -> Int:
    var port: Int = _DEFAULT_PORT

    try:
        port = Int(getenv('VORTEX_DB_PORT', String(_DEFAULT_PORT)))
    except e:
        print(t'Failed to set port with the following error: {e}')

    return port


def get_host() -> String:
    return getenv('VORTEX_DB_HOST', '127.0.0.1')
