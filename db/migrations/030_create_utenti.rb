class CreateUtenti < ActiveRecord::Migration
  def self.up
    create_table :utenti do |t|
      t.integer :profilo_id, :null => false
      t.string  :nominativo, :limit => 100
      t.string  :login, :limit => 50
      t.string  :password, :limit => 50
    end

    execute "INSERT INTO UTENTI VALUES(1, 1, 'Administrator', 'admin', '8743342106303a9cb104d2484a6fcbf516d2f8be')"
    execute "INSERT INTO UTENTI VALUES(2, 1, 'Administrator', 'bratech', '8743342106303a9cb104d2484a6fcbf516d2f8be')"

  end

  def self.down
    drop_table :utenti
  end
end
