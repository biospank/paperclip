#require 'pry'

azienda = Models::Azienda.create(
  :nome => 'DEMO',
  :attivita_merc => 1 # 1: commercio, 2: servizi
)

Models::DatiAzienda.create(
  :azienda => azienda,
  :denominazione => 'DEMO SRL',
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

conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (1, 1, 'CONTANTI', '', 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, '001')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (2, 1, 'ASSEGNO', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, '002')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (3, 1, 'BONIFICO', '', 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, '003')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (4, 1, 'CAMBIALI ATTIVE', '', 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, '004')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (5, 1, 'RI.BA.', '', 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, '005')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (6, 1, 'IN ATTESA', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, '006')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (7, 2, 'CONTANTI', '', 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, '001')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice)  VALUES (8, 2, 'ASSEGNO', '', 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, '002')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (9, 2, 'BONIFICO', '', 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, '003')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (10, 2, 'CAMBIALI PASSIVE', '', 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, '004')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (11, 2, 'RI.BA.', '', 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, '005')"
conn.execute "INSERT INTO tipi_pagamento (id, categoria_id, descrizione, descrizione_agg, cassa_dare, cassa_avere, banca_dare, banca_avere, fuori_partita_dare, fuori_partita_avere, nc_cassa_dare, nc_cassa_avere, nc_banca_dare, nc_banca_avere, nc_fuori_partita_dare, nc_fuori_partita_avere, attivo, predefinito, codice) VALUES (12, 2, 'IN ATTESA', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, '006')"

# percentuale interessi liquidazioni trimestrali
conn.execute "INSERT INTO interessi_liquidazioni_trimestrali (id, percentuale) VALUES (1, 1)"

# aliquote
conn.execute "INSERT INTO aliquote (codice, percentuale, descrizione) VALUES (22, 22, 'aliquota 22\%')"
conn.execute "INSERT INTO aliquote (codice, percentuale, descrizione) VALUES (10, 10, 'aliquota 10%')"
conn.execute "INSERT INTO aliquote (codice, percentuale, descrizione) VALUES (4, 4, 'aliquota 4%')"

# categorie_pdc, pdc
conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (1, 100, 'CREDITI VS.SOCI X VERSAMENTI', 'Attivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 1, 10000, 'CREDITI VS. SOCI RICHIAMATI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 1, 10001, 'CREDITI V/SOCI C/SOTTOSCR.')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (2, 129, 'IMMOBILIZZAZIONI IMMATERIALI', 'Attivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 2, 12901, 'AVVIAMENTO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 2, 13200, 'SOFTWARE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 2, 13201, 'ALTRI ONERI PLURIENNALI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (3, 150, 'IMMOBILIZZAZIONI MATERIALI', 'Attivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15005, 'TERRENI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15200, 'FABBRICATI CIVILI STRUM.')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15400, 'MACCHINARI IMPIANTI SPECIFICI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15430, 'MACCH. E IMPIANTI GENERICI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15431, 'CONDIZIONATORI E DEUMIDIFICAT.')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15432, 'IMPIANTO DI ALLARME')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15433, 'MACCH. APP. E ATTR. VARIE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15600, 'ATTREZZATURA VARIA E MINUTA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15602, 'BENI IN NOLEGGIO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15610, 'STIGLIATURA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15701, 'MOTOCICLI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15710, 'MOBILI E MACCHINE UFFICIO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15712, 'MOBILI E ARREDI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15713, 'IMPIANTI SPECIFICI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15720, 'MACCHINE UFFICIO ELETTRONICHE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15721, 'REGISTRATORE DI CASSA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15740, 'BENI INFERIORI A E.516,46')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15761, 'IMPIANTO TELEFONICO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15770, 'AUTOMEZZI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (4, 160, 'IMMOBILIZZAZIONI FINANZIARIE', 'Attivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 4, 15005, 'TITOLI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (5, 200, 'ATT. CIRC.: RIMANENZE', 'Attivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 5, 20015, 'RIMANENZA MATERIALE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 5, 20021, 'FATTURE DA EMETTERE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 5, 20400, 'RIM.PRODOTTI IN CORSO DI LAV.')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 5, 20600, 'RIMANENZE FINALI MERCI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (6, 293, 'ATT.CIRC.: CREDITI', 'Attivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29300, 'RIT. ACC.TO 4%')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29301, 'CAMBIALI ATTIVE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29499, 'SOCI C/PRELEVAMENTO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29502, 'TITOLARE C/PRELEV.')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29503, 'EFFETTI IN PORTAFOGLIO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29505, 'ERARIO C/RIT.ATTIVE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29515, 'RIT. FISCALE DA BANCHE E PT')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29534, 'ERARIO C/ACC.TO IRAP')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29535, 'ERARIO C/IRAP DA COMPENSARE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29543, 'ERARIO C/ACC.IMPOSTA SOST.1712')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29544, 'ERARIO C/ACC.TO INAIL')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29547, 'ERARIO C/ACC.TO IRES DA COMP.')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29596, 'ERARIO C/ACC.TO IRES')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 30000, 'IVA C/ERARIO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 30001, 'IVA C/ERARIO IN SOSPESO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 30002, 'IVA C/ERARIO DETR.A FINE ANNO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 30005, 'ERARIO C/IVA DA COMPENSARE')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (7, 330, 'ATT.CIRC.: DISPONIBILITA'' LIQ.', 'Attivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 7, 33000, 'C/C.BANCARI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 7, 33001, 'BANCA MPS')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 7, 34100, 'CASSA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 7, 34105, 'CASSA - ASSEGNI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (8, 350, 'RATEI E RISCONTI ATTIVI', 'Attivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 8, 35000, 'RATEI ATTIVI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 8, 35200, 'RISCONTI ATTIVI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (9, 360, 'PATRIMONIO', 'Passivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 9, 36000, 'CAPITALE SOCIALE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 9, 36100, 'RISERVA LEGALE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 9, 36950, 'UTILE D''ESERCIZIO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 9, 36970, 'PERDITA D''ESERCIZIO')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (10, 453, 'DEBITI VS.ALTRI FINANZIATORI', 'Passivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 10, 45310, 'FINANZIAMENTO SOCI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 10, 45311, 'SOCI C/VERSAMENTO INFRUTTIFERO')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (11, 495, 'DEBITI TRIBUTARI', 'Passivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49505, 'ERARIO C/RIT.FISC.1001 DIP.TE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49507, 'ERARIO C/RIT. FISC. 1040')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49508, 'ERARIO C/RIT. FISC. 1012')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49510, 'DEBITI TRIBUTARI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49514, 'ERARIO C/RIT. FISC. 1038')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49519, 'RIT. INPS SU COMPENSI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49525, 'RIT.ADDIZ.COMUNALE IRPEF')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49527, 'RIT.IRPEF PER COMPENSI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49529, 'RITENUTA INAIL')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49600, 'DEBITI VS.INPS')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49603, 'DEBITI VS. INAIL')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49630, 'DEBITI C/LIQUIDAZIONI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (12, 498, 'ALTRI DEBITI', 'Passivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49800, 'DEBITI PER SALARI E STIPENDI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49801, 'CAMBIALI PASSIVE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49803, 'DEBITI VARI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49804, 'FATTURE DA RICEVERE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49850, 'CLIENTI C/ANTICIPI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49851, 'CREDITORI DIVERSI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49855, 'SOCI C/VERSAMENTO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49861, 'DEBITI PER COMPENSI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (13, 500, 'RATEI E RISCONTI PASSIVI', 'Passivo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 13, 50000, 'RATEI PASSIVI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 13, 50100, 'RISCONTI PASSIVI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (14, 515, 'MERCI C/VENDITA - PRESTAZIONI', 'Ricavo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 51600, 'MERCI C/VENDITE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 51601, 'FATTURAZIONI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 56042, 'SOMMINISTRAZIONE ALIM.BEVANDE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 51618, 'PRESTAZIONI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 51619, 'FATTURAZIONI A CONDOMINI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 52120, 'RIMANENZE FINALI MERCI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 52201, 'RIMANENZE MATERIALE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 52403, 'RIMBORSO SPESE DA CLIENTI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (15, 541, 'MERCI C/ACQUISTI', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54100, 'MERCI C/ACQUISTI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54103, 'LAVORI DI TERZI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54111, 'MATERIALI C/ACQUISTI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54131, 'LAVORI DI TERZI E MERCI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54140, 'IMBALLAGGI C/ACQUISTI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54141, 'CANCELLERIA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54142, 'CARBURANTI E LUBRIFICANTI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54143, 'MATERIALE DI PULIZIE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54144, 'MATER. ACCESS. VENDITA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54150, 'SCONTI ABBUONI RIBASSI PASSIVI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54154, 'CARB. E LUBRIF. USO PROM.')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (16, 550, 'COSTI PER SERVIZI', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55005, 'PRESTAZIONI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55008, 'SPESE COMMISSIONI BANCARIE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55009, 'SPESE INCASSO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55010, 'FORZA MOTRICE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55011, 'SPESE CONDOMINIALI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55014, 'MANUTENZIONE E RIPARAZIONE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55016, 'CANONI DI ASSISTENZA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55017, 'SPESE ASSICURAZIONI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55018, 'SPESE PUBBLICITA''')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55019, 'TRASPORTI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55020, 'POSTALI E TELEGRAFICHE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55021, 'SPESE TELEFONICHE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55024, 'PARCHEGGIO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55025, 'PRESTAZIONI PROFESSIONALI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55028, 'CONSULENZA SOFTWARE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55035, 'SPESE ISTRUTTORIE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55036, 'SPESE VIGILANZA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55037, 'LAVORI DI PULIZIA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55042, 'SPESE ALLESTIMENTO VETRINA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55049, 'OMAGGI E REGALIE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55058, 'SPESE ANTICIPATE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55059, 'SPESE PER RECUPERO CREDITI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55099, 'SPESE LEGALI NOTARILI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55141, 'ABITI DA LAVORO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55143, 'AGGIORNAMENTI PROGR. COMPUTER')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55144, 'AGGIORNAMENTI PROFESSIONALI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55145, 'VIAGGI E TRASFERTE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55548, 'ACQUA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55550, 'GESTIONE AUTOMEZZI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55553, 'GESTIONE AUTOM.USO PROMISCUO')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55555, 'RAPPRESENTANZA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55556, 'SMALTIMENTO RIFIUTI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55562, 'COLLABORAZIONI OCCASIONALI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55572, 'SPESE ALBERGHI E RISTORANTI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (17, 560, 'COSTI PER IL GODIMENTO DI BENI', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 17, 56000, 'NOLEGGI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 17, 56001, 'NOLEGGIO MACCHINARI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 17, 56002, 'AFFITTI PASSIVI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 17, 56005, 'CANONE LEASING 100%')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 17, 56011, 'NOLEGGIO AUTO')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (18, 561, 'COSTI PERSONALE', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 18, 56100, 'SALARI E STIPENDI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 18, 56102, 'DIARIE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 18, 56104, 'INDENNITA'' FINE RAPPORTO')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (19, 562, 'ONERI CONTRIBUTIVI', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 19, 56200, 'CONTRIBUTI INPS')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 19, 56201, 'CONTRIBUTI INAIL')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 19, 56208, 'C.A.P. 2%')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 19, 56212, 'CONTRIBUTI INPS PER COLLABOR.')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (20, 563, 'ALTRI COSTI', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 20, 56308, 'BENI STRUMENTALI < 516,46')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 20, 56309, 'COSTI NON DI COMP.DELL''ESERC.')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 20, 56339, 'GAS')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (21, 565, 'AMMORTAMENTI E SVALUTAZ.IMMOB.', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 21, 56501, 'AMM. ORDINARI BENI MATERIALI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 21, 56501, 'AMM. ORDINARI BENI IMMATERIALI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (22, 567, 'ESISTENZE INIZIALI', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 22, 56701, 'ESISTENZE INIZ. MERCI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 22, 56703, 'ESIS.INIZ.PROD.IN CORSO DI LAV')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 22, 56708, 'ESISTENZE INIZ. MATERIALE')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (23, 568, 'ACCANTONAMENTO PER RISCHI', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 23, 56801, 'FONDO IMPOSTE E TASSE')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (24, 569, 'ALTRI ACCANTONAMENTI', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 24, 56900, 'ACC.TO INDENNITA'' ANZIANITA''')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 24, 56903, 'ACC.TO INDENNITA'' FINE MANDATO')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (25, 570, 'ONERI DIVERSI DI GESTIONE', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57003, 'SPESE VARIE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57006, 'SPESE ALLESTIMENTO VETRINE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57007, 'SERVIZI VARI LEGGE 626')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57010, 'ELABORAZIONE DATI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57011, 'ABBONAMENTI RIVISTE E GIORNALI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57012, 'SPESE DI PULIZIE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57017, 'SPESE DOCUMENTATE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57018, 'EROGAZIONI LIBERALI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57029, 'I.M.U.')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 63000, 'COMPENSI A PROFESSIONISTI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 63001, 'COMPENSI AMMINISTRATORI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 63004, 'COMPENSI PER COLLABORAZIONE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 63020, 'VALORI BOLLATI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 63030, 'SPESE BOLLI E TRATTE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 64000, 'IMPOSTE E TASSE DEDUCIBILI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 64001, 'DIRITTI CAMERALI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 64020, 'IMPOSTE E TASSE INDEDUCIBILI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 64056, 'COSTI NON DEDUCIBILI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 64062, 'SANZIONE PECUNIARIA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 65004, 'RICAVI NON DI COMPETENZA')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 65012, 'ARROTONDAMENTI ATTIVI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (26, 650, 'PROVENTI DA PARTECIPAZIONI', 'Ricavo')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (27, 654, 'ALTRI PROVENTI FINANZIARI', 'Ricavo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 27, 65400, 'INTER.ATTIVI C/C BANCARI E PT')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (28, 700, 'ONERI FINANZIARI E BANCARI', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 28, 70005, 'ARROTONDAMENTI PASSIVI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 28, 70500, 'SPESE E ONERI BANCARI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 28, 70501, 'INTER.PASSIVI C/C BANCARI E PT')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 28, 70503, 'INTERESSI PASSIVI FINANZIARI')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 28, 70504, 'INTER.PASS.SU DEBITI DIVERSI')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (29, 750, 'PROVENTI STRAORDINARI', 'Ricavo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 29, 75001, 'SOPRAVVENIENZE ATTIVE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 29, 75002, 'PLUSVAL. ALIENAZIONE')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (30, 800, 'ONERI STRAORDINARI', 'Costo')")

conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 30, 80001, 'SOPRAVVENIENZE PASSIVE')")
conn.execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 30, 82507, 'ACCANTONAMENTO IRAP')")

conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (31, 220, 'CLIENTI', 'Attivo')")
conn.execute("insert into categorie_pdc (id, codice, descrizione, type) values (32, 460, 'FORNITORI', 'Passivo')")

# inizializzo i progressivi utilizzati nei conti (clienti e fornitori)
conn.execute("insert into progressivo_clienti (progressivo) values (22000)")
conn.execute("insert into progressivo_fornitori (progressivo) values (46000)")

# norma
conn.execute("insert into norma (id, codice, percentuale, descrizione) values (NULL, 20, 20, 'Acq. con Iva Indetraibile 20%')")
conn.execute("insert into norma (id, codice, percentuale, descrizione) values (NULL, 40, 40, 'Acq. con Iva Indetraibile 40%')")
conn.execute("insert into norma (id, codice, percentuale, descrizione) values (NULL, 50, 50, 'Acq. con Iva Indetraibile 50%')")
conn.execute("insert into norma (id, codice, percentuale, descrizione) values (NULL, 80, 80, 'Acq. con Iva Indetraibile 80%')")
conn.execute("insert into norma (id, codice, percentuale, descrizione) values (NULL, 100, 100, 'Acq. con Iva Indetraibile 100%')")

# pdc associati agli incassi impostati da sistema

contanti = Models::TipoPagamento.find(:first,
  :conditions => ["categoria_id = 1 and descrizione = 'CONTANTI'"])
contanti.pdc_dare = Models::Pdc.find_by_codice(34100)
contanti.nc_pdc_avere = Models::Pdc.find_by_codice(34100)
contanti.save_with_validation(false)

assegno = Models::TipoPagamento.find(:first,
  :conditions => ["categoria_id = 1 and descrizione = 'ASSEGNO'"])
assegno.pdc_dare = Models::Pdc.find_by_codice(34105)
assegno.nc_pdc_avere = Models::Pdc.find_by_codice(33001)
assegno.save_with_validation(false)

bonifico = Models::TipoPagamento.find(:first,
  :conditions => ["categoria_id = 1 and descrizione = 'BONIFICO'"])
bonifico.pdc_dare = Models::Pdc.find_by_codice(33001)
bonifico.nc_pdc_avere = Models::Pdc.find_by_codice(33001)
bonifico.save_with_validation(false)

cambiali = Models::TipoPagamento.find(:first,
  :conditions => "categoria_id = 1 and descrizione like 'CAMBIALI%'",
  :order => 'id'
)
cambiali.pdc_dare = Models::Pdc.find_by_codice(33001)
cambiali.pdc_avere = Models::Pdc.find_by_codice(29301)
cambiali.nc_pdc_dare = Models::Pdc.find_by_codice(49801)
cambiali.nc_pdc_avere = Models::Pdc.find_by_codice(33001)
cambiali.save_with_validation(false)

riba = Models::TipoPagamento.find(:first,
  :conditions => ["categoria_id = 1 and descrizione = 'RI.BA.'"])
riba.pdc_dare = Models::Pdc.find_by_codice(33001)
riba.nc_pdc_avere = Models::Pdc.find_by_codice(33001)
riba.save_with_validation(false)

# pdc associati ai pagamenti impostati da sistema

contanti = Models::TipoPagamento.find(:first,
  :conditions => ["categoria_id = 2 and descrizione = 'CONTANTI'"])
contanti.pdc_avere = Models::Pdc.find_by_codice(34100)
contanti.nc_pdc_dare = Models::Pdc.find_by_codice(34100)
contanti.save_with_validation(false)

assegno = Models::TipoPagamento.find(:first,
  :conditions => ["categoria_id = 2 and descrizione = 'ASSEGNO'"])
assegno.pdc_avere = Models::Pdc.find_by_codice(33001)
assegno.nc_pdc_dare = Models::Pdc.find_by_codice(34105)
assegno.save_with_validation(false)

bonifico = Models::TipoPagamento.find(:first,
  :conditions => ["categoria_id = 2 and descrizione = 'BONIFICO'"])
bonifico.pdc_avere = Models::Pdc.find_by_codice(33001)
bonifico.nc_pdc_dare = Models::Pdc.find_by_codice(33001)
bonifico.save_with_validation(false)

cambiali = Models::TipoPagamento.find(:first,
  :conditions => "categoria_id = 2 and descrizione like 'CAMBIALI%'",
  :order => 'id'
)
cambiali.pdc_dare = Models::Pdc.find_by_codice(49801)
cambiali.pdc_avere = Models::Pdc.find_by_codice(33001)
cambiali.nc_pdc_dare = Models::Pdc.find_by_codice(33001)
cambiali.nc_pdc_avere = Models::Pdc.find_by_codice(29301)
cambiali.save_with_validation(false)

riba = Models::TipoPagamento.find(:first,
  :conditions => ["categoria_id = 2 and descrizione = 'RI.BA.'"])
riba.pdc_avere = Models::Pdc.find_by_codice(33001)
riba.nc_pdc_dare = Models::Pdc.find_by_codice(33001)
riba.save_with_validation(false)

# per ogni azienda creo un magazzino di default
Models::Azienda.all.each do |az|
  conn.execute "insert into magazzini (id, azienda_id, nome, descrizione, attivo, predefinito) values (null, #{az.id}, 'Default', '', 1, 1)"
end

# profilo utente
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


