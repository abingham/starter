
require_relative '../src/rack_dispatcher'
require_relative 'rack_request_stub'
require_relative 'test_base'

class RackDispatcherTest < TestBase

  def self.hex_prefix
    'D06F7'
  end

  # - - - - - - - - - - - - - - - - -

  test 'BB0',
  %w( unknown method-name becomes exception ) do
    body,stderr = assert_rack_call_raw(400, 'blah', '{}')
    assert_exception('ClientError', 'json:malformed', body, stderr)

    body,stderr = assert_rack_call_raw(400, 'Languages_choices', '{}')
    assert_exception('ClientError', 'json:malformed', body, stderr)

    body,stderr = assert_rack_call_raw(400, 'a b', '{}')
    assert_exception('ClientError', 'json:malformed', body, stderr)
  end

  # - - - - - - - - - - - - - - - - -

  test 'BB1',
  %w( invalid json in http payload becomes exception ) do
    body,stderr = assert_rack_call_raw(500, 'languages_choices', 'sdfsdf')
    assert_exception('JSON::ParserError', "765: unexpected token at 'sdfsdf'", body, stderr)

    body,stderr = assert_rack_call_raw(500, 'languages_choices', 'nil')
    assert_exception('JSON::ParserError', "765: unexpected token at 'nil'", body, stderr)
  end

  # - - - - - - - - - - - - - - - - -

  test 'BB2',
  %w( non-hash in http payload becomes exception ) do
    body,stderr = assert_rack_call_raw(400, 'languages_choices', 'null')
    assert_exception('ClientError', 'json:malformed', body, stderr)

    body,stderr = assert_rack_call_raw(400, 'languages_choices', '[]')
    assert_exception('ClientError', 'json:malformed', body, stderr)
  end

end
