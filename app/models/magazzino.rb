# encoding: utf-8

module Models
  class Magazzino < ActiveRecord::Base
    include Base::Model

    set_table_name :magazzini

    belongs_to :azienda
    has_many :movimenti, :class_name => 'Models::Movimento', :foreign_key => 'magazzino_id', :order => 'created_at desc'

    validates_presence_of :nome, :message => "Inserire un nome per il magazzino"

    before_save do |magazzino|
      self.update_all('predefinito = 0') if magazzino.predefinito?
    end

    def before_validation_on_create
      self.azienda = Azienda.current
    end

    def modificabile?
      num = Models::Movimento.count(:conditions => ["magazzino_id = ?", self.id])
      num == 0
    end

  end
end
