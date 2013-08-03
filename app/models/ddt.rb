# encoding: utf-8

require 'app/models/base'

module Models
  class Ddt < ActiveRecord::Base
    include Base::Model

    set_table_name :ddt
    belongs_to :cliente, :foreign_key => 'cliente_id', :polymorphic => true
    belongs_to :azienda
    has_many :righe_ddt, :class_name => 'Models::RigaDdt', :foreign_key => 'ddt_id', :dependent => :delete_all, :order => 'righe_ddt.id'
  
    validates_presence_of :data_emissione, 
      :message => "Data inesistente o formalmente errata."

    validates_presence_of :num, 
      :message => "Inserire il numero del documento di trasporto"

    def before_validation_on_create
      self.azienda = Azienda.current
    end

    protected
    
    def ricerca_precedente_o_successivo(num)
      self.class.search(:first, :conditions => ["num = ? and #{to_sql_year('data_emissione')} = ?", num.to_s, data_emissione.year.to_s])
    end
  
    def numero_duplicato?
      self.class.search(:first, :conditions => ["num = ? and #{to_sql_year('data_emissione')} = ?", num, data_emissione.year.to_s]) != nil
    end
    
    def validate()
      if errors.empty? and self.new_record?
        if numero_duplicato?
          errors.add(:num, "Numero documento di trasporto già utilizzato")
        else
          if num.strip.match(/^[0-9]*$/)
            # controllo tra le note spese precedenti
            # se maggiore di 0
            # -1 cerca il numero ddt precedente (num - 1)
            # -2 se é un numero valido, controlla la data
            # -3 se non é un numero valido, riprendi dal punto 1 al punto 3 
            # per un massimo di volte fino ad arrivare a 0
            numero_ddt = num.strip.to_i
            numero_ddt_prec = (numero_ddt - 1)
            while numero_ddt_prec > 0
              ddt_prec = ricerca_precedente_o_successivo(numero_ddt_prec)
              unless ddt_prec.nil?
                logger.debug("Numero ddt precedente: " + ddt_prec.num)
                logger.debug("Data ddt: " + data_emissione.to_s)
                logger.debug("Data ddt precedente: " + ddt_prec.data_emissione.to_s)
                if data_emissione < ddt_prec.data_emissione
                  errors.add(:num, "La data del documento risulta esere minore della data\ndel documento immediatamente precedente (n. #{ddt_prec.num} del #{ddt_prec.data_emissione.to_s(:italian_date)})")
                end
                break
              else
                numero_ddt_prec -= 1  
              end
            end
            # controllo tra le note spese successive
            # se maggiore di 0
            # -1 cerca il numero ddt successiva (num + 1)
            # -2 se è un numero valido, controlla la data
            # -3 se non è un numero valido, riprendi dal punto 1 al punto 3 
            # per un massimo di volte fino al numero progressivo disponibile
            progressivo_ddt = Models::ProgressivoDdt.next_sequence(data_emissione.year).to_i
            numero_ddt = num.strip.to_i
            numero_ddt_succ = numero_ddt + 1
            while numero_ddt_succ < progressivo_ddt
              ddt_succ = ricerca_precedente_o_successivo(numero_ddt_succ)
              unless ddt_succ.nil?
                logger.debug("Numero ddt successiva: " + ddt_succ.num)
                logger.debug("Data ddt: " + data_emissione.to_s)
                logger.debug("Data ddt successiva: " + ddt_succ.data_emissione.to_s)
                if data_emissione > ddt_succ.data_emissione
                  errors.add(:num, "La data del documento di trasporto risulta esere maggiore della data\ndel documento di trasporto immediatamente successivo (n. #{ddt_succ.num} del #{ddt_succ.data_emissione.to_s(:italian_date)})")
                end
                break
              else
                numero_ddt_succ += 1  
              end
            end
          end
        end
      end        
    end
    
    def after_destroy()
      Models::ProgressivoDdt.remove_sequence(data_emissione.year) if self.class.count(:conditions => ["#{to_sql_year('data_emissione')} = ? and azienda_id = ?", data_emissione.year.to_s, Azienda.current]).zero?
    end

  end
end