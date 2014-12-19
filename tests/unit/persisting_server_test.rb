require 'test/unit'
require 'mocha'

require_relative '../../src/persisting_server'

class PersistingServerTest < Test::Unit::TestCase

  def setup
    @redis = Redis.new(:host => "127.0.0.1", :port => 6379)
    @persisting_server = PersistingServer
    # need to fix this dependency injection stuff
  end

end