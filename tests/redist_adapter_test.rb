require 'test/unit'
require 'redis'
require 'json'


class RedisAdapterTest < Test::Unit::TestCase

  def setup
    @redis = Redis.new(:host => "127.0.0.1", :port => 6379)
  end

  def test_simple


=begin
    redis.set("a","clinet one")
    puts redis.get("a")
=end


    obj = TestObject.new()
    obj.name = "nino"
    obj.id = 1

    j = obj.to_json

    @redis.set("1", j)
    redisPayload = @redis.get("1")



    s = obj.from_json!(redisPayload)


   puts s["@id"]
    puts s["@name"]





  end


  def test_redis_key_update
    @redis.set("online","1")
    puts @redis.get("online")

    @redis.set("online", "1,2,3")
    puts @redis.get("online")
  end


end


class TestObject

  attr_accessor :name, :id


  def to_json
    hash = {}
    self.instance_variables.each do |var|
      hash[var] = self.instance_variable_get var
    end
    hash.to_json
  end
  def from_json! string
    JSON.load(string).each do |var, val|
      self.instance_variable_set var, val
    end
  end
end



