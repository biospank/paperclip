# encoding: utf-8

module Models
  class Scrittura < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    set_table_name :prima_nota
    belongs_to :azienda
    belongs_to :causale, :foreign_key => 'causale_id'
    belongs_to :banca, :foreign_key => 'banca_id'
    belongs_to :pdc_dare, :class_name => "Models::Pdc", :foreign_key => 'pdc_dare_id'
    belongs_to :pdc_avere, :class_name => "Models::Pdc", :foreign_key => 'pdc_avere_id'
    has_many :pagamenti_prima_nota, :class_name => "Models::PagamentoPrimaNota", :foreign_key => "prima_nota_id", :dependent => :delete_all
    has_many :corrispettivi_prima_nota, :class_name => "Models::CorrispettivoPrimaNota", :foreign_key => "prima_nota_id", :dependent => :delete_all
    belongs_to :parent, :foreign_key => 'parent_id', :class_name => "Models::Scrittura"
    has_one :storno, :foreign_key => 'parent_id', :class_name => "Models::Scrittura"
    has_one    :pagamento_fattura_cliente, :through => :pagamenti_prima_nota
    has_one    :pagamento_fattura_fornitore, :through => :pagamenti_prima_nota
    has_one    :maxi_pagamento_cliente, :through => :pagamenti_prima_nota
    has_one    :maxi_pagamento_fornitore, :through => :pagamenti_prima_nota
    has_many   :prima_nota_partita_doppia, :class_name => 'Models::PrimaNotaPartitaDoppia', :foreign_key => 'prima_nota_id', :dependent => :destroy
    has_many    :scrittura_pd, :through => :prima_nota_partita_doppia

    before_save :nullify_zeros

    validates_presence_of :data_operazione,
      :message => "Data inesistente o formalmente errata."

    validates_presence_of :descrizione,
      :message => "Inserire la descrizione."

    validates_presence_of :importo,
      :if => Proc.new { |scrittura|
        configatron.bilancio.attivo
      },
      :message => "Inserire l'importo."

    # pdc_dare è obbligatorio se è attivo il bilancio
    validates_presence_of :pdc_dare,
      :if => Proc.new { |scrittura|
        configatron.bilancio.attivo
      },
      :message => "Inserire il conto in dare oppure premere F5 per la ricerca."

    # pdc_avere è obbligatorio se è attivo il bilancio
    validates_presence_of :pdc_avere,
      :if => Proc.new { |scrittura|
        configatron.bilancio.attivo
      },
      :message => "Inserire il conto in avere oppure premere F5 per la ricerca."

    def before_validation_on_create
      self.azienda = Azienda.current
      self.data_registrazione = Time.now
    end

    def causale_compatibile?()
      res = true
      # se esiste una banca e una causale
      if(self.banca and self.causale)
        # che non prevede un movimento di banca
        if(self.causale.banca_dare == 0 and self.causale.banca_avere == 0)
          res = false
        end
      end
      return res
    end

    def importo_compatibile?
      res = true
      # se la scrittura ha una banca associata
      if self.banca
        # ma non e' una scrittura di banca
        if !self.di_banca?
          res = false
        end
      # se la scrittura non ha una banca associata
      else
        # ma e' una scrittura di banca
        if self.di_banca?
          res = false
        end
      end

      return res
    end

    def con_importo_valido?
      if configatron.bilancio.attivo
        self.importo.zero? ? false : true
      else
        if self.cassa_dare.zero? and self.cassa_avere.zero? and
            self.banca_dare.zero? and self.banca_avere.zero? and
            self.fuori_partita_dare.zero? and self.fuori_partita_avere.zero?
          false
        else
          true
        end
      end
    end

    def di_banca?
      if self.banca_dare > 0 or self.banca_avere > 0
        true
      else
        false
      end

    end

    def con_importi_differenti?
      res = false

      importi_dare = []
      importi_avere = []

      if self.causale
        importi_dare << cassa_dare if causale.cassa_dare?
        importi_avere << cassa_avere if causale.cassa_avere?
        importi_dare << banca_dare if causale.banca_dare?
        importi_avere << banca_avere if causale.banca_avere?
        importi_dare << fuori_partita_dare if causale.fuori_partita_dare?
        importi_avere << fuori_partita_avere if causale.fuori_partita_avere?
      else
        importi_dare = [cassa_dare,
                         banca_dare,
                         fuori_partita_dare,
        ].select() {|importo| importo > 0 }
        importi_avere = [cassa_avere,
                          banca_avere,
                          fuori_partita_avere
        ].select() {|importo| importo > 0 }
      end

      if (not importi_dare.empty?) and (not importi_avere.empty?)
        importo_dare = importi_dare.first()
        res = importi_avere.any? {|importo_avere| importo_avere != importo_dare}
      end

      res
    end

    def stornata?
      (storno ? true : false)
    end

    def di_storno?
      (parent_id ? true : false)
    end

    def nullify_zeros
      self.importo = nil if self.importo && self.importo.zero?
      self.cassa_dare = nil if self.cassa_dare && self.cassa_dare.zero?
      self.cassa_avere = nil if self.cassa_avere && self.cassa_avere.zero?
      self.banca_dare = nil if self.banca_dare && self.banca_dare.zero?
      self.banca_avere = nil if self.banca_avere && self.banca_avere.zero?
      self.fuori_partita_dare = nil if self.fuori_partita_dare && self.fuori_partita_dare.zero?
      self.fuori_partita_avere = nil if self.fuori_partita_avere && self.fuori_partita_avere.zero?
    end

    def post_datata?
      return (self.data_operazione and self.data_operazione > Date.today)
    end

    # override per gestire gli storni
    # evita la cancellazione in cascata se la scrittura è congelata
    def destroy()
      super unless self.congelata?
    end
#    protected
#
#    def validate()
#      if errors.empty?
#        if configatron.bilancio.attivo
#          # pdc_dare è obbligatorio se fuori_partita_dare è valorizzato
#          if self.fuori_partita_dare > 0 && self.pdc_dare.nil?
#            errors.add(:pdc_dare, "Un movimento di fuori partita in dare neccessita di un movimento pdc in dare.\nInserire il codice pdc in dare.")
#          end
#          # pdc_avere è obbligatorio se fuori_partita_avere è valorizzato
#          if self.fuori_partita_avere > 0 && self.pdc_avere.nil?
#            errors.add(:pdc_avere, "Un movimento di fuori partita in avere neccessita di un movimento pdc in avere.\nInserire il codice pdc in avere.")
#          end
#          # se sono valorizzati fuori_partita_dare e fuori_partita_avere,
#          # pdc_dare e pdc_avere non possono essere due conti economici
#          if self.fuori_partita_dare > 0 &&
#              self.fuori_partita_avere > 0 &&
#              self.pdc_dare && self.pdc_avere &&
#              self.pdc_dare.conto_economico? &&
#              self.pdc_avere.conto_economico?
#            errors.add(:pdc_dare, "Sono stati valorizzati fuori partita dare e avere.\nIn questo caso il pdc non può essere un conto economico sia in dare che in avere. ")
#          end
#        end
#      end
#    end
  end
end
