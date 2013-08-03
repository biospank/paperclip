require 'timeout'
require 'rinda/ring'
require 'rinda/tuplespace'
require 'app/models/postgres_db_server'


class RindaClient

  def self.db_server
    begin
      DRb.start_service

      ring_server = Timeout::timeout(5) do
        Rinda::RingFinger.primary
      end
      
      service = ring_server.read([:postgres_db_service, nil, nil, nil])

      service[2]
    rescue Timeout::Error, RuntimeError
      return nil
    end
  end

end

if __FILE__ == $0

  if server = RindaClient.db_server
    puts "Server db: #{server.database}"
    puts "Server username: #{server.username}"
    puts "Server password: #{server.password}"
    puts "Server password: #{server.encoding}"
    puts "Server host: #{server.host}"
    puts "Server port: #{server.port}"
  else
    puts "Server not found"
  end
end