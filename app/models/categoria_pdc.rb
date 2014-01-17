# encoding: utf-8

module Models
  class CategoriaPdc < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    set_table_name :categorie_pdc

    validates_presence_of :codice,
      :message => "Inserire il codice"

    validates_presence_of :descrizione,
      :message => "Inserire la descrizione"

    validates_uniqueness_of :codice,
      :message => "Codice catagoria gia' utilizzato."

    def modificabile?
      num = 0
      unless self.id.nil?
        num += Models::Pdc.count(:conditions => ["categoria_pdc_id = ?", self.id])
      end
      num == 0
    end

  end
end