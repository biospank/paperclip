# encoding: utf-8

module Models
  class DbServer < ActiveRecord::Base
    include Base::Model

    set_table_name :db_server
    
    validates_presence_of :adapter, 
      :message => "Scegliere l'adapter"

    validates_presence_of :host, 
      :message => "specificare l'host in formato ipv4"
    
    validates_presence_of :port, 
      :message => "specificare la porta"
    
    validates_presence_of :username, 
      :message => "inserire lo username"
    
    validates_presence_of :password, 
      :message => "inserire la password"
    
    validates_presence_of :encoding, 
      :message => "scegliere l'encoding (es. 'utf-8')"
    
  end
end