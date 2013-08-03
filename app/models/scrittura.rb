# encoding: utf-8

module Models
  class Scrittura < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    set_table_name :prima_nota
    belongs_to :azienda
    belongs_to :causale, :foreign_key => 'causale_id'
    belongs_to :banca, :foreign_key => 'banca_id'
    has_many :pagamenti_prima_nota, :class_name => "Models::PagamentoPrimaNota", :foreign_key => "prima_nota_id", :dependent => :delete_all
    belongs_to :parent, :foreign_key => 'parent_id', :class_name => "Models::Scrittura"
    has_one :storno, :foreign_key => 'parent_id', :class_name => "Models::Scrittura"
    has_one    :pagamento_fattura_cliente, :through => :pagamenti_prima_nota
    has_one    :pagamento_fattura_fornitore, :through => :pagamenti_prima_nota
    has_one    :maxi_pagamento_cliente, :through => :pagamenti_prima_nota
    has_one    :maxi_pagamento_fornitore, :through => :pagamenti_prima_nota
    
    before_save :nullify_zeros
    
    validates_presence_of :data_operazione, 
      :message => "Data inesistente o formalmente errata."

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione."

    def before_validation_on_create
      self.azienda = Azienda.current
      self.data_registrazione = Time.now
    end

    def causale_compatibile?()
      res = true
      if(self.banca and self.causale)
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
      if self.cassa_dare.zero? and self.cassa_avere.zero? and
          self.banca_dare.zero? and self.banca_avere.zero? and
          self.fuori_partita_dare.zero? and self.fuori_partita_avere.zero?
        false
      else
        true
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
  end
    
end
