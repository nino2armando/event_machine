require 'eventmachine'

class Server < EventMachine::Connection

  @@connected_clinets = Array.new

  attr_reader :username

  def post_init
    @@connected_clinets.push(self)
    puts "client connected..."
    ask_username
  end

  def receive_data(data)
    if data == "\n"
      data
    end

    if @username.nil? || @username.empty?
      handle_username(data)
    else
      handle_message(data)
    end


    #send_data(data)
  end

  def unbind
    @@connected_clinets.delete(self)
    puts "Clinet disconnected..."
  end

  # helpers

  def handle_message(data)
    send_data("#{@username}: #{data}")
  end

  def handle_username(data)
    if data.empty?
      puts "username can not be empty"
      ask_username
    else
      @username = data
    end
  end

  def ask_username
    self.send_data("Please enter username: ")
  end


end

EventMachine.run do
  # hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server("127.0.0.1", 10000, Server)
end