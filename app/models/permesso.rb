# encoding: utf-8

module Models
  class Permesso < ActiveRecord::Base
    include Base::Model

    set_table_name :permessi
    belongs_to :utente
    belongs_to :modulo_azienda

  end
end