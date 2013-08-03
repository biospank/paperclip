# encoding: utf-8

module Models
  class Categoria < ActiveRecord::Base
    include Base::Model
    
    set_table_name :categorie

  end
end