# encoding: utf-8

module Models
  class Profilo < ActiveRecord::Base
    include Base::Model

    set_table_name :profili

    SYSTEM = 0
    ADMIN = 1
    USER = 2
    GUEST = 3
  end
end