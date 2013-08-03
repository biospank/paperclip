azienda = Models::Azienda.create(
  :nome => 'Nautica Casilina S.r.l.',
  :attivita_merc => 1 # 1: commercio, 2: servizi
)

Models::DatiAzienda.create(
  :azienda => azienda,
  :denominazione => 'Nautica Casilina S.r.l.',
  :p_iva => '1234567890',
  :cod_fisc => '1234567890',
  :indirizzo => '',
  :cap => '',
  :citta => ''
)

['CLIENTI', 'FORNITORI'].each do |cat|
  Models::Categoria.create(
    :descrizione => cat
  )
end

{
  10 => ['Anagrafica', 1],
  20 => ['Fatturazione', 1],
  30 => ['Scadenzario', 1],
  40 => ['Prima Nota', 1],
  50 => ['Magazzino', 1],
  60 => ['Configurazione', 1]
}.each do |key, value|
  modulo = Models::Modulo.new(
    :nome => value[0]
  )
  modulo.id = key
  modulo.save!
  # per ogni azienda abilito i moduli di default
  [azienda].each do |az|
    Models::ModuloAzienda.create(
      :azienda_id => az.id,
      :modulo_id => modulo.id,
      :attivo => value[1]
    )
  end
end

conn = ActiveRecord::Base.connection

conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (1, 1, 'CONTANTI', '', 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, '001')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (2, 1, 'ASSEGNO', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, '002')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (3, 1, 'BONIFICO', '', 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, '003')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (4, 1, 'CAMBIALI', '', 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, '004')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (5, 1, 'RI.BA.', '', 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, '005')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (6, 1, 'IN ATTESA', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, '006')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (7, 2, 'CONTANTI', '', 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, '001')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice)  VALUES (8, 2, 'ASSEGNO', '', 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, '002')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (9, 2, 'BONIFICO', '', 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, '003')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (10, 2, 'CAMBIALI', '', 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, '004')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (11, 2, 'RI.BA.', '', 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, '005')"
conn.execute "INSERT INTO TIPI_PAGAMENTO (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (12, 2, 'IN ATTESA', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, '006')"

['Admin', 'User', 'Guest'].each do |profilo|
  Models::Profilo.create(
    :descrizione => profilo
  )
end

# utente admin e di sistema valgono per tutte le aziende
{
  1 => ['admin', '8743342106303a9cb104d2484a6fcbf516d2f8be'], 
  2 => ['bratech', '8743342106303a9cb104d2484a6fcbf516d2f8be']
}.each do |key, value|
  conn.execute "INSERT INTO UTENTI (id, profilo_id, azienda_id, nominativo, login, password) VALUES (#{key}, 1, 1, 'Administrator', '#{value[0]}', '#{value[1]}')"
end

Models::Licenza.create(
  :numero_seriale => '',
  :data_scadenza => Date.today.months_since(4),
  :versione => '2.4.0'
)

