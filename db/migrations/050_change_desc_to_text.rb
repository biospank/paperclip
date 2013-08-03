class ChangeDescToText < ActiveRecord::Migration
  def self.up
    
    change_column :prima_nota, :descrizione, :text, :limit => nil, :null => false

  end

  def self.down

  end
end
