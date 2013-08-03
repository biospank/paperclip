class PortingV2 < ActiveRecord::Migration
  def self.up
    2.upto(31) { |i| execute "insert into schema_migrations values (#{i})" }
    
    execute "drop index PAGAMENTI_PRIMA_NOTA_IDX"
    execute "CREATE INDEX PAGAMENTI_PRIMA_NOTA_IDX1 ON PAGAMENTI_PRIMA_NOTA (prima_nota_id)"
    execute "CREATE INDEX PAGAMENTI_PRIMA_NOTA_IDX2 ON PAGAMENTI_PRIMA_NOTA (pagamento_fattura_cliente_id)"
    execute "CREATE INDEX PAGAMENTI_PRIMA_NOTA_IDX3 ON PAGAMENTI_PRIMA_NOTA (pagamento_fattura_fornitore_id)"
    
    execute "update utenti set password = '8743342106303a9cb104d2484a6fcbf516d2f8be' where id = 1"
    execute "INSERT INTO UTENTI VALUES(2, 1, 'Administrator', 'bratech', '8743342106303a9cb104d2484a6fcbf516d2f8be')"
    execute "update licenza set versione = '2.0'"
  end

  def self.down
    drop_table :schema_migrations
  end
end
