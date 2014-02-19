# encoding: utf-8

module Models
  class ProgressivoCliente < ActiveRecord::Base
    include Base::Model

    set_table_name :progressivo_clienti
  
    def self.next_sequence()
      pgr = self.first
      pgr.increment!(:progressivo)
      pgr.progressivo
    end

  end
end