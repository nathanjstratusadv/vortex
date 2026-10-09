from std.memory import alloc, Layout
from std.ffi import external_call
from std.sys._libc_errno import get_errno

comptime AF_INET: Int32 = 2
comptime SOCK_STREAM: Int32 = 1


@always_inline
def htons(value: UInt16) -> UInt16:
    return external_call['htons', UInt16](value)


@always_inline
def socket() -> Int32:
    return external_call['socket', Int32](AF_INET, SOCK_STREAM, 0)


@always_inline
def inet_addr(address: Pointer[UInt8, MutUntrackedOrigin]) -> UInt32:
    return external_call['inet_addr', UInt32](address)


@always_inline
def bind(
    file_descriptor: Int32,
    socket_address: Pointer[UInt8, MutUntrackedOrigin],
    socket_address_length: Int,
) -> Int32:
    return external_call['bind', Int32](
        file_descriptor, socket_address, socket_address_length
    )


@always_inline
def listen(file_descriptor: Int32, backlog: Int32) -> Int32:
    return external_call['listen', Int32](file_descriptor, backlog)


@always_inline
def accept(file_descriptor: Int32) -> Int32:
    return external_call['accept', Int32](file_descriptor, None, None)


@always_inline
def recv(
    file_descriptor: Int32,
    buffer: Pointer[UInt8, MutUntrackedOrigin],
    byte_count: Int,
) -> Int32:
    return external_call['recv', Int32](file_descriptor, buffer, byte_count, 0)


@always_inline
def send(
    file_descriptor: Int32,
    buffer: Pointer[UInt8, MutUntrackedOrigin],
    byte_count: Int,
) -> Int32:
    return external_call['send', Int32](file_descriptor, buffer, byte_count, 0)


@always_inline
def close(file_descriptor: Int32) -> Int32:
    return external_call['close', Int32](file_descriptor)


def fill_sockaddr_in(
    port: Int, host: String
) -> Pointer[UInt8, MutUntrackedOrigin]:
    var socket_address_layout = Layout[UInt8](count=16)
    var socket_address_allocation = alloc(socket_address_layout)
    var socket_address_buffer = socket_address_allocation.unsafe_ptr()
    socket_address_buffer.unsafe_store(0, UInt8(2))
    socket_address_buffer.unsafe_store(1, UInt8(0))
    var network_byte_order_port = htons(UInt16(port))
    socket_address_buffer.unsafe_store(2, UInt8(network_byte_order_port & 0xFF))
    socket_address_buffer.unsafe_store(
        3, UInt8((network_byte_order_port >> 8) & 0xFF)
    )

    var host_byte_count = host.byte_length()
    var host_buffer_layout = Layout[UInt8](count=host_byte_count + 1)
    var host_buffer_allocation = alloc(host_buffer_layout)
    var host_buffer = host_buffer_allocation^.unsafe_leak()
    var host_bytes = host.as_bytes()
    for index in range(host_byte_count):
        host_buffer.unsafe_store(index, host_bytes[index])
    host_buffer.unsafe_store(host_byte_count, UInt8(0))

    var network_byte_order_address = inet_addr(host_buffer)
    socket_address_buffer.unsafe_store(
        4, UInt8(network_byte_order_address & 0xFF)
    )
    socket_address_buffer.unsafe_store(
        5, UInt8((network_byte_order_address >> 8) & 0xFF)
    )
    socket_address_buffer.unsafe_store(
        6, UInt8((network_byte_order_address >> 16) & 0xFF)
    )
    socket_address_buffer.unsafe_store(
        7, UInt8((network_byte_order_address >> 24) & 0xFF)
    )
    host_buffer.unsafe_free()

    return socket_address_allocation^.unsafe_leak()
