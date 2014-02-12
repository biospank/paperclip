# encoding: utf-8

module Models
  class Corrispettivo < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    set_table_name :corrispettivi

    attr_accessor :anno, :mese, :giorno, :descrizione_pdc
    
    belongs_to :azienda, :foreign_key => 'azienda_id'
    belongs_to :aliquota, :foreign_key => 'aliquota_id'
    belongs_to :pdc_dare, :class_name => "Models::Pdc", :foreign_key => 'pdc_dare_id'
    belongs_to :pdc_avere, :class_name => "Models::Pdc", :foreign_key => 'pdc_avere_id'
    has_one    :corrispettivo_prima_nota, :class_name => 'Models::CorrispettivoPrimaNota', :foreign_key => 'corrispettivo_id'
    has_one    :scrittura, :through => :corrispettivo_prima_nota

    validates_presence_of :giorno,
      :message => "Inserire il giorno"

    validates_presence_of :importo,
      :message => "Inserire l'importo"

    validates_numericality_of :importo,
      :greater_than => 0,
      :message => "L'importo deve essere maggiore di 0"

    validates_presence_of :aliquota,
      :message => "Scegliere l'aliquota"

    validates_presence_of :pdc_dare,
      :if => Proc.new { |corrispettivo| configatron.bilancio.attivo },
      :message => "Inserire il codice pdc in dare oppure premere F5 per la ricerca."

    validates_presence_of :pdc_avere,
      :if => Proc.new { |corrispettivo| configatron.bilancio.attivo },
      :message => "Inserire il codice pdc in avere oppure premere F5 per la ricerca."

    # virtual attribute
    def giorno()
      if date = read_attribute(:data)
        self.anno = date.year
        self.mese = date.month
        date.day
      else
        nil
      end
    end
    
    def giorno=(day)
      write_attribute(:data, (Date.new(self.anno.to_i, self.mese.to_i, day.to_i) rescue nil))
    end

    def before_create
      self.azienda = Azienda.current
    end

    def calcola_imponibile
#      self.imponibile = (self.importo * 100 / (self.aliquota.percentuale + 100))
      self.imponibile = (self.importo - self.iva)
    end

    def calcola_iva
      self.iva = Helpers::ApplicationHelper.real((self.importo * self.aliquota.percentuale) / (self.aliquota.percentuale + 100))
      #self.iva = (self.imponibile * self.aliquota.percentuale / 100)
    end

    def congelato?
      return (scrittura and scrittura.congelata?)
    end

    protected

    def validate()
      if errors.empty?
        if self.data.future?
          errors.add(:giorno, "La data indicata è maggiore della data odierna.")
        end
      end
    end
  end
end