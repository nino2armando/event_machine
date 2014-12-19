require 'eventmachine'
require 'redis'

class PersistingServer < EventMachine::Connection

  attr_writer :redis
  attr_reader :username
  attr_accessor :partner

  ONLINE_USERS = 14
  ONE_TWO_ONE = 15

  def redis
    @redis ||= Redis.new(:host => "127.0.0.1", :port => 6379)
  end

  def post_init
    send_data("username:")
  end

  def receive_data(data)
    formatted = data.chomp
    if formatted.empty? || formatted.nil?
      formatted
    elsif @username.nil? || @username.empty?
      handle_username(formatted)
    elsif formatted == ":menu"
      display_menu
    elsif formatted == ":show"
      display_online
    elsif formatted == ":exit"
      self.close_connection
    elsif formatted.include? ":select[*]"
      formatted.slice! ":select[*]"
      broadcast("[all]: #{formatted}\n")
    elsif @partner.nil?
        define_session(formatted)
    else
      handle_message(formatted)
    end

  end

  def unbind
    redis.select(ONLINE_USERS)
    redis.del(self.object_id)
    redis.select(ONE_TWO_ONE)
    redis.del(@username)
    broadcast("#{@username} is now offline #{Time.now.strftime("%d/%m/%Y %H:%M")}\n")
  end

  # helper method

  def handle_message(data)
    @partner.send_data("[#{@username}]: #{data}\n")
  end

  def define_session(data)
    redis.select(ONLINE_USERS)
    all_users = get_users(ONLINE_USERS)
    partner_id = all_users.find {|key|data.include? redis.get(key)}

    if data.empty?
      ask_partner
    elsif partner_id.nil?
      send_data("not a valid user\n")
    else
      @partner = get_object(partner_id)
      redis.select(ONE_TWO_ONE)
      redis.set(@username, partner_id)
      redis.set(@partner.username, self.object_id)
      @partner.partner = self
    end

  end
  def ask_partner
    send_data("enter a username to talk to:")
  end


  def get_object(objId)
    # dont forget if garbage collection is called this obj id is lost :-O
    em_class = ObjectSpace._id2ref(objId.to_i)
    em_class
  end

  def broadcast(msg)
    users = get_users(ONLINE_USERS)
    users.each do |objId|
      connected_client = get_object(objId)
      connected_client.send_data(msg)
    end
  end

  def get_users(db)
    # we need to select db
    redis.select(db)
    all_users = redis.keys("*")
    all_users
  end

  def display_online
    all_users = get_users(ONLINE_USERS)
    send_data("- type :select[username] to talk to the specific user\n")
    send_data("- type :select[*] followed by the message to broadcast\n")
    send_data("Online:\n")
    all_users.each do |id|
      send_data("#{redis.get(id)}\n")
    end
    divider
  end

  def display_welcome
    send_data("- type :menu to display more options and :exit to exit\n")
    broadcast("#{@username} is now online #{Time.now.strftime("%d/%m/%Y %H:%M")}\n")
    divider
  end

  def divider
    send_data(String.new("-"*50)+"\n")
  end

  def display_menu
    send_data("- type :show to display online users\n")
    send_data("- type :exit to exit\n")
    divider
  end

  def handle_username(input)
    if input.empty?
      send_data("username can not be empty\n")
      ask_username
    else
      @username = input
      redis.select(ONLINE_USERS)
      redis.set(self.object_id, @username)
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


  EventMachine.start_server("127.0.0.1", 10001, PersistingServer)

end