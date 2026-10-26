from std.testing import TestSuite, assert_equal, assert_true
from vortex.database.database import Database


def test_store_then_fetch_returns_stored_value() raises:
    var database = Database()
    assert_equal(database.process('store greeting hello world'), 'stored greeting')
    assert_equal(database.process('fetch greeting'), 'hello world')


def test_store_value_may_contain_spaces() raises:
    var database = Database()
    _ = database.process('store note first line is here')
    assert_equal(database.process('fetch note'), 'first line is here')


def test_store_overwrites_existing_value() raises:
    var database = Database()
    _ = database.process('store greeting old value')
    _ = database.process('store greeting new value')
    assert_equal(database.process('fetch greeting'), 'new value')


def test_store_without_value_returns_usage_message() raises:
    var database = Database()
    assert_equal(database.process('store greeting'), 'usage: store KEY VALUE...')


def test_fetch_absent_key_returns_not_found_message() raises:
    var database = Database()
    assert_equal(database.process('fetch missing'), 'not found: missing')


def test_fetch_without_key_returns_usage_message() raises:
    var database = Database()
    assert_equal(database.process('fetch'), 'usage: fetch KEY')


def test_delete_removes_present_key() raises:
    var database = Database()
    _ = database.process('store greeting hello world')
    _ = database.process('store farewell goodbye')
    assert_equal(database.process('delete greeting'), 'deleted greeting')
    assert_equal(database.process('fetch greeting'), 'not found: greeting')
    assert_equal(database.process('fetch farewell'), 'goodbye')


def test_delete_absent_key_returns_not_found_message() raises:
    var database = Database()
    assert_equal(database.process('delete missing'), 'not found: missing')


def test_delete_without_key_returns_usage_message() raises:
    var database = Database()
    assert_equal(database.process('delete'), 'usage: delete KEY')


def test_keys_lists_every_stored_key() raises:
    var database = Database()
    _ = database.process('store alpha 1')
    _ = database.process('store beta 2')
    var all_stored_keys = database.process('keys')
    assert_true(all_stored_keys.find(String('alpha')) >= 0)
    assert_true(all_stored_keys.find(String('beta')) >= 0)


def test_keys_empty_database_returns_empty_string() raises:
    var database = Database()
    assert_equal(database.process('keys'), '')


def test_unknown_command_returns_unknown_command_message() raises:
    var database = Database()
    assert_equal(database.process('frobnicate'), 'unknown command: frobnicate')


def test_empty_input_returns_usage_message() raises:
    var database = Database()
    assert_equal(database.process(''), 'empty command. usage: store/fetch/delete/keys')


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
