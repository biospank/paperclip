# encoding: utf-8

module Models
  class RigaOrdine < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    set_table_name :righe_ordini
    belongs_to :ordine
    belongs_to :prodotto
    has_one :carico

    validates_presence_of(:prodotto, :message => "Inserire il codice/barcode del prodotto")

    validates_numericality_of :qta,
      :greater_than => 0,
      :message => "La quantità deve essere maggiore di 0"

    def caricata?
      return false if self.new_record?
      Carico.count(:conditions => ["riga_ordine_id = ?", id]) > 0
    end
    
    def before_validation_on_create()
      self.qta ||= 0
    end
  end
end