# encoding: utf-8

module Models
  class FatturaClienteFatturazione < FatturaCliente

    has_many :righe_fattura_cliente, :class_name => 'Models::RigaFatturaCliente', :foreign_key => 'fattura_cliente_id', :dependent => :destroy, :order => 'righe_fatture_clienti.id'

    def before_validation_on_create
      self.azienda = Azienda.current
      self.da_fatturazione = true
    end

    def con_destinatario?
      return (!self.destinatario.blank? ||
              !self.indirizzo_dest.blank? ||
              !self.cap_dest.blank? ||
              !self.citta_dest.blank?)
    end
    
#    def check_progressivo!
#      while self.class.count(:conditions => ["num = ? and #{to_sql_year('data_emissione')} = ? and nota_di_credito = 0 and azienda_id = ?", self.num, self.data_emissione.year.to_s, Azienda.Current]) > 0
#        self.num = ((self.num.to_i) + 1).to_s
#      end
#    end

    protected
    
    def ricerca_precedente_o_successivo(num)
      if self.nota_di_credito?
        self.class.search(:first, :conditions => ["num = ? and #{to_sql_year('data_emissione')} = ? and nota_di_credito = 1", num.to_s, data_emissione.year.to_s])
      else
        self.class.search(:first, :conditions => ["num = ? and #{to_sql_year('data_emissione')} = ? and nota_di_credito = 0", num.to_s, data_emissione.year.to_s])
      end
    end

    def validate()
      if errors.empty? and self.new_record?
        if numero_duplicato?
          errors.add(:num, "Numero fattura o nota di credito già utilizzato.")
        else
          if num.strip.match(/^[0-9]*$/)
            # controllo tra le note spese precedenti
            # se maggiore di 0
            # -1 cerca il numero fattura precedente (num - 1)
            # -2 se é un numero valido, controlla la data
            # -3 se non é un numero valido, riprendi dal punto 1 al punto 3 
            # per un massimo di volte fino ad arrivare a 0
            numero_fattura = num.strip.to_i
            numero_fattura_prec = (numero_fattura - 1)
            while numero_fattura_prec > 0
              fattura_prec = ricerca_precedente_o_successivo(numero_fattura_prec)
              unless fattura_prec.nil?
                logger.debug("Numero fattura precedente: " + fattura_prec.num)
                logger.debug("Data fattura: " + data_emissione.to_s)
                logger.debug("Data fattura precedente: " + fattura_prec.data_emissione.to_s)
                if data_emissione < fattura_prec.data_emissione
                  errors.add(:num, "La data di fattura o nota di credito risulta esere minore della data\ndi fattura o nota di credito immediatamente precedente (n. #{fattura_prec.num} del #{fattura_prec.data_emissione.to_s(:italian_date)}).")
                end
                break
              else
                numero_fattura_prec -= 1  
              end
            end
            # controllo tra le note spese successive
            # se maggiore di 0
            # -1 cerca il numero fattura successiva (num + 1)
            # -2 se è un numero valido, controlla la data
            # -3 se non è un numero valido, riprendi dal punto 1 al punto 3 
            # per un massimo di volte fino al numero progressivo disponibile
            progressivo_fattura = (self.nota_di_credito? ? Models::ProgressivoNc.next_sequence(data_emissione.year) : Models::ProgressivoFatturaCliente.next_sequence(data_emissione.year)).to_i
            numero_fattura = num.strip.to_i
            numero_fattura_succ = numero_fattura + 1
            while numero_fattura_succ < progressivo_fattura
              fattura_succ = ricerca_precedente_o_successivo(numero_fattura_succ)
              unless fattura_succ.nil?
                logger.debug("Numero fattura successiva: " + fattura_succ.num)
                logger.debug("Data fattura: " + data_emissione.to_s)
                logger.debug("Data fattura successiva: " + fattura_succ.data_emissione.to_s)
                if data_emissione > fattura_succ.data_emissione
                  errors.add(:num, "La data di fattura o nota di credito risulta esere maggiore della data\ndi fattura o nota di credito immediatamente successiva (n. #{fattura_succ.num} del #{fattura_succ.data_emissione.to_s(:italian_date)}).")
                end
                break
              else
                numero_fattura_succ += 1  
              end
            end
          end
        end
      end        
    end
    
    def after_destroy()
      if self.nota_di_credito?
        Models::ProgressivoNc.remove_sequence(data_emissione.year) if self.class.count(:conditions => ["#{to_sql_year('data_emissione')} = ? and nota_di_credito = 1 and azienda_id = ?", data_emissione.year.to_s, Azienda.current]).zero?
      else
        Models::ProgressivoFatturaCliente.remove_sequence(data_emissione.year) if self.class.count(:conditions => ["#{to_sql_year('data_emissione')} = ? and nota_di_credito = 0 and azienda_id = ?", data_emissione.year.to_s, Azienda.current]).zero?
      end
    end
  end
end