class AddLogo < ActiveRecord::Migration
  def self.up
    add_column :dati_azienda, :logo, :string, :null => true
  end

  def self.down

  end
end
