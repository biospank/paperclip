# encoding: utf-8

require 'uri'

module Models
  class Licenza < ActiveRecord::Base
    include Base::Model

    set_table_name :licenza
  
    def scaduta?
      !attiva?
    end
    
    def attiva?
      if configatron.env = 'production'
        (self.get_data_scadenza >= Date.today)
      else
        true
      end
    end
    
    def get_data_scadenza(reload=false)
      if reload
        codice_scadenza = self.numero_seriale.split('-').last
        @data = Time.at(URI.unescape(codice_scadenza).unpack('m').join.to_i).to_date
      else
        @data ||= begin
          if self.numero_seriale
            codice_scadenza = self.numero_seriale.split('-').last
            Time.at(URI.unescape(codice_scadenza).unpack('m').join.to_i).to_date
          else
            Date.yesterday
          end
        rescue
          Date.yesterday
        end
      end
    end
  end  
end