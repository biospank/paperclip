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

    def self.query_db_server(time_out=3)
      db_server = nil

      # puts "starting server listener..."
      thread = UDPClient::start_server_listener(time_out) do |conf, server_ip|
        puts "response: #{conf} from server #{server_ip}"
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

    # begin to remove
#    unless configatron.configure_from_yaml('conf/paperclip.yml')
#    # end to remove
#      require 'conf/paperclip.rb'
#    end

    #configatron.set_default(:env, (ENV['PAPERCLIP_ENV'] || 'development'))
    configatron.env = (ENV['PAPERCLIP_ENV'] || 'development')

    # modalita di connessione al db
    configatron.connection.set_default(:mode, :local)

    ActiveRecord::Base.logger = logger = Helpers::Logger::LoggerHelper.instance()

    PaperclipConfig::Db.connect_local()

    Helpers.autoload 'BusinessClassHelper', 'app/helpers/business_class_helper.rb'

#    Dir.glob('app/models/*.rb') do |filename|
#      Models.autoload filename.split('/').last[0..-4].camelize, filename
#    end

    Models.autoload 'Aliquota', 'app/models/aliquota.rb'
    Models.autoload 'Azienda', 'app/models/azienda.rb'
    Models.autoload 'Banca', 'app/models/banca.rb'
    #Models.autoload 'Base', 'app/models/base.rb' # viene caricato direttamente
    Models.autoload 'Categoria', 'app/models/categoria.rb'
    Models.autoload 'Causale', 'app/models/causale.rb'
    Models.autoload 'Cliente', 'app/models/cliente.rb'
    Models.autoload 'DatiAzienda', 'app/models/dati_azienda.rb'
    Models.autoload 'Ddt', 'app/models/ddt.rb'
    Models.autoload 'FatturaCliente', 'app/models/fattura_cliente.rb'
    Models.autoload 'FatturaClienteFatturazione', 'app/models/fattura_cliente_fatturazione.rb'
    Models.autoload 'FatturaClienteScadenzario', 'app/models/fattura_cliente_scadenzario.rb'
    Models.autoload 'FatturaFornitore', 'app/models/fattura_fornitore.rb'
    Models.autoload 'Filtro', 'app/models/filtro.rb'
    Models.autoload 'Fornitore', 'app/models/fornitore.rb'
    Models.autoload 'IncassoRicorrente', 'app/models/incasso_ricorrente.rb'
    Models.autoload 'Licenza', 'app/models/licenza.rb'
    Models.autoload 'MaxiPagamentoCliente', 'app/models/maxi_pagamento_cliente.rb'
    Models.autoload 'MaxiPagamentoFornitore', 'app/models/maxi_pagamento_fornitore.rb'
    Models.autoload 'NotaSpese', 'app/models/nota_spese.rb'
    Models.autoload 'PagamentoFatturaCliente', 'app/models/pagamento_fattura_cliente.rb'
    Models.autoload 'PagamentoFatturaFornitore', 'app/models/pagamento_fattura_fornitore.rb'
    Models.autoload 'PagamentoPrimaNota',  'app/models/pagamento_prima_nota.rb'
    Models.autoload 'Profilo',  'app/models/profilo.rb'
    Models.autoload 'Progressivo',  'app/models/progressivo.rb'
    Models.autoload 'ProgressivoDdt',  'app/models/progressivo_ddt.rb'
    Models.autoload 'ProgressivoFatturaCliente',  'app/models/progressivo_fattura_cliente.rb'
    Models.autoload 'ProgressivoNc',  'app/models/progressivo_nc.rb'
    Models.autoload 'ProgressivoNotaSpese',  'app/models/progressivo_nota_spese.rb'
    Models.autoload 'RigaDdt',  'app/models/riga_ddt.rb'
    Models.autoload 'RigaFatturaCliente',  'app/models/riga_fattura_cliente.rb'
    Models.autoload 'RigaFatturaCommercio',  'app/models/riga_fattura_commercio.rb'
    Models.autoload 'RigaFatturaServizi',  'app/models/riga_fattura_servizi.rb'
    Models.autoload 'RigaNotaSpese',  'app/models/riga_nota_spese.rb'
    Models.autoload 'RigaNotaSpeseCommercio',  'app/models/riga_nota_spese_commercio.rb'
    Models.autoload 'RigaNotaSpeseServizi',  'app/models/riga_nota_spese_servizi.rb'
    Models.autoload 'Ritenuta',  'app/models/ritenuta.rb'
    Models.autoload 'Scrittura',  'app/models/scrittura.rb'
    Models.autoload 'TipoPagamento',  'app/models/tipo_pagamento.rb'
    Models.autoload 'TipoPagamentoCliente',  'app/models/tipo_pagamento_cliente.rb'
    Models.autoload 'TipoPagamentoFornitore',  'app/models/tipo_pagamento_fornitore.rb'
    Models.autoload 'Utente',  'app/models/utente.rb'
    Models.autoload 'IdentModel',  'app/models/ident_model.rb'
    Models.autoload 'DbServer',  'app/models/db_server.rb'

    Models.autoload 'Ordine',  'app/models/ordine.rb'
    Models.autoload 'RigaOrdine',  'app/models/riga_ordine.rb'
    Models.autoload 'Prodotto',  'app/models/prodotto.rb'
    Models.autoload 'Movimento',  'app/models/movimento.rb'
    Models.autoload 'Carico',  'app/models/carico.rb'
    Models.autoload 'Scarico',  'app/models/scarico.rb'

    Models.autoload 'Modulo',  'app/models/modulo.rb'
    Models.autoload 'ModuloAzienda',  'app/models/modulo_azienda.rb'
    Models.autoload 'Permesso',  'app/models/permesso.rb'

    Models.autoload 'Pdc',  'app/models/pdc.rb'
    Models.autoload 'Costo',  'app/models/costo.rb'
    Models.autoload 'Ricavo',  'app/models/ricavo.rb'
    Models.autoload 'Attivo',  'app/models/attivo.rb'
    Models.autoload 'Passivo',  'app/models/passivo.rb'
    Models.autoload 'RigaFatturaPdc',  'app/models/riga_fattura_pdc.rb'
    Models.autoload 'Norma',  'app/models/norma.rb'

    Models.autoload 'Corrispettivo',  'app/models/corrispettivo.rb'
    Models.autoload 'CorrispettivoPrimaNota',  'app/models/corrispettivo_prima_nota.rb'

    Models.autoload 'CategoriaPdc',  'app/models/categoria_pdc.rb'

    Models.autoload 'SaldoIvaMensile',  'app/models/saldo_iva_mensile.rb'
    Models.autoload 'SaldoIvaTrimestrale',  'app/models/saldo_iva_trimestrale.rb'

    Models.autoload 'InteressiLiquidazioneTrimestrale',  'app/models/interessi_liquidazione_trimestrale.rb'

    Models.autoload 'ProgressivoCliente',  'app/models/progressivo_cliente.rb'
    Models.autoload 'ProgressivoFornitore',  'app/models/progressivo_fornitore.rb'

    Models.autoload 'ScritturaPd',  'app/models/scrittura_pd.rb'
    Models.autoload 'PagamentoPartitaDoppia',  'app/models/pagamento_partita_doppia.rb'
    Models.autoload 'CorrispettivoPartitaDoppia',  'app/models/corrispettivo_partita_doppia.rb'
    Models.autoload 'DettaglioFatturaPartitaDoppia',  'app/models/dettaglio_fattura_partita_doppia.rb'
    Models.autoload 'PrimaNotaPartitaDoppia',  'app/models/prima_nota_partita_doppia.rb'

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

      # avvio il processo di migrazione
      if configatron.env == 'production'
        if File.directory? 'db/migrations'
          FileUtils.mkdir_p 'db/backup' unless File.directory? 'db/backup'
          backup_db = File.join('db/backup', Time.now.strftime("%d_%m_%Y_%H_%M_%S") + '.backup')
          FileUtils.cp File.join('db', configatron.env, 'bra.db'), backup_db
          ActiveRecord::Migration.verbose = false
          ActiveRecord::Migrator.migrate('db/migrations', nil)
        end

        unless PaperclipConfig.update_version!
          self.error = RuntimeError.new("Aggiornare Paperclip: versione obsoleta.")
        end

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

            unless PaperclipConfig.update_version!
              self.error = RuntimeError.new("Aggiornare Paperclip: versione obsoleta.")
            end

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
          begin
#            if configatron.connection.mode == :remote
#              db_server = Models::DbServer.first()
#              if db_server && db_server.host == local_ip
#                FileUtils.rm Dir.glob('./updates/*')
#                create_7z_archive("updates/#{PaperclipConfig.last_release()}.zip",
#                  'db/migrations',
#                  'resources',
#                  'lib')
#              end
#            end
          rescue Exception => e
            logger.error("error creating archive: #{e.message}")
            self.error = e
          else
            FileUtils.rm_rf 'db/migrations' unless ENV['PAPERCLIP_BUILD']
          end
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
