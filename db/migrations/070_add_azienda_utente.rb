class AddAziendaUtente < ActiveRecord::Migration
  # modifica alla tabella utenti per collegare l'azienda di appartenenza
  # ogni utente appariene ad una sola azienda
  # admin e system vedono tutte le aziende
  def self.up
    add_column :utenti, :azienda_id, :integer, :null => false, :default => 1

  end

  def self.down

  end
end
