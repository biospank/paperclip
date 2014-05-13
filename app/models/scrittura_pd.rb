# encoding: utf-8

module Models
  class ScritturaPd < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    set_table_name :partita_doppia
    belongs_to :azienda
    belongs_to :causale, :foreign_key => 'causale_id'
    belongs_to :pdc_dare, :class_name => "Models::Pdc", :foreign_key => 'pdc_dare_id'
    belongs_to :pdc_avere, :class_name => "Models::Pdc", :foreign_key => 'pdc_avere_id'
    belongs_to :nc_pdc_dare, :class_name => "Models::Pdc", :foreign_key => 'nc_pdc_dare_id'
    belongs_to :nc_pdc_avere, :class_name => "Models::Pdc", :foreign_key => 'nc_pdc_avere_id'
    has_many :pagamenti_partita_doppia, :class_name => "Models::PagamentoPartitaDoppia", :foreign_key => "partita_doppia_id", :dependent => :delete_all
    has_many :corrispettivi_partita_doppia, :class_name => "Models::CorrispettivoPartitaDoppia", :foreign_key => "partita_doppia_id", :dependent => :delete_all
    has_many :dettaglio_fatture_partita_doppia, :class_name => "Models::DettaglioFatturaPartitaDoppia", :foreign_key => "partita_doppia_id"
    belongs_to :parent, :foreign_key => 'parent_id', :class_name => "Models::ScritturaPd"
    has_one :storno, :foreign_key => 'parent_id', :class_name => "Models::ScritturaPd"
    has_one    :dettaglio_fattura, :through => :dettaglio_fattura_partita_doppia
    has_one    :pagamento_fattura_cliente, :through => :pagamenti_partita_doppia
    has_one    :pagamento_fattura_fornitore, :through => :pagamenti_partita_doppia
    has_one    :maxi_pagamento_cliente, :through => :pagamenti_partita_doppia
    has_one    :maxi_pagamento_fornitore, :through => :pagamenti_partita_doppia

    serialize :tipo
    
    validates_presence_of :data_operazione, 
      :message => "Data inesistente o formalmente errata."

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione."

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

    def stornata?
      (storno ? true : false)
    end
    
    def di_storno?
      (parent_id ? true : false)
    end
    
    def post_datata?
      return (self.data_operazione and self.data_operazione > Date.today)
    end

  end
end
