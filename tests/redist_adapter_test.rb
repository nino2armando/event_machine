require 'test/unit'
require 'redis'

class RedisAdapterTest < Test::Unit::TestCase

  def test_simple
  redis = Redis.new(:host => "127.0.0.1", :port => 6379)

    redis.set("a","clinet one")
    puts redis.get("a")

  end


end