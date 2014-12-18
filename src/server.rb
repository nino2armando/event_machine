require 'eventmachine'

class Server < EventMachine::Connection

  @@connected_clients = Array.new

  attr_reader :username
  attr_accessor :session_buddy, :echoMode

  def post_init
    @@connected_clients.push(self)
    puts "client connected..."
    ask_username
  end

  def receive_data(data)
    formatted = remove_linebreak(data)
    if formatted.empty? || formatted.nil?
      formatted
    else
      if @username.nil? || @username.empty?
        handle_username(formatted)
      elsif @session_buddy.nil? && !@echoMode
        define_session(formatted)
      elsif formatted == "menu"
        @@connected_clients.each do |c|
          puts c.username
        end
        send_data("we will display menu here soon")
      elsif formatted == "exit"
        self.close_connection
      else
        if @echoMode
          handle_echo_message(formatted) # right now we only echo
        else
          handle_message(formatted)
        end

      end
    end

  end

  def unbind
    @@connected_clients.delete(self)
    broadcast("[#{@username}] is now offline!\n")
    # here we need to adjust the session buddy stuff or maybe detect user offline
    puts "Client disconnected..."

  end

  # helpers

  def remove_linebreak(input)
    input.chomp
  end

  def handle_echo_message(data)
    send_data("#{@username}: #{data}\n")
  end

  def handle_message(data)
    @session_buddy.send_data("#{@username}: #{data}\n")
  end

  def handle_username(data)
    if data.empty?
      send_data("username can not be empty\n")
      ask_username
    else
      @username = data
      send_data("Welcome #{username}! \n")
      display_options
      display_onlineUsers
      divider
      broadcast("[#{@username}] is now online!\n")
      if@@connected_clients.count == 1
        send_data("nobody is online to talk to, switching to echo mode\n")
        @echoMode = true
      else
        ask_sessionBuddy
      end

    end
  end

  def define_session(data)
    user = data.chomp
    clientExits = @@connected_clients.find{|c| c.username == user}
    if user.empty?
      ask_sessionBuddy
    elsif clientExits.nil?
      send_data("enter a valid username:")
    else
      @session_buddy = @@connected_clients.find { |b| b.username == user}
      clientExits.session_buddy = self
      clientExits.echoMode = false
    end

  end

  def ask_sessionBuddy
    send_data("enter a user name to talk to:")
  end

  def divider
    send_data(String.new("-"*50)+"\n")
  end

  def display_options
    self.send_data("Note: type \"menu\" to see additional options\n")
  end

  def display_onlineUsers
    send_data("Online:\n")
    @@connected_clients.each do |connected|
      if connected.username != self.username
        send_data("[#{connected.username}]\n")
      end

    end
  end

  def ask_username
    self.send_data("Please enter username: ")
  end

  def broadcast(msg)
    @@connected_clients.each do |c|
        c.send_data(msg)
    end
  end

end

EventMachine.run do

  # hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server("127.0.0.1", 10000, Server)
end