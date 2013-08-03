require 'log4r'
require 'yaml'
require 'activerecord'
require 'app/models/fattura_cliente'
require 'app/models/fattura_cliente_fatturazione'
require 'app/models/riga_fattura_cliente'
require 'app/models/aliquota'
require 'app/helpers/number_helper'
require 'sqlite3'

class CalcolaImponibileIvaFattureClienti
  include Helpers::NumberHelper
	include Models

  @log = nil
  @conf = nil
  
  def initialize()
    # load configuration file
    #loadConfig()
    
    # initilize log
    #initializeLog()
    
    # database connection
    setUpDatabaseConnection()

  end
  
  def execute()
    FatturaClienteFatturazione.find(:all).each do |fattura|
      totale_imponibile = 0.0
      totale_iva = 0.0
      fattura.righe_fattura_cliente.each do |riga|
        if riga.importo_iva?
          totale_iva += riga.importo
        else
          importo = (riga.qta.zero?) ? riga.importo : (riga.importo * riga.qta)
          totale_imponibile += importo
          totale_iva += ((importo * riga.aliquota.percentuale) / 100)
        end
      end
      
      fattura.imponibile = eval(number_with_precision(totale_imponibile, precision=2))
      fattura.iva = eval(number_with_precision(totale_iva, precision=2))
      fattura.save!
    end
    
  end

  def setUpDatabaseConnection
    ActiveRecord::Base.establish_connection(
      :adapter => "sqlite3",
      #:database => "db/development/bpn.db"
      :database => "db/development/bra.db"
    )
  end

  def loadConfig()
    begin
      @conf = YAML::load(File.open(File.join('conf', 'bpnfx.yml')))
      #puts @conf.to_yaml
    rescue
      raise RuntimeError, "Can't read file: #{File.join('conf', 'bpnfx.yml')}"
    end
  end

  def initializeLog
    # create a logger named 'mylog' that logs to stdout
    @log = Log4r::Logger.new 'bpnlog'
    #bpnOut = Log4r::FileOutputter.new('bpnout', {:filename => 'log/bpn.log'})
    #bpnLog.add(bpnOut)
    @log.outputters = Log4r::Outputter.stdout#, bpnOut
    @log.level = eval(@conf["log"]["level"])
    #@log.level = Log4r::ERROR
    ActiveRecord::Base.logger = Log4r::Logger['bpnlog']
  end
  
end
 
calcola = CalcolaImponibileIvaFattureClienti.new

calcola.execute()
