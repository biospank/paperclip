require 'app/helpers/number_helper'
class AddImponibileIvaNs < ActiveRecord::Migration
  extend Helpers::NumberHelper
  
  def self.up
    add_column :nota_spese, :imponibile, :decimal, :null => false, :default => 0
    add_column :nota_spese, :iva, :decimal, :null => false, :default => 0

    Models::NotaSpese.find(:all).each do |ns|
      totale_imponibile = 0.0
      totale_iva = 0.0
      ns.righe_nota_spese.each do |riga|
        if riga.importo_iva?
          totale_iva += riga.importo
        else
          importo = (riga.qta.zero?) ? riga.importo : (riga.importo * riga.qta)
          totale_imponibile += importo
          totale_iva += ((importo * riga.aliquota.percentuale) / 100)
        end
      end

      ns.imponibile = eval(number_with_precision(totale_imponibile, 2))
      ns.iva = eval(number_with_precision(totale_iva, 2))
      ns.save!
    end

  end

  def self.down

  end
end
