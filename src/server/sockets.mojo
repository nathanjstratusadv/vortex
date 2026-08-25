"""Low-level POSIX socket bindings.

These are thin wrappers around the C library socket calls, necessary because
Mojo's standard library does not pre-wrap BSD sockets.  We call libc directly
through `std.ffi.external_call` and pass raw byte buffers via the `Pointer`
returned by `alloc`.

All functions return the libc result code (negative on error, errno set).
"""

from std.memory import alloc, Layout
from std.ffi import external_call
from std.sys._libc_errno import get_errno

comptime AF_INET: Int32 = 2
comptime SOCK_STREAM: Int32 = 1

@always_inline
def htons(value: UInt16) -> UInt16:
    """Convert a 16-bit value from host to network byte order."""
    return external_call['htons', UInt16](value)


@always_inline
def socket() -> Int32:
    """Create an IPv4 TCP socket.  Returns a file descriptor or -1."""
    return external_call['socket', Int32](AF_INET, SOCK_STREAM, 0)


@always_inline
def bind(
    file_descriptor: Int32,
    socket_address: Pointer[UInt8, MutUntrackedOrigin],
    socket_address_length: Int,
) -> Int32:
    """Bind a socket to an address.  `socket_address` points to a `sockaddr_in`."""
    return external_call['bind', Int32](
        file_descriptor, socket_address, socket_address_length
    )


@always_inline
def listen(file_descriptor: Int32, backlog: Int32) -> Int32:
    """Mark a socket as listening for incoming connections."""
    return external_call['listen', Int32](file_descriptor, backlog)


@always_inline
def accept(file_descriptor: Int32) -> Int32:
    """Accept an incoming connection.  Returns the client file descriptor or -1."""
    return external_call['accept', Int32](file_descriptor, None, None)


@always_inline
def recv(
    file_descriptor: Int32,
    buffer: Pointer[UInt8, MutUntrackedOrigin],
    byte_count: Int,
) -> Int32:
    """Receive up to `byte_count` bytes from a connected socket."""
    return external_call['recv', Int32](file_descriptor, buffer, byte_count, 0)


@always_inline
def send(
    file_descriptor: Int32,
    buffer: Pointer[UInt8, MutUntrackedOrigin],
    byte_count: Int,
) -> Int32:
    """Send up to `byte_count` bytes on a connected socket."""
    return external_call['send', Int32](file_descriptor, buffer, byte_count, 0)


@always_inline
def close(file_descriptor: Int32) -> Int32:
    """Close a file descriptor."""
    return external_call['close', Int32](file_descriptor)


def fill_sockaddr_in(port: Int) -> Pointer[UInt8, MutUntrackedOrigin]:
    """Build a 16-byte `sockaddr_in` for 0.0.0.0:`port`.

    Layout: [0]=AF_INET, [1]=0, [2..3]=port (network byte order), rest = 0.
    The caller must `free()` the returned buffer.
    """
    var socket_address_layout = Layout[UInt8](count=16)
    var socket_address_allocation = alloc(socket_address_layout)
    var socket_address_buffer = socket_address_allocation.unsafe_ptr()
    socket_address_buffer.unsafe_store(0, UInt8(2))
    socket_address_buffer.unsafe_store(1, UInt8(0))
    var network_byte_order_port = htons(UInt16(port))
    socket_address_buffer.unsafe_store(
        2, UInt8(network_byte_order_port & 0xFF)
    )
    socket_address_buffer.unsafe_store(
        3, UInt8((network_byte_order_port >> 8) & 0xFF)
    )
    return socket_address_allocation^.unsafe_leak()
