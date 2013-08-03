require 'rinda/ring'
require 'rinda/tuplespace'
require File.dirname(__FILE__) + '/models/postgres_db_server'

rinda_conf = YAML.load(File.open(File.dirname(__FILE__) + '/config/rinda.yml'))

DRb.start_service
Rinda::RingServer.new(Rinda::TupleSpace.new)

ring_server = Rinda::RingFinger.primary
# [:name, :Class, instance_of_class, 'description']
#ring_server.write([:postgres_db_service, :PostgresDbServer, Models::PostgresDbServer.new, 'Postgres db service'], Rinda::SimpleRenewer.new) # expire in 180 seconds and refresh
ring_server.write([:postgres_db_service, :PostgresDbServer, Models::PostgresDbServer.new(rinda_conf['database']['postgresql']), 'Postgres db service'], nil) # never expire

DRb.thread.join
