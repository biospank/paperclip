require "socket"
require "timeout"
require 'yaml'

# call from command line: ruby app\udp_server.rb

module UDPServer

  UDP_CLIENT_PORT = 17599

  def self.answer_client(ip, port, response)
    # puts "Sending response..."
    s = UDPSocket.new
    s.send(Marshal.dump(response), 0, ip, port)
    s.close
  end

  def self.start_service_announcer(server_udp_port)
    db_conf = YAML.load(File.open(File.dirname(__FILE__) + '/config/udp.yml'))

    # puts "Starting Server announcer..."
    Thread.fork do
      s = UDPSocket.new
      s.bind('0.0.0.0', server_udp_port)

      loop do
        body, sender = s.recvfrom(1024)
        client_ip = sender[3]
#        data = Marshal.load(body)
#        client_port = data[:reply_port]


        begin
          answer_client(client_ip, UDP_CLIENT_PORT, db_conf)
        rescue
          # Make sure thread does not crash
        end

      end
    end
  end

end

UDP_SERVER_PORT = 1759

# puts "Starting Server..."

thread = UDPServer.start_service_announcer(UDP_SERVER_PORT)

# puts "Server running on port #{UDP_SERVER_PORT}."

thread.join #unless ENV['OCRA_BUILD']
