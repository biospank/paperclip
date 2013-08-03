# encoding: utf-8

module Models
  class RigaNotaSpeseServizi < RigaNotaSpese
    validates_numericality_of :importo,
      :if => Proc.new { |riga| riga.importo_iva?},
      :greater_than => 0,
      :message => "L'importo deve essere maggiore di 0"

    def before_validation_on_create()
      self.qta ||= 0
    end
  end
end