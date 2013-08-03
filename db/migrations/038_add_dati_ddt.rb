class AddDatiDdt < ActiveRecord::Migration
  def self.up
    add_column :ddt, :aspetto_beni, :string, :null => true
    add_column :ddt, :num_colli, :integer, :null => true
    add_column :ddt, :peso, :decimal, :null => true
    add_column :ddt, :porto, :string, :null => true
  end

  def self.down

  end
end
