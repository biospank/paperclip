class CreateDbServer < ActiveRecord::Migration
  def self.up
    create_table :db_server do |t|
      t.string :adapter, :limit => 100
      t.string :host, :limit => 100
      t.integer :port
      t.string :username, :limit => 50
      t.string :password, :limit => 50
      t.string :database, :limit => 50
      t.string :encoding, :limit => 20
    end

  end


  def self.down
    drop_table :db_server
  end
end

