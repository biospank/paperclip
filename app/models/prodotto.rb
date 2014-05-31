# encoding: utf-8

module Models
  class Prodotto < ActiveRecord::Base
    include Base::Model

    set_table_name :prodotti
    belongs_to :azienda
    has_many :movimenti, :class_name => 'Models::Movimento', :foreign_key => 'prodotto_id', :order => 'created_at desc'
    has_many :carichi, :class_name => 'Models::Carico', :foreign_key => 'prodotto_id', :order => 'created_at desc'
    has_many :scarichi, :class_name => 'Models::Scarico', :foreign_key => 'prodotto_id', :order => 'created_at desc'
    belongs_to :aliquota

    validates_presence_of :codice, :if => Proc.new { |prodotto| prodotto.bar_code.blank? }, :message => "Inserire un codice prodotto oppure il codice a barre"
    validates_presence_of :bar_code, :if => Proc.new { |prodotto| prodotto.codice.blank? }, :message => "Inserire un codice prodotto oppure il codice a barre"
    validates_presence_of :descrizione, :message => "Inserire la descrizione"
    validates_presence_of :aliquota, :message => "Scegliere l'aliquota"
    validates_uniqueness_of :codice,
      :scope => :azienda_id,
      :message => "Codice già utilizzato"
    validates_uniqueness_of :bar_code,
      :scope => :azienda_id,
      :message => "Codice a barre già utilizzato", :if => Proc.new {|prodotto| !prodotto.bar_code.blank? }

    attr_accessor :residuo

    def calcola_imponibile
      if self.aliquota
        self.imponibile = (self.prezzo_vendita * 100 / (self.aliquota.percentuale + 100))
      else
        self.imponibile = self.prezzo_vendita
      end
    end

    def calcola_totale
      if self.aliquota
        self.prezzo_vendita = (self.imponibile + (self.imponibile * self.aliquota.percentuale / 100))
      else
        self.prezzo_vendita = self.imponibile
      end
    end

    def residuo?
      self.residuo > 0
    end

    def calcola_residuo(*args)
      opts = args.extract_options!

      qta_caricate = self.carichi.sum(:qta, :conditions => ["magazzino_id = ? and data <= ?", opts[:magazzino], (opts[:al] || Date.today)])
      qta_scaricate = self.scarichi.sum(:qta, :conditions => ["magazzino_id = ? and data <= ?", opts[:magazzino], (opts[:al] || Date.today)])

      self.residuo = (qta_caricate - qta_scaricate)
    end

    def before_create
      self.azienda = Azienda.current
    end

    def modificabile?
      num = Models::RigaOrdine.count(:conditions => ["prodotto_id = ?", self.id])
      num += Models::Carico.count(:conditions => ["prodotto_id = ?", self.id])
      num += Models::Scarico.count(:conditions => ["prodotto_id = ?", self.id])
      num == 0
    end

  end
end
