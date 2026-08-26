"""Tests for HTTP request parsing (`server.http.request.HttpRequest`).

Run the whole file:  just test tests/server/test_parser.mojo
Run a single test:   just test tests/server/test_parser.mojo --only test_parse_splits_query_string_from_path
"""

from std.testing import TestSuite, assert_equal, assert_true
from server.http.request import HttpRequest


def test_parse_request_line_sets_method_and_path() raises:
    var request = HttpRequest(String('GET /hello HTTP/1.1\r\n\r\n'))
    assert_equal(request.method, 'GET')
    assert_equal(request.path, '/hello')


def test_parse_splits_query_string_from_path() raises:
    var request = HttpRequest(
        String('GET /search?q=mojo&page=2 HTTP/1.1\r\n\r\n')
    )
    assert_equal(request.path, '/search')
    assert_equal(request.get_query('q'), 'mojo')
    assert_equal(request.get_query('page'), '2')


def test_parse_query_parameter_without_equals_is_empty() raises:
    var request = HttpRequest(String('GET /items?populated HTTP/1.1\r\n\r\n'))
    assert_equal(request.path, '/items')
    assert_equal(request.get_query('populated'), '')


def test_parse_reads_headers() raises:
    var request = HttpRequest(
        String(
            'POST / HTTP/1.1\r\n'
            + 'Content-Type: text/plain\r\n'
            + 'Host: localhost\r\n'
            + '\r\n'
        )
    )
    assert_equal(request.header.keys_values['Content-Type'], 'text/plain')
    assert_equal(request.header.keys_values['Host'], 'localhost')


def test_parse_separates_body_after_blank_line() raises:
    var request = HttpRequest(
        String('POST /cmd HTTP/1.1\r\nContent-Length: 11\r\n\r\nstore k v')
    )
    assert_equal(request.path, '/cmd')
    assert_equal(request.body.data, 'store k v')


def test_parse_without_blank_line_leaves_body_empty() raises:
    var request = HttpRequest(String('GET / HTTP/1.1'))
    assert_equal(request.body.data, '')


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
