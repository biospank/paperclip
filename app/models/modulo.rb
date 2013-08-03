# encoding: utf-8

module Models
  class Modulo < ActiveRecord::Base
    include Base::Model

    set_table_name :moduli

    belongs_to :parent, :class_name => 'Models::Modulo', :foreign_key => 'parent_id'

  end
end