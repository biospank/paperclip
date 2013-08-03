require 'app/helpers/number_helper'
class ManageImponibileIva < ActiveRecord::Migration
  extend Helpers::NumberHelper
  
  def self.up

    Models::NotaSpese.find(:all).each do |ns|
      if ns.imponibile.nil? or
          ns.imponibile.zero? or
          ns.iva.nil? or
          ns.iva.zero?

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

    Models::FatturaClienteFatturazione.find(:all).each do |fattura|
      if fattura.imponibile.nil? or
          fattura.imponibile.zero? or
          fattura.iva.nil? or
          fattura.iva.zero?

        totale_imponibile = 0.0
        totale_iva = 0.0
        fattura.righe_fattura_cliente.each do |riga|
          if riga.importo_iva?
            totale_iva += riga.importo
          else
            importo = (riga.qta.zero?) ? riga.importo : (riga.importo * riga.qta)
            totale_imponibile += importo
            totale_iva += ((importo * riga.aliquota.percentuale) / 100)
          end
        end

        fattura.imponibile = eval(number_with_precision(totale_imponibile, 2))
        fattura.iva = eval(number_with_precision(totale_iva, 2))
        fattura.save!

      end
    end

  end

  def self.down

  end
end
