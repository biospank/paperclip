class AddImponibile < ActiveRecord::Migration
  def self.up
    add_column :prodotti, :imponibile, :decimal, :null => false, :default => 0.0
    add_column :movimenti, :imponibile, :decimal, :null => false, :default => 0.0

    Models::Carico.find(:all, :order => 'id').each do |carico|
      if carico.prodotto.aliquota
        carico.prezzo_vendita = (carico.prezzo_vendita + (carico.prezzo_vendita * carico.prodotto.aliquota.percentuale / 100))
        carico.imponibile = (carico.prezzo_vendita * 100 / (carico.prodotto.aliquota.percentuale + 100))
      else
        carico.imponibile = carico.prezzo_vendita
      end
      prodotto = Models::Prodotto.find(carico.prodotto_id)
      prodotto.imponibile = carico.imponibile
      prodotto.prezzo_vendita = carico.prezzo_vendita
      carico.save_with_validation(false)
      prodotto.save_with_validation(false)
    end

  end

  def self.down
    remove_column :prodotti, :imponibile
    remove_column :movimenti, :imponibile
  end
end
