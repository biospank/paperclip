class CreateModuliAzienda < ActiveRecord::Migration
  # tabella che abilita i moduli per una determinata azienda (plugin)
  # inserire qui i moduli associati ad un'azienda ed abilitarli (attivo)
  def self.up
    create_table :moduli_azienda do |t|
      t.integer :azienda_id, :null => false
      t.integer :modulo_id, :null => false
      t.integer :attivo, :null => false, :limit => 1, :default => 1
    end

    # per ogni azienda vengono abilitati i moduli di default
    # e quelli aggiuntivi (es. magazzino)
    Models::Azienda.find(:all).each do |azienda|
      execute "INSERT INTO moduli_azienda (azienda_id, modulo_id, attivo) VALUES (#{azienda.id}, 10, 1)"
      execute "INSERT INTO moduli_azienda (azienda_id, modulo_id, attivo) VALUES (#{azienda.id}, 20, 1)"
      execute "INSERT INTO moduli_azienda (azienda_id, modulo_id, attivo) VALUES (#{azienda.id}, 30, 1)"
      execute "INSERT INTO moduli_azienda (azienda_id, modulo_id, attivo) VALUES (#{azienda.id}, 40, 1)"
      if azienda.nome =~ /p\. g\. costruzioni|giva/i
        execute "INSERT INTO moduli_azienda (azienda_id, modulo_id, attivo) VALUES (#{azienda.id}, 50, 1)"
      else
        execute "INSERT INTO moduli_azienda (azienda_id, modulo_id, attivo) VALUES (#{azienda.id}, 50, 0)"
      end
      execute "INSERT INTO moduli_azienda (azienda_id, modulo_id, attivo) VALUES (#{azienda.id}, 60, 1)"
    end
    
  end

  def self.down
    drop_table :moduli_azienda
  end
end
