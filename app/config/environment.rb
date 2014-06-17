# encoding: utf-8

require 'app/versione'
require 'active_record'
require 'pg'
require 'yaml'
require 'configatron'
require 'app/helpers/logger_helper'
require 'app/helpers/authorization_helper'
require 'app/models/base'
require 'app/models/db_server'
require 'socket'
require 'timeout'
require 'net/http'
require 'uri'
#require 'rinda/ring'
#require 'rinda/tuplespace'
require 'app/models/postgres_db_server'

module PaperclipConfig
  extend Versione

#  module RindaServer
#    def db_server
#      begin
#        DRb.start_service
#
#        ring_server = Timeout::timeout(5) do
#          Rinda::RingFinger.finger.primary
#        end
#
#        service = ring_server.read([:postgres_db_service, nil, nil, nil])
#
#        Models::DbServer.new(service[2].attributes)
#
#      rescue Timeout::Error, RuntimeError
#        return Models::PostgresDbServer.new(
#          :adapter => 'postgresql',
#          :encoding => 'utf-8',
#          :database => 'rinda server',
#          :username => 'rinda',
#          :password => 'rinda',
#          :host => 'rinda',
#          :port => 0
#        )
#      end
#    end
#
#    module_function :db_server
#
#  end

  module UDPClient
    UDP_SERVER_PORT = 1759
    UDP_CLIENT_PORT = 17599

    def self.broadcast_to_potential_servers!()
      s = UDPSocket.new
      s.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      s.send('', 0, '<broadcast>', UDP_SERVER_PORT)
      s.close
    end

    def self.start_server_listener(time_out=5, &code)
      Thread.fork do
        s = UDPSocket.new
        s.bind('0.0.0.0', UDP_CLIENT_PORT)

        begin
          body, sender = timeout(time_out) { s.recvfrom(1024) }
#          p sender
          server_ip = sender[3]
          conf = Marshal.load(body)
          code.call(conf['database']['postgresql'], server_ip)
          s.close
        rescue Timeout::Error
          s.close
          raise
        end
      end
    end

    def self.query_db_server(time_out=5)
      db_server = nil

      # puts "starting server listener..."
      thread = UDPClient::start_server_listener(time_out) do |conf, server_ip|
        #puts "response: #{conf} from server #{server_ip}"
        db_server = Models::DbServer.new(conf.merge({:host => server_ip}))
      end

      # puts "broadcast to potential servers..."
      UDPClient::broadcast_to_potential_servers!()

      begin
        # puts "waiting for response..."
        thread.join
      rescue Timeout::Error, RuntimeError
        db_server = Models::PostgresDbServer.new(
          :adapter => 'postgresql',
          :encoding => 'utf-8',
          :database => 'udp server',
          :username => 'udp',
          :password => 'udp',
          :host => 'udp',
          :port => 0
        )
      end

      return db_server
    end

  end

  module Db

    def connect_local()
      ActiveRecord::Base.establish_connection(
        :adapter => 'sqlite3',
        :database => File.join('db', configatron.env, 'bra.db'),
        :encoding => 'utf8'

      )

      PaperclipConfig::Boot.info = "Connesso a localhost"
    end

    module_function :connect_local

    def connect_remote(db_server)
      ActiveRecord::Base.establish_connection(
        :adapter => db_server.adapter,
        :host => db_server.host,
        :port => db_server.port,
        :username => db_server.username,
        :password => db_server.password,
        :database => db_server.database,
        :encoding => db_server.encoding

      )

      # testo la connessione
      ActiveRecord::Base.connection

    end

    module_function :connect_remote
  end

  class Boot

    cattr_accessor :info
    cattr_accessor :error

    configatron.configure_from_hash(YAML.load_file('conf/paperclip.yml'))

    configatron.env = (ENV['PAPERCLIP_ENV'] || 'development')

    # modalita di connessione al db
    configatron.connection.mode = :local unless configatron.connection.has_key?(:mode)

    ActiveRecord::Base.logger = logger = Helpers::Logger::LoggerHelper.instance()

    PaperclipConfig::Db.connect_local()

    require 'app/config/autoload'

    ActiveRecord::Base.extend Models::Base::Searchable

    ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS.merge!(
      :italian_date => "%d/%m/%Y",
      :italian_short_date => "%d/%m/%y",
      :year => "%Y",
      :short_year => "%y"
    )

    ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
      :italian_time => "%d/%m/%Y H::M",
      :italian_date => "%d/%m/%Y",
      :italian_short_time => "%d/%m/%y H::M",
      :italian_short_date => "%d/%m/%y",
      :year => "%Y",
      :short_year => "%y"
    )

    begin
#
#      logger.debug("db version: #{Models::Licenza.first.versione}")
#
#      unless PaperclipConfig.update_version!
#        raise "Aggiornare Paperclip: versione obsoleta."
#      end

#      require 'pry'
#
#      binding.pry

      # avvio il processo di migrazione
      if configatron.env == 'production'
        if File.directory? 'db/migrations'
          FileUtils.mkdir_p 'db/backup' unless File.directory? 'db/backup'
          backup_db = File.join('db/backup', Time.now.strftime("%d_%m_%Y_%H_%M_%S") + '.backup')
          FileUtils.cp File.join('db', configatron.env, 'bra.db'), backup_db
          ActiveRecord::Migration.verbose = false
          ActiveRecord::Migrator.migrate('db/migrations', nil)
        end

        if Models::Azienda.first.nome == 'DEMO'
          unless Models::Licenza.first
            # licenza data scadenza
            Models::Licenza.create(
              :numero_seriale => '',
              :data_scadenza => PaperclipConfig.demo_period,
              :versione => PaperclipConfig.release
            )
          end
        end

        self.error = RuntimeError.new("Aggiornare Paperclip: versione obsoleta.") unless PaperclipConfig.update_version!

        load 'db/patch.rb' if File.exist?('db/patch.rb')

        # clean tmp dir
        FileUtils.rm Dir.glob('./tmp/*.pdf')

      end

      # insert into db_server (id, adapter, host, port, username, password, 'database', encoding) values (1, 'postgresql', 'Fabio-thinkpad', 5432, 'postgres', 'paperclip', 'paperclip', 'utf-8')
      if configatron.connection.mode == :remote
#        db_server = Models::DbServer.first() || PaperclipConfig::RindaServer.db_server
        db_server = Models::DbServer.first() || PaperclipConfig::UDPClient.query_db_server()

        if db_server

          PaperclipConfig::Db.connect_remote(db_server)

          self.info = "Connesso al server #{db_server.host}"

          # avvio il processo di migrazione del db server
          if configatron.env == 'production'
            if File.directory? 'db/migrations'
              ActiveRecord::Migration.verbose = false
              ActiveRecord::Migrator.migrate('db/migrations', nil)
            end

            if Models::Azienda.first.nome == 'DEMO'
              unless Models::Licenza.first
                # licenza data scadenza
                Models::Licenza.create(
                  :numero_seriale => '',
                  :data_scadenza => PaperclipConfig.demo_period,
                  :versione => PaperclipConfig.release
                )
              end
            end

            self.error = RuntimeError.new("Aggiornare Paperclip: versione obsoleta.") unless PaperclipConfig.update_version!

            load 'db/patch.rb' if File.exist?('db/patch.rb')
          end
        end
      end
    rescue ActiveRecord::StatementInvalid => si
      logger.error("Error connecting to db server: #{si.message}")
      self.error = si
    rescue PGError => pge
      logger.error("Error connecting to db server: #{db_server.inspect}\n#{pge.message}")
      self.error = pge
      PaperclipConfig::Db.connect_local()
    rescue => e
      logger.error("Error connecting to db server: #{e.class} #{e.message}")
      self.error = e
    else
      if configatron.env == 'production'
        if File.directory? 'db/migrations'
          FileUtils.rm_rf 'db/migrations' unless ENV['PAPERCLIP_BUILD']
        end
        unless ENV['PAPERCLIP_BUILD']
          FileUtils.rm 'db/patch.rb' if File.exist?('db/patch.rb')
        end
      end
    end

    def self.windows_platform?
      RUBY_PLATFORM =~ /(win|w)32$/
    end
  end
end
