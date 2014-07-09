# encoding: utf-8

module Models
  class Licenza < ActiveRecord::Base
    include Base::Model

    set_table_name :licenza
  
    def scaduta?
      !attiva?
    end
    
    def attiva?
      if configatron.env = 'production'
        return (self.get_data_scadenza >= Date.today)
      else
        true
      end
    end
    
    def get_data_scadenza
      @data ||= begin
        if self.numero_seriale
          Time.at(self.numero_seriale.split('-').map {|chunk| [chunk].pack('H*')}.last.to_i).to_date
        else
          self.data_scadenza || Date.today
        end
      end
    end
  end  
end