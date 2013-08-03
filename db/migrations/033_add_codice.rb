require 'app/models/banca'
require 'app/models/causale'
require 'app/models/tipo_pagamento'
require 'app/models/ritenuta'
require 'app/models/aliquota'

class AddCodice < ActiveRecord::Migration
  def self.up
    add_column :banche, :codice, :string, :null => false, :limit => 4, :default => ''
    add_column :causali, :codice, :string, :null => false, :limit => 4, :default => ''
    add_column :tipi_pagamento, :codice, :string, :null => false, :limit => 4, :default => ''
    
    Models::Banca.find(:all, :order => 'descrizione').each_with_index do |item, idx|
      item.codice = sprintf("%03d", (idx + 1))
      item.save!
    end

    Models::Causale.find(:all, :order => 'descrizione').each_with_index do |item, idx|
      item.codice = sprintf("%03d", (idx + 1))
      item.save!
    end

    Models::TipoPagamentoCliente.find(:all, :conditions => "categoria_id = 1", :order => 'descrizione').each_with_index do |item, idx|
      item.codice = sprintf("%03d", (idx + 1))
      item.save!
    end

    Models::TipoPagamentoFornitore.find(:all, :conditions => "categoria_id = 2", :order => 'descrizione').each_with_index do |item, idx|
      item.codice = sprintf("%03d", (idx + 1))
      item.save!
    end

    Models::Ritenuta.find(:all, :order => 'descrizione').each_with_index do |item, idx|
      item.codice = sprintf("%03d", (idx + 1))
      item.save!
    end

    Models::Aliquota.find(:all, :order => 'descrizione').each_with_index do |item, idx|
      item.codice = sprintf("%03d", (idx + 1))
      item.save!
    end
  end

  def self.down

  end
end
