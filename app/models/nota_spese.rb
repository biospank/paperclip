# encoding: utf-8

module Models
  class NotaSpese < ActiveRecord::Base
    include Base::Model
    
    INTESTAZIONE = {
      1 => 'Nota spese',
      2 => 'Avviso fattura',
      3 => 'Avviso parcella'
    } unless const_defined? 'INTESTAZIONE'

    INTESTAZIONE_PLURALE = {
      1 => 'Note spese',
      2 => 'Avvisi fattura',
      3 => 'Avvisi parcella'
    } unless const_defined? 'INTESTAZIONE_PLURALE'

    set_table_name :nota_spese

    belongs_to :cliente, :foreign_key => 'cliente_id'
    belongs_to :azienda
    belongs_to :ritenuta, :foreign_key => 'ritenuta_id'
    belongs_to :fattura_cliente, :foreign_key => 'fattura_cliente_id'
    has_many :righe_nota_spese, :class_name => 'Models::RigaNotaSpese', :foreign_key => 'nota_spese_id', :dependent => :delete_all, :order => 'righe_nota_spese.id'

    validates_presence_of :data_emissione, 
      :message => "Data inesistente o formalmente errata."

    validates_presence_of :num, 
      :message => "Inserire il numero di #{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]}"

    def before_validation_on_create
      self.azienda = Azienda.current
    end

    def fatturata?
      return !self.fattura_cliente.nil?
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
          errors.add(:num, "Numero #{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]} già utilizzato")
        else
          if num.strip.match(/^[0-9]*$/)
            # controllo tra le note spese precedenti
            # se maggiore di 0
            # -1 cerca il numero nota_spese precedente (num - 1)
            # -2 se é un numero valido, controlla la data
            # -3 se non é un numero valido, riprendi dal punto 1 al punto 3 
            # per un massimo di volte fino ad arrivare a 0
            numero_nota_spese = num.strip.to_i
            numero_nota_spese_prec = (numero_nota_spese - 1)
            while numero_nota_spese_prec > 0
              nota_spese_prec = ricerca_precedente_o_successivo(numero_nota_spese_prec)
              unless nota_spese_prec.nil?
                logger.debug("Numero nota spese precedente: " + nota_spese_prec.num)
                logger.debug("Data nota spese: " + data_emissione.to_s)
                logger.debug("Data nota spese precedente: " + nota_spese_prec.data_emissione.to_s)
                if data_emissione < nota_spese_prec.data_emissione
                  errors.add(:num, "La data di #{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]} risulta esere minore della data\ndi #{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]} immediatamente precedente (n. #{nota_spese_prec.num} del #{nota_spese_prec.data_emissione.to_s(:italian_date)})")
                end
                break
              else
                numero_nota_spese_prec -= 1  
              end
            end
            # controllo tra le note spese successive
            # se maggiore di 0
            # -1 cerca il numero nota_spese successiva (num + 1)
            # -2 se è un numero valido, controlla la data
            # -3 se non è un numero valido, riprendi dal punto 1 al punto 3 
            # per un massimo di volte fino al numero progressivo disponibile
            progressivo_nota_spese = Models::ProgressivoNotaSpese.next_sequence(data_emissione.year).to_i
            numero_nota_spese = num.strip.to_i
            numero_nota_spese_succ = numero_nota_spese + 1
            while numero_nota_spese_succ < progressivo_nota_spese
              nota_spese_succ = ricerca_precedente_o_successivo(numero_nota_spese_succ)
              unless nota_spese_succ.nil?
                logger.debug("Numero nota spese successiva: " + nota_spese_succ.num)
                logger.debug("Data nota spese: " + data_emissione.to_s)
                logger.debug("Data nota spese successiva: " + nota_spese_succ.data_emissione.to_s)
                if data_emissione > nota_spese_succ.data_emissione
                  errors.add(:num, "La data di #{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]} risulta esere maggiore della data\ndi #{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]} immediatamente successiva (n. #{nota_spese_succ.num} del #{nota_spese_succ.data_emissione.to_s(:italian_date)})")
                end
                break
              else
                numero_nota_spese_succ += 1  
              end
            end
          end
        end
      end        
    end
    
    def after_destroy()
      Models::ProgressivoNotaSpese.remove_sequence(data_emissione.year) if self.class.count(:conditions => ["#{to_sql_year('data_emissione')} = ? and azienda_id = ?", data_emissione.year.to_s, Azienda.current]).zero?
    end

  end
end
