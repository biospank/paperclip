# encoding: utf-8

module Models
  class DatiAzienda < ActiveRecord::Base
    include Base::Model

   set_table_name :dati_azienda
   belongs_to :azienda
  end
end
