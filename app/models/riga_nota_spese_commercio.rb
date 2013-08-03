# encoding: utf-8

module Models
  class RigaNotaSpeseCommercio < RigaNotaSpese
    validates_numericality_of :importo,
      :if => Proc.new { |riga| riga.importo_iva? or riga.qta > 0},
      :greater_than => 0,
      :message => "L'importo deve essere maggiore di 0"
    
  end

end