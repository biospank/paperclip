
require 'rubygems'
require "socket"
require "timeout"
require 'yaml'
require 'win32/daemon'
#add the current directory to library path
# $: << File.expand_path('../', File.dirname(__FILE__))

include Win32

# call from command line: ruby app\udp_server.rb

# ERROR_LOG_FILE = "#{`echo %cd%`.chomp}\\..\\error.log"
#
# def log(text)
#   File.open(ERROR_LOG_FILE, 'a') { |f| f.puts text }
# end

module UDPServer

  UDP_SERVER_PORT = 1759
  UDP_CLIENT_PORT = 17599

  def answer_client(ip, port, response)
    # puts "Sending response..."
    s = UDPSocket.new
    s.send(Marshal.dump(response), 0, ip, port)
    s.close
  end

  def start_service_announcer()
    db_conf = {
      'database' => {
        'postgresql' => {
          'adapter' => 'postgresql',
          'encoding' => 'utf-8',
          'database' => 'paperclip',
          'username' => 'postgres',
          'password' => 'postgres',
          'port' => 5432
        }
      }
    }

    # puts "Starting Server announcer..."
    # Thread.fork do
      s = UDPSocket.new
      s.bind('0.0.0.0', UDP_SERVER_PORT)

      loop do
        body, sender = s.recvfrom(1024)
        client_ip = sender[3]
#        data = Marshal.load(body)
#        client_port = data[:reply_port]

        begin
          answer_client(client_ip, UDP_CLIENT_PORT, db_conf)
        rescue
          #log "error: #{$!}"
        end

      end
    # end
  end

end


# start win installation
# sc create pserver binPath= "C:\Ruby193\bin\ruby.exe -C c:\fabio\lavoro\paperclip\git\paperclip app\win_udp_server.rb" type= own start= auto
# sc start pserver
# sc stop pserver
# sc delete pserver

begin

  class PserverDaemon < Daemon
    include UDPServer
    # attr_reader :service_thread

    def service_main
      #log "Starting Server..."
      # @service_thread = UDPServer.start_service_announcer(UDP_SERVER_PORT)
      start_service_announcer()
      #log 'Started!!'
      # @service_thread.join
    end

    def service_stop
      #log 'Ended'
      # @service_thread.exit
      exit!
    end

  end

  PserverDaemon.mainloop unless defined?(Ocra)

rescue Exception => err
  #log " ***Daemon failure err=#{err.message} "
  #log "error: #{err.message} stack: #{err.backtrace.join("\n")}"
  raise
end
