# encoding: utf-8

module Models
  class ProgressivoFornitore < ActiveRecord::Base
    include Base::Model

    set_table_name :progressivo_fornitori

    def self.next_sequence(azienda = nil)
      pgr = self.find(:first, :conditions => ["azienda_id = ?", (azienda || Models::Azienda.current)])
      pgr.increment!(:progressivo)
      pgr.progressivo
    end

  end
end