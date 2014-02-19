class AddContoClientiFornitori < ActiveRecord::Migration
  def self.up
    add_column :categorie_pdc, :standard, :integer, :limit => 1, :null => false, :default => 0
    add_column :pdc, :standard, :integer, :limit => 1, :null => false, :default => 0
    add_column :pdc, :hidden, :integer, :limit => 1, :null => false, :default => 0
    add_column :clienti, :conto, :integer
    add_column :fornitori, :conto, :integer

    Models::Cliente.find(:all).each do |cliente|
      seq = Models::ProgressivoCliente.next_sequence()
      cat_pdc = Models::CategoriaPdc.find(:first, :conditions => ["codice = ?", 220])
      Models::Pdc.create(
        :categoria_pdc => cat_pdc,
        :codice => seq,
        :descrizione => cliente.denominazione,
        :attivo => true,
        :standard => true,
        :hidden => true
      )
      cliente.update_attribute(:conto, seq)
    end

    Models::Fornitore.find(:all).each do |fornitore|
      seq = Models::ProgressivoFornitore.next_sequence()
      cat_pdc = Models::CategoriaPdc.find(:first, :conditions => ["codice = ?", 460])
      Models::Pdc.create(
        :categoria_pdc => cat_pdc,
        :codice => seq,
        :descrizione => fornitore.denominazione,
        :attivo => true,
        :standard => true,
        :hidden => true
      )
      fornitore.update_attribute(:conto, seq)
    end

    execute("update categorie_pdc set standard = 1")

    execute("update pdc set standard = 1")

  end

  def self.down
    remove_column :clienti, :conto
    remove_column :fornitori, :conto
    remove_column :pdc, :hidden
    remove_column :pdc, :standard
    remove_column :categorie_pdc, :standard
  end
end
