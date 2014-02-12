class AddContoClientiFornitori < ActiveRecord::Migration
  def self.up
    add_column :clienti, :conto, :integer
    add_column :fornitori, :conto, :integer

    Models::Azienda.all.each do |azienda|
      Models::Cliente.find(:all, :conditions => ["azienda_id = ?", azienda]).each do |cliente|
        cliente.update_attribute(:conto, Models::ProgressivoCliente.next_sequence(azienda))
      end

      Models::Fornitore.find(:all, :conditions => ["azienda_id = ?", azienda]).each do |fornitore|
        fornitore.update_attribute(:conto, Models::ProgressivoFornitore.next_sequence(azienda))
      end
    end

  end

  def self.down
    remove_column :clienti, :conto
    remove_column :fornitori, :conto
  end
end
