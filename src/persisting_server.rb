require 'eventmachine'
require 'redis'

class PersistingServer < EventMachine::Connection

  @username

  def initialize(redis)
    @redis = redis
  end


  def post_init
    #@redis.set("online",self.object_id)
    send_data("username:")
  end

  def receive_data(data)
    formatted = data.chomp

    if @username.nil? || @username.empty?
      handle_username(formatted)
    elsif formatted == ":menu"
      display_menu
    elsif formatted == ":show"
      display_online
    elsif formatted == ":exit"
      self.close_connection
    else
      # handle message
    end


    # dont forget if garbage collection is called this obj id is lost :-O
    # obj_id = @redis.get("online").to_i
    # thisclass = ObjectSpace._id2ref(obj_id)
    # thisclass.send_data("hello")
  end

  def unbind
    @redis.del(self.object_id)
  end

  # helper method

  def display_online
    @redis.select(14)
    all_users = @redis.keys("*")
    send_data("Online:\n")

    all_users.each do |u|
      send_data("#{@redis.get(u)}\n")
    end

  end

  def display_welcome
    send_data("type :menu to display more options and :exit to exit\n")
    divider
    display_online
  end

  def divider
    send_data(String.new("-"*50)+"\n")
  end

  def display_menu
    send_data("- type :show to display online users\n")
    send_data("- type :exit to exit\n")
  end

  def handle_username(input)
    if input.empty?
      send_data("username can not be empty\n")
      ask_username
    else
      @username = input
      @redis.set(self.object_id, @username)
      display_welcome
    end

  end


  def ask_username
    send_data("username:")
  end


end

EventMachine.run do

  # hit Control + C to stop
  Signal.trap("INT"){EventMachine.stop}
  Signal.trap("TERM"){EventMachine.stop}


  redis = Redis.new(:host => "127.0.0.1", :port => 6379, :db => 14)

  EventMachine.start_server("127.0.0.1", 10001, PersistingServer, redis)

end