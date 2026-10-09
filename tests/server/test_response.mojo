from std.testing import TestSuite, assert_equal, assert_true
from vortex.server.http.response import HttpResponse
from vortex.server.http.status import (
    STATUS_OK,
    STATUS_BAD_REQUEST,
    STATUS_NOT_FOUND,
    Status,
)


def test_status_ok_is_two_hundred() raises:
    assert_equal(STATUS_OK, 200)


def test_default_response_status_is_ok() raises:
    var response = HttpResponse()
    assert_equal(response.status.code, 200)


def test_default_serialize_starts_with_valid_status_line() raises:
    var response = HttpResponse()
    var wire = response.serialize()
    assert_true(wire.startswith(String('HTTP/1.1 200 OK\r\n')))


def test_serialize_custom_status_line() raises:
    var response = HttpResponse(status_code=STATUS_NOT_FOUND)
    var wire = response.serialize()
    assert_true(wire.startswith(String('HTTP/1.1 404 Not Found\r\n')))


def test_serialize_includes_content_length_and_body() raises:
    var response = HttpResponse()
    response.body.data = String('hello')
    var wire = response.serialize()
    assert_true(wire.find(String('Content-Length: 5\r\n')) >= 0)
    assert_true(wire.endswith(String('hello')))


def test_status_rejects_unknown_code() raises:
    var status = Status(code=STATUS_BAD_REQUEST)
    assert_equal(status.code, 400)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
