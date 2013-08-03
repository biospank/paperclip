# encoding: utf-8

module Models
  class Scarico < Movimento

    belongs_to :riga_fattura, :class_name => 'Models::RigaFatturaCliente', :foreign_key => 'riga_fattura_id'

    protected

    def validate
      if(qta_non_valida?)
        errors.add(:qta, "Quantità deve essere maggiore di 0")
      end
      if(qta_eccedente?)
        errors.add(:qta, "La quantità scaricata non puo' essere maggiore della disponibilità")
      end
    end

  end
end