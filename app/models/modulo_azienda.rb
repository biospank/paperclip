# encoding: utf-8

module Models
  class ModuloAzienda < ActiveRecord::Base
    include Base::Model

    set_table_name :moduli_azienda
    has_many :permessi, :class_name => 'Models::Permesso' , :foreign_key => 'modulo_id', :dependent => :delete_all
    belongs_to :azienda
    belongs_to :modulo

  end
end