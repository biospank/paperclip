# encoding: utf-8

module Models
  class Licenza < ActiveRecord::Base
    include Base::Model

    set_table_name :licenza
  
    def scaduta?
      unless self.data_scadenza.nil?
        if self.data_scadenza < Date.today
          return true
        end
      end
    
      return false
    end
  end  
end