class CreatePermessi < ActiveRecord::Migration
  # tabella dei permessi
  # l'utente amministratore e system hanno permessi di 
  # lettura/scrittura (non necessitano di permessi) su tutti i moduli di tutte le aziende configurate
  #
  # Oni utente creato, vede solo l'azienda per cui è stato configurato e i permessi a lui associati
  # Per abilitare lo stesso utente su piu aziende, e' necessario crearlo su tutte le aziende a cui accede
  #
  # La gestione dei permessi viene fatta da interfaccia
  def self.up
    create_table :permessi do |t|
      t.integer :utente_id, :null => false
      t.integer :modulo_azienda_id, :null => false
      t.integer :lettura, :null => false, :limit => 1, :default => 1
      t.integer :scrittura, :null => false, :limit => 1, :default => 1
    end

  end


  def self.down
    drop_table :permessi
  end
end
