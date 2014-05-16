# encoding: utf-8

require 'socket'
require 'timeout'
require 'net/http'
require 'uri'

module UDPClient
  UDP_SERVER_PORT = 1759
  UDP_CLIENT_PORT = 17599

  def self.broadcast_to_potential_servers!()
    s = UDPSocket.new
    s.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
    s.send('', 0, '<broadcast>', UDP_SERVER_PORT)
    s.close
  end

  def self.start_server_listener(time_out=3, &code)
    Thread.fork do
      s = UDPSocket.new
      s.bind('0.0.0.0', UDP_CLIENT_PORT)

      begin
        body, sender = timeout(time_out) { s.recvfrom(1024) }
#          p sender
        server_ip = sender[3]
        conf = Marshal.load(body)
        code.call(conf['database']['postgresql'], server_ip)
        # code.call(conf, server_ip)
        s.close
      rescue Timeout::Error
        s.close
        raise
      end
    end
  end

end

puts "starting server listener..."
thread = UDPClient::start_server_listener(3) do |conf, server_ip|
  puts "response: #{conf} from server #{server_ip}"
end

puts "broadcast to potential servers..."
UDPClient::broadcast_to_potential_servers!()

begin
  puts "waiting for response..."
  thread.join
rescue Timeout::Error, RuntimeError
  puts "error #{$!}"
end
