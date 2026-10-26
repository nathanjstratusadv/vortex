from std.testing import TestSuite, assert_true
from vortex.server.server import _request_is_complete


def test_request_without_body_is_complete() raises:
    var raw_request_text = String('GET /hello HTTP/1.1\r\n\r\n')
    assert_true(_request_is_complete(raw_request_text))


def test_partial_headers_are_incomplete() raises:
    var raw_request_text = String('GET /hello HTTP/1.1\r\nHost: ')
    assert_true(not _request_is_complete(raw_request_text))


def test_missing_declared_body_is_incomplete() raises:
    var raw_request_text = String(
        'POST / HTTP/1.1\r\nContent-Length: 5\r\n\r\n'
    )
    assert_true(not _request_is_complete(raw_request_text))


def test_arrived_declared_body_is_complete() raises:
    var raw_request_text = String(
        'POST / HTTP/1.1\r\nContent-Length: 5\r\n\r\nhello'
    )
    assert_true(_request_is_complete(raw_request_text))


def test_content_length_header_is_case_insensitive() raises:
    var raw_request_text = String(
        'POST / HTTP/1.1\r\nCONTENT-LENGTH: 5\r\n\r\nhello'
    )
    assert_true(_request_is_complete(raw_request_text))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
