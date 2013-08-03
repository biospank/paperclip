require 'app/models/ddt'

class AddClienteType < ActiveRecord::Migration
  def self.up
    add_column :ddt, :cliente_type, :string
    
    Models::Ddt.update_all("cliente_type = 'Models::Cliente'")

  end

  def self.down

  end
end
