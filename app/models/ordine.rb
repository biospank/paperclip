# encoding: utf-8

module Models
  class Ordine < ActiveRecord::Base
    include Base::Model

    set_table_name :ordini
    belongs_to :azienda
    belongs_to :fornitore
    has_many :righe_ordine, :class_name => 'Models::RigaOrdine', :foreign_key => 'ordine_id', :dependent => :delete_all, :order => 'righe_ordini.id'

    # stati dell'ordine
    APERTO = 'A'
    EVASO = 'E'
    CHIUSO = 'C'

    validates_presence_of(:fornitore, :message => "Scegliere un fornitore")
    validates_presence_of(:num, :message => "Inserire il numero d'ordine")

    validates_presence_of :data_emissione, 
      :message => "Data inesistente o formalmente errata."

    def before_create
      self.azienda = Azienda.current
    end

    def caricato_in_magazzino?
      righe_ordine.any? { |riga| riga.caricata? }
    end

    protected

    def before_save
      if self.stato.eql? CHIUSO
        self.data_chiusura = Date.today
      else
        self.data_chiusura = nil
      end
    end
  end
end