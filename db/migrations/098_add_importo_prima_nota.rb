class AddImportoPrimaNota < ActiveRecord::Migration
  def self.up
    add_column :prima_nota, :importo, :decimal
  end

  def self.down
    remove_column :prima_nota, :importo
  end
end
