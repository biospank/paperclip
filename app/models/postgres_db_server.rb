require 'socket'

module Models
  class PostgresDbServer
    #include DRbUndumped
    attr_accessor :adapter, :host, :port, :username, :password, :database, :encoding

    def initialize(conf)
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

      self.host = UDPSocket.open do |s|
        s.connect('64.233.187.99', 1)
        s.addr.last
      end
      
      conf.each do |k, v|
        send("#{k}=", v)
      end

    ensure
      Socket.do_not_reverse_lookup = orig
    end

    def attributes
      {
        :adapter => self.adapter, 
        :host => self.host, 
        :port => self.port, 
        :username => self.username, 
        :password => self.password, 
        :database => self.database, 
        :encoding => self.encoding
      }
    end
  end
end
