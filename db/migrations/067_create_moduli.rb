class CreateModuli < ActiveRecord::Migration
  # tabella che elenca i moduli di paperclip
  def self.up
    create_table :moduli do |t|
      t.string :nome, :null => false, :limit => 50
      t.integer :parent_id
    end

    # i moduli identificano le macro funzionalita
    # è possibile inserire moduli che abilitano una particolare funzione (es. bilancino)
    # ogni nuovo modulo da autorizzare deve essere censito in questa tabella
    execute "INSERT INTO moduli VALUES (10, 'Anagrafica', null)"
    execute "INSERT INTO moduli VALUES (20, 'Fatturazione', null)"
    execute "INSERT INTO moduli VALUES (30, 'Scadenzario', null)"
    execute "INSERT INTO moduli VALUES (40, 'Prima Nota', null)"
    execute "INSERT INTO moduli VALUES (50, 'Magazzino', null)"
    execute "INSERT INTO moduli VALUES (60, 'Configurazione', null)"
    
  end

  def self.down
    drop_table :moduli
  end
end
