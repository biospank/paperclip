# encoding: utf-8

require 'app/models/base'

module Models
  class Causale < ActiveRecord::Base
    include Base::Model

    set_table_name :causali

    belongs_to :banca, :foreign_key => 'banca_id'
    belongs_to :pdc_dare, :class_name => "Models::Pdc", :foreign_key => 'pdc_dare_id'
    belongs_to :pdc_avere, :class_name => "Models::Pdc", :foreign_key => 'pdc_avere_id'

    before_save do |causale| 
      Causale.update_all('predefinita = 0') if causale.predefinita? 
    end
    
    validates_presence_of :codice, 
      :message => "Inserire il codice"

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

    validates_uniqueness_of :codice, 
      :message => "Codice causale gia' utilizzato."

    # pdc_dare è obbligatorio se è attivo il bilancio
    validates_presence_of :pdc_dare,
      :if => Proc.new { |causale|
        configatron.bilancio.attivo
      },
      :message => "Inserire il conto in dare oppure premere F5 per la ricerca."

    # pdc_avere è obbligatorio se è attivo il bilancio
    validates_presence_of :pdc_avere,
      :if => Proc.new { |causale|
        configatron.bilancio.attivo
      },
      :message => "Inserire il conto in avere oppure premere F5 per la ricerca."

    def modificabile?
      num = 0
      num = Models::Scrittura.count(:conditions => ["causale_id = ?", self.id]) unless self.id.nil?
      num == 0
    end

    def movimento_di_banca?()
      return banca_dare? || banca_avere?
    end
    
    protected
    
    def validate()
      if configatron.bilancio.attivo
        # se è stata abilitata la banca in dare o in avere
        if self.banca_dare? || self.banca_avere?
          # e non esiste almeno un conto con la banca
          if((self.pdc_dare.blank? || self.pdc_dare.banca.blank?) &&
            (self.pdc_avere.blank? || self.pdc_avere.banca.blank?))
            errors.add(:pdc_dare, "Le opzioni banca prevedono almeno un conto con la banca associata.\nPremere F5 per selezionare un conto con la banca oppure associare la banca a un conto\nnel pannello 'prima nota -> piano dei conti -> gestione conti'.")
          end
        end
      else
        if(self.banca and self.banca_dare == 0 and self.banca_avere == 0)
          errors.add(:banca, "Le opzioni non sono compatibili con la banca selezionata.")
        end
      end
#      if configatron.bilancio.attivo
#        # pdc_dare è obbligatorio se fuori_partita_dare è valorizzato
#        if self.fuori_partita_dare? && !self.pdc_dare
#          errors.add(:pdc_dare, "Un movimento di fuori partita in dare neccessita di un movimento pdc in dare.\nInserire il codice pdc in dare.")
#        end
#        # pdc_avere è obbligatorio se fuori_partita_avere è valorizzato
#        if self.fuori_partita_avere? && !self.pdc_avere
#          errors.add(:pdc_avere, "Un movimento di fuori partita in avere neccessita di un movimento pdc in avere.\nInserire il codice pdc in avere.")
#        end
#        # se sono valorizzati fuori_partita_dare e fuori_partita_avere,
#        # pdc_dare e pdc_avere non possono essere due conti economici
#        if self.fuori_partita_dare? &&
#            self.fuori_partita_avere? &&
#            self.pdc_dare && self.pdc_avere &&
#            self.pdc_dare.conto_economico? &&
#            self.pdc_avere.conto_economico?
#          errors.add(:pdc_dare, "Sono stati valorizzati fuori partita dare e avere.\nIn questo caso il pdc non può essere un conto economico sia in dare che in avere. ")
#        end
#      end
    end
    
  end
end