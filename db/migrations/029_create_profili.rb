class CreateProfili < ActiveRecord::Migration
  def self.up
    create_table :profili do |t|
      t.string  :descrizione, :limit => 100
    end

    execute "INSERT INTO PROFILI VALUES(1, 'Admin')"
    execute "INSERT INTO PROFILI VALUES(2, 'User')"
    execute "INSERT INTO PROFILI VALUES(3, 'Guest')"

  end

  def self.down
    drop_table :profili
  end
end
