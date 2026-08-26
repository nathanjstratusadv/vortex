from std.testing import TestSuite, assert_equal, assert_true
from database.database import Database


def test_store_and_fetch() raises:
    var database = Database()
    database.store('greeting', 'hello world')
    assert_true(database.contains('greeting'))
    assert_equal(database.fetch('greeting'), 'hello world')


def test_store_overwrites_existing_value() raises:
    var database = Database()
    database.store('greeting', 'old value')
    database.store('greeting', 'new value')
    assert_equal(database.fetch('greeting'), 'new value')


def test_fetch_absent_key_returns_empty_string() raises:
    var database = Database()
    assert_equal(database.fetch('missing'), '')


def test_delete_removes_present_key() raises:
    var database = Database()
    database.store('greeting', 'hello world')
    database.store('farewell', 'goodbye')
    assert_equal(database.delete('greeting'), True)
    assert_true(not database.contains('greeting'))
    assert_equal(database.fetch('farewell'), 'goodbye')


def test_delete_absent_key_returns_false() raises:
    var database = Database()
    assert_equal(database.delete('missing'), False)


def test_all_keys_lists_every_stored_key() raises:
    var database = Database()
    database.store('alpha', '1')
    database.store('beta', '2')
    var all_stored_keys = database.all_keys()
    assert_true(all_stored_keys.find(String('alpha')) >= 0)
    assert_true(all_stored_keys.find(String('beta')) >= 0)


def test_all_keys_empty_database_returns_empty_string() raises:
    var database = Database()
    assert_equal(database.all_keys(), '')


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()

