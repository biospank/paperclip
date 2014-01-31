# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 74) do

  create_table "aliquote", :force => true do |t|
    t.string  "codice",       :limit => 50,                 :null => false
    t.decimal "percentuale"
    t.string  "descrizione",  :limit => 100
    t.integer "attiva",                      :default => 1
    t.integer "predefinita",  :limit => 2,   :default => 0, :null => false
    t.integer "lock_version",                :default => 0, :null => false
  end

  create_table "azienda", :force => true do |t|
    t.string  "nome",          :limit => 100
    t.integer "attivita_merc", :limit => 2,   :default => 1
  end

  create_table "banche", :force => true do |t|
    t.integer "azienda_id",                                    :null => false
    t.string  "descrizione",    :limit => 100
    t.string  "conto_corrente", :limit => 50
    t.string  "iban",           :limit => 27
    t.string  "agenzia",        :limit => 100
    t.string  "telefono",       :limit => 50
    t.string  "indirizzo",      :limit => 100
    t.integer "attiva",                        :default => 1
    t.integer "predefinita",    :limit => 2,   :default => 0,  :null => false
    t.string  "codice",         :limit => 4,   :default => "", :null => false
    t.integer "lock_version",                  :default => 0,  :null => false
  end

  create_table "categorie", :force => true do |t|
    t.string "descrizione", :limit => 100
  end

  create_table "causali", :force => true do |t|
    t.string  "descrizione",         :limit => 100
    t.string  "descrizione_agg",     :limit => 200
    t.integer "banca_id"
    t.integer "cassa_dare",                         :default => 0
    t.integer "cassa_avere",                        :default => 0
    t.integer "banca_dare",                         :default => 0
    t.integer "banca_avere",                        :default => 0
    t.integer "fuori_partita_dare",                 :default => 0
    t.integer "fuori_partita_avere",                :default => 0
    t.integer "attiva",                             :default => 1
    t.integer "predefinita",         :limit => 2,   :default => 0,  :null => false
    t.string  "codice",              :limit => 4,   :default => "", :null => false
    t.integer "lock_version",                       :default => 0,  :null => false
  end

  create_table "clienti", :force => true do |t|
    t.integer "azienda_id",                                  :null => false
    t.string  "denominazione", :limit => 100
    t.integer "no_p_iva",                     :default => 0
    t.string  "p_iva",         :limit => 11
    t.string  "cod_fisc",      :limit => 16
    t.string  "indirizzo",     :limit => 100
    t.string  "comune",        :limit => 50
    t.string  "provincia",     :limit => 2
    t.string  "cap",           :limit => 10
    t.string  "citta",         :limit => 50
    t.string  "telefono",      :limit => 50
    t.string  "cellulare",     :limit => 50
    t.string  "fax",           :limit => 50
    t.string  "e_mail",        :limit => 100
    t.integer "attivo",                       :default => 1
    t.string  "note",          :limit => 300
    t.integer "lock_version",                 :default => 0, :null => false
  end

  create_table "dati_azienda", :force => true do |t|
    t.integer "azienda_id",                                    :null => false
    t.string  "denominazione",   :limit => 100
    t.string  "telefono",        :limit => 50
    t.string  "fax",             :limit => 50
    t.string  "e_mail",          :limit => 100
    t.string  "indirizzo",       :limit => 100
    t.string  "cap",             :limit => 10
    t.string  "citta",           :limit => 50
    t.string  "p_iva",           :limit => 11
    t.string  "cod_fisc",        :limit => 16
    t.decimal "cap_soc"
    t.string  "reg_imprese",     :limit => 100
    t.string  "num_reg_imprese", :limit => 50
    t.string  "num_rea",         :limit => 50
    t.integer "lock_version",                   :default => 0, :null => false
    t.binary  "logo"
    t.string  "logo_tipo",       :limit => 5
    t.string  "iban",            :limit => 27
  end

  create_table "db_server", :force => true do |t|
    t.string  "adapter",  :limit => 100
    t.string  "host",     :limit => 100
    t.integer "port"
    t.string  "username", :limit => 50
    t.string  "password", :limit => 50
    t.string  "database", :limit => 50
    t.string  "encoding", :limit => 20
  end

  create_table "ddt", :force => true do |t|
    t.integer "azienda_id",                                    :null => false
    t.integer "cliente_id",                                    :null => false
    t.string  "num",             :limit => 20,                 :null => false
    t.date    "data_emissione",                                :null => false
    t.string  "mezzo_trasporto", :limit => 100
    t.string  "nome_cess",       :limit => 100
    t.string  "indirizzo_cess",  :limit => 100
    t.string  "cap_cess",        :limit => 10
    t.string  "citta_cess",      :limit => 100
    t.string  "nome_dest",       :limit => 100
    t.string  "indirizzo_dest",  :limit => 100
    t.string  "cap_dest",        :limit => 10
    t.string  "citta_dest",      :limit => 100
    t.string  "causale",         :limit => 100
    t.string  "nome_vett",       :limit => 100
    t.string  "indirizzo_vett",  :limit => 100
    t.string  "cap_vett",        :limit => 10
    t.string  "citta_vett",      :limit => 100
    t.string  "mezzo_vett",      :limit => 100
    t.string  "cliente_type"
    t.string  "aspetto_beni"
    t.integer "num_colli"
    t.decimal "peso"
    t.string  "porto"
    t.integer "lock_version",                   :default => 0, :null => false
  end

  create_table "fatture_clienti", :force => true do |t|
    t.integer "azienda_id",                                    :null => false
    t.integer "cliente_id",                                    :null => false
    t.integer "ritenuta_id"
    t.string  "num",             :limit => 20,                 :null => false
    t.date    "data_emissione",                                :null => false
    t.decimal "imponibile",                                    :null => false
    t.decimal "iva",                                           :null => false
    t.decimal "importo",                                       :null => false
    t.integer "nota_di_credito",                :default => 0
    t.string  "destinatario",    :limit => 100
    t.string  "indirizzo_dest",  :limit => 100
    t.string  "cap_dest",        :limit => 10
    t.string  "citta_dest",      :limit => 100
    t.string  "rif_ddt",         :limit => 100
    t.string  "rif_pagamento",   :limit => 100
    t.integer "da_fatturazione",                :default => 0
    t.integer "da_scadenzario",                 :default => 0
    t.integer "iva_diff",        :limit => 2,   :default => 0, :null => false
    t.integer "lock_version",                   :default => 0, :null => false
  end

  add_index "fatture_clienti", ["cliente_id"], :name => "fc_cliente_fk_idx"
  add_index "fatture_clienti", ["data_emissione"], :name => "fc_data_emissione_idx"
  add_index "fatture_clienti", ["num"], :name => "fc_num_idx"

  create_table "fatture_fornitori", :force => true do |t|
    t.integer "azienda_id",                                   :null => false
    t.integer "fornitore_id",                                 :null => false
    t.string  "num",             :limit => 20,                :null => false
    t.date    "data_emissione",                               :null => false
    t.decimal "importo",                                      :null => false
    t.integer "nota_di_credito",               :default => 0
    t.integer "lock_version",                  :default => 0, :null => false
  end

  add_index "fatture_fornitori", ["data_emissione"], :name => "ff_data_emissione_idx"
  add_index "fatture_fornitori", ["fornitore_id"], :name => "ff_fornitore_fk_idx"
  add_index "fatture_fornitori", ["num"], :name => "ff_num_idx"

  create_table "fornitori", :force => true do |t|
    t.integer "azienda_id",                                  :null => false
    t.string  "denominazione", :limit => 100
    t.integer "no_p_iva",                     :default => 0
    t.string  "p_iva",         :limit => 11
    t.string  "cod_fisc",      :limit => 16
    t.string  "indirizzo",     :limit => 100
    t.string  "comune",        :limit => 50
    t.string  "provincia",     :limit => 2
    t.string  "cap",           :limit => 10
    t.string  "citta",         :limit => 50
    t.string  "telefono",      :limit => 50
    t.string  "cellulare",     :limit => 50
    t.string  "fax",           :limit => 50
    t.string  "e_mail",        :limit => 100
    t.integer "attivo",                       :default => 1
    t.string  "note",          :limit => 300
    t.integer "lock_version",                 :default => 0, :null => false
  end

  create_table "incassi_ricorrenti", :force => true do |t|
    t.integer "cliente_id",                                 :null => false
    t.decimal "importo",                                    :null => false
    t.string  "descrizione",  :limit => 100,                :null => false
    t.integer "attivo",                      :default => 1
    t.integer "lock_version",                :default => 0, :null => false
  end

  create_table "licenza", :force => true do |t|
    t.string "numero_seriale", :limit => 100, :null => false
    t.date   "data_scadenza"
    t.string "versione",       :limit => 20
  end

  create_table "maxi_pagamenti_clienti", :force => true do |t|
    t.integer "azienda_id",                                       :null => false
    t.decimal "importo",                                          :null => false
    t.integer "range_temporale"
    t.integer "tipo_pagamento_id"
    t.integer "banca_id"
    t.date    "data_pagamento",                                   :null => false
    t.date    "data_registrazione",                               :null => false
    t.integer "chiuso",                            :default => 0
    t.string  "note",               :limit => 150
    t.integer "lock_version",                      :default => 0, :null => false
  end

  add_index "maxi_pagamenti_clienti", ["azienda_id"], :name => "mpc_azienda_fk_idx"
  add_index "maxi_pagamenti_clienti", ["banca_id"], :name => "mpc_banca_fk_idx"
  add_index "maxi_pagamenti_clienti", ["data_pagamento"], :name => "mpc_data_pagamento_fk_idx"
  add_index "maxi_pagamenti_clienti", ["data_registrazione"], :name => "mpc_data_registrazione_fk_idx"
  add_index "maxi_pagamenti_clienti", ["tipo_pagamento_id"], :name => "mpc_tipo_pagamento_fk_idx"

  create_table "maxi_pagamenti_fornitori", :force => true do |t|
    t.integer "azienda_id",                                       :null => false
    t.decimal "importo",                                          :null => false
    t.integer "range_temporale"
    t.integer "tipo_pagamento_id"
    t.integer "banca_id"
    t.date    "data_pagamento",                                   :null => false
    t.date    "data_registrazione",                               :null => false
    t.integer "chiuso",                            :default => 0
    t.string  "note",               :limit => 150
    t.integer "lock_version",                      :default => 0, :null => false
  end

  add_index "maxi_pagamenti_fornitori", ["azienda_id"], :name => "mpf_azienda_fk_idx"
  add_index "maxi_pagamenti_fornitori", ["banca_id"], :name => "mpf_banca_fk_idx"
  add_index "maxi_pagamenti_fornitori", ["data_pagamento"], :name => "mpf_data_pagamento_idx"
  add_index "maxi_pagamenti_fornitori", ["data_registrazione"], :name => "mpf_data_registrazione_idx"
  add_index "maxi_pagamenti_fornitori", ["tipo_pagamento_id"], :name => "mpf_tipo_pagamento_fk_idx"

  create_table "moduli", :force => true do |t|
    t.string  "nome",      :limit => 50, :null => false
    t.integer "parent_id"
  end

  create_table "moduli_azienda", :force => true do |t|
    t.integer "azienda_id",                             :null => false
    t.integer "modulo_id",                              :null => false
    t.integer "attivo",     :limit => 2, :default => 1, :null => false
  end

  create_table "movimenti", :force => true do |t|
    t.string   "type"
    t.integer  "prodotto_id",                                     :null => false
    t.integer  "riga_ordine_id"
    t.integer  "riga_fattura_id"
    t.integer  "qta",                                             :null => false
    t.decimal  "prezzo_acquisto"
    t.decimal  "prezzo_vendita"
    t.date     "data",                                            :null => false
    t.string   "note",            :limit => 300
    t.integer  "lock_version",                   :default => 0,   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "imponibile",                     :default => 0.0, :null => false
  end

  add_index "movimenti", ["data"], :name => "m_data_idx"
  add_index "movimenti", ["prodotto_id"], :name => "m_prodotto_fk_idx"
  add_index "movimenti", ["riga_ordine_id"], :name => "m_riga_ordine_fk_idx"

  create_table "nota_spese", :force => true do |t|
    t.integer "azienda_id",                                        :null => false
    t.integer "cliente_id",                                        :null => false
    t.integer "ritenuta_id"
    t.integer "fattura_cliente_id"
    t.string  "num",                :limit => 20,                  :null => false
    t.date    "data_emissione",                                    :null => false
    t.decimal "importo",                                           :null => false
    t.integer "lock_version",                     :default => 0,   :null => false
    t.decimal "imponibile",                       :default => 0.0, :null => false
    t.decimal "iva",                              :default => 0.0, :null => false
  end

  add_index "nota_spese", ["data_emissione"], :name => "ns_data_emissione_idx"
  add_index "nota_spese", ["num"], :name => "ns_num_idx"

  create_table "ordini", :force => true do |t|
    t.integer "azienda_id",                                   :null => false
    t.integer "fornitore_id",                                 :null => false
    t.string  "num",            :limit => 20,                 :null => false
    t.date    "data_emissione",                               :null => false
    t.integer "stato",                         :default => 1
    t.date    "data_chiusura"
    t.string  "note",           :limit => 300
    t.integer "lock_version",                  :default => 0, :null => false
  end

  add_index "ordini", ["azienda_id"], :name => "o_azienda_fk_idx"
  add_index "ordini", ["data_emissione"], :name => "o_data_emissione_idx"
  add_index "ordini", ["fornitore_id"], :name => "o_fornitore_fk_idx"
  add_index "ordini", ["stato"], :name => "o_stato_idx"

  create_table "pagamenti_fatture_clienti", :force => true do |t|
    t.integer "fattura_cliente_id",                                      :null => false
    t.integer "maxi_pagamento_cliente_id"
    t.decimal "importo",                                                 :null => false
    t.integer "range_temporale"
    t.integer "tipo_pagamento_id"
    t.integer "banca_id"
    t.date    "data_pagamento",                                          :null => false
    t.date    "data_registrazione",                                      :null => false
    t.integer "registrato_in_prima_nota"
    t.string  "note",                      :limit => 100
    t.integer "lock_version",                             :default => 0, :null => false
  end

  add_index "pagamenti_fatture_clienti", ["banca_id"], :name => "pfc_banca_fk_idx"
  add_index "pagamenti_fatture_clienti", ["data_pagamento"], :name => "pfc_data_pagamento_fk_idx"
  add_index "pagamenti_fatture_clienti", ["data_registrazione"], :name => "pfc_data_registrazione_fk_idx"
  add_index "pagamenti_fatture_clienti", ["fattura_cliente_id"], :name => "pfc_fattura_cliente_fk_idx"
  add_index "pagamenti_fatture_clienti", ["maxi_pagamento_cliente_id"], :name => "pfc_maxi_pagamento_cliente_fk_idx"
  add_index "pagamenti_fatture_clienti", ["tipo_pagamento_id"], :name => "pfc_tipo_pagamento_fk_idx"

  create_table "pagamenti_fatture_fornitori", :force => true do |t|
    t.integer "fattura_fornitore_id",                                      :null => false
    t.integer "maxi_pagamento_fornitore_id"
    t.decimal "importo",                                                   :null => false
    t.integer "range_temporale"
    t.integer "tipo_pagamento_id"
    t.integer "banca_id"
    t.date    "data_pagamento",                                            :null => false
    t.date    "data_registrazione",                                        :null => false
    t.integer "registrato_in_prima_nota"
    t.string  "note",                        :limit => 100
    t.integer "lock_version",                               :default => 0, :null => false
  end

  add_index "pagamenti_fatture_fornitori", ["banca_id"], :name => "pff_banca_fk_idx"
  add_index "pagamenti_fatture_fornitori", ["data_pagamento"], :name => "pff_data_pagamento_fk_idx"
  add_index "pagamenti_fatture_fornitori", ["data_registrazione"], :name => "pff_data_registrazione_fk_idx"
  add_index "pagamenti_fatture_fornitori", ["fattura_fornitore_id"], :name => "pff_fattura_fornitore_fk_idx"
  add_index "pagamenti_fatture_fornitori", ["maxi_pagamento_fornitore_id"], :name => "pff_maxi_pagamento_fornitore_fk_idx"
  add_index "pagamenti_fatture_fornitori", ["tipo_pagamento_id"], :name => "pff_tipo_pagamento_fk_idx"

  create_table "pagamenti_prima_nota", :force => true do |t|
    t.integer "prima_nota_id",                  :null => false
    t.integer "pagamento_fattura_cliente_id"
    t.integer "pagamento_fattura_fornitore_id"
    t.integer "maxi_pagamento_cliente_id"
    t.integer "maxi_pagamento_fornitore_id"
  end

  add_index "pagamenti_prima_nota", ["maxi_pagamento_cliente_id"], :name => "ppn_maxi_pagamento_cliente_fk_idx"
  add_index "pagamenti_prima_nota", ["maxi_pagamento_fornitore_id"], :name => "ppn_maxi_pagamento_fornitore_fk_idx"
  add_index "pagamenti_prima_nota", ["pagamento_fattura_cliente_id"], :name => "ppn_pagamento_fattura_cliente_fk_idx"
  add_index "pagamenti_prima_nota", ["pagamento_fattura_fornitore_id"], :name => "ppn_pagamento_fattura_fornitore_fk_idx"
  add_index "pagamenti_prima_nota", ["prima_nota_id"], :name => "ppn_prima_nota_fk_idx"

  create_table "permessi", :force => true do |t|
    t.integer "utente_id",                                     :null => false
    t.integer "modulo_azienda_id",                             :null => false
    t.integer "lettura",           :limit => 2, :default => 1, :null => false
    t.integer "scrittura",         :limit => 2, :default => 1, :null => false
  end

  create_table "prima_nota", :force => true do |t|
    t.integer  "azienda_id",                                        :null => false
    t.integer  "causale_id"
    t.integer  "banca_id"
    t.text     "descrizione",                                       :null => false
    t.date     "data_operazione",                                   :null => false
    t.datetime "data_registrazione",                                :null => false
    t.integer  "esterna",                            :default => 0
    t.integer  "congelata",                          :default => 0
    t.decimal  "cassa_dare"
    t.decimal  "cassa_avere"
    t.decimal  "banca_dare"
    t.decimal  "banca_avere"
    t.decimal  "fuori_partita_dare"
    t.decimal  "fuori_partita_avere"
    t.string   "note",                :limit => 300
    t.date     "data_residuo"
    t.integer  "parent_id"
  end

  add_index "prima_nota", ["azienda_id"], :name => "pn_azienda_fk_idx"
  add_index "prima_nota", ["banca_id"], :name => "pn_banca_fk_idx"
  add_index "prima_nota", ["causale_id"], :name => "pn_causale_fk_idx"
  add_index "prima_nota", ["data_operazione"], :name => "pn_data_operazione_idx"
  add_index "prima_nota", ["data_registrazione"], :name => "pn_data_registrazione_idx"
  add_index "prima_nota", ["parent_id"], :name => "pn_parent_fk_idx"

  create_table "prodotti", :force => true do |t|
    t.integer "azienda_id",                                      :null => false
    t.string  "codice",          :limit => 20,                   :null => false
    t.string  "bar_code",        :limit => 50
    t.string  "descrizione",     :limit => 100,                  :null => false
    t.decimal "prezzo_acquisto"
    t.decimal "prezzo_vendita"
    t.string  "note",            :limit => 300
    t.integer "attivo",          :limit => 2,   :default => 1,   :null => false
    t.integer "lock_version",                   :default => 0,   :null => false
    t.integer "aliquota_id"
    t.decimal "imponibile",                     :default => 0.0, :null => false
  end

  add_index "prodotti", ["aliquota_id"], :name => "p_aliquota_fk_idx"
  add_index "prodotti", ["azienda_id"], :name => "p_azienda_fk_idx"
  add_index "prodotti", ["bar_code"], :name => "p_bar_code_idx"
  add_index "prodotti", ["codice"], :name => "p_codice_idx"

  create_table "profili", :force => true do |t|
    t.string "descrizione", :limit => 50
  end

  create_table "progressivo_ddt", :force => true do |t|
    t.integer "azienda_id",  :null => false
    t.integer "progressivo", :null => false
    t.integer "anno_rif",    :null => false
  end

  create_table "progressivo_fatture_clienti", :force => true do |t|
    t.integer "azienda_id",  :null => false
    t.integer "progressivo", :null => false
    t.integer "anno_rif",    :null => false
  end

  create_table "progressivo_nota_credito", :force => true do |t|
    t.integer "azienda_id",  :null => false
    t.integer "progressivo", :null => false
    t.integer "anno_rif",    :null => false
  end

  create_table "progressivo_nota_spese", :force => true do |t|
    t.integer "azienda_id",  :null => false
    t.integer "progressivo", :null => false
    t.integer "anno_rif",    :null => false
  end

  create_table "righe_ddt", :force => true do |t|
    t.integer "ddt_id",                                     :null => false
    t.string  "descrizione",  :limit => 500,                :null => false
    t.integer "qta",                                        :null => false
    t.integer "lock_version",                :default => 0, :null => false
  end

  add_index "righe_ddt", ["ddt_id", "id"], :name => "righe_ddt_idx"

  create_table "righe_fatture_clienti", :force => true do |t|
    t.integer "fattura_cliente_id",                               :null => false
    t.integer "importo_iva"
    t.string  "descrizione",        :limit => 500,                :null => false
    t.integer "qta",                                              :null => false
    t.decimal "importo",                                          :null => false
    t.integer "aliquota_id",                                      :null => false
    t.integer "lock_version",                      :default => 0, :null => false
  end

  add_index "righe_fatture_clienti", ["aliquota_id", "fattura_cliente_id", "id"], :name => "righe_fatture_clienti_idx"

  create_table "righe_nota_spese", :force => true do |t|
    t.integer "nota_spese_id",                               :null => false
    t.integer "importo_iva"
    t.string  "descrizione",   :limit => 500,                :null => false
    t.integer "qta",                                         :null => false
    t.decimal "importo",                                     :null => false
    t.integer "aliquota_id",                                 :null => false
    t.integer "lock_version",                 :default => 0, :null => false
  end

  add_index "righe_nota_spese", ["nota_spese_id"], :name => "rns_nota_spese_fk_idx"

  create_table "righe_ordini", :force => true do |t|
    t.integer "ordine_id",                      :null => false
    t.integer "prodotto_id",                    :null => false
    t.integer "qta",                            :null => false
    t.decimal "prezzo_acquisto"
    t.decimal "prezzo_vendita"
    t.integer "lock_version",    :default => 0, :null => false
  end

  add_index "righe_ordini", ["ordine_id"], :name => "ro_ordine_fk_idx"
  add_index "righe_ordini", ["prodotto_id"], :name => "ro_prodotto_fk_idx"

  create_table "ritenute", :force => true do |t|
    t.string  "codice",      :limit => 50,                 :null => false
    t.decimal "percentuale"
    t.string  "descrizione", :limit => 100
    t.integer "attiva",                     :default => 1
    t.integer "predefinita", :limit => 2,   :default => 0, :null => false
  end

  create_table "tipi_pagamento", :force => true do |t|
    t.integer "categoria_id",                                         :null => false
    t.string  "descrizione",            :limit => 50,                 :null => false
    t.string  "descrizione_agg",        :limit => 50
    t.integer "cassa_dare",                           :default => 0
    t.integer "cassa_avere",                          :default => 0
    t.integer "banca_dare",                           :default => 0
    t.integer "banca_avere",                          :default => 0
    t.integer "fuori_partita_dare",                   :default => 0
    t.integer "fuori_partita_avere",                  :default => 0
    t.integer "nc_cassa_dare",                        :default => 0
    t.integer "nc_cassa_avere",                       :default => 0
    t.integer "nc_banca_dare",                        :default => 0
    t.integer "nc_banca_avere",                       :default => 0
    t.integer "nc_fuori_partita_dare",                :default => 0
    t.integer "nc_fuori_partita_avere",               :default => 0
    t.integer "attivo",                               :default => 1
    t.integer "predefinito",            :limit => 2,  :default => 0,  :null => false
    t.string  "codice",                 :limit => 4,  :default => "", :null => false
    t.integer "banca_id"
    t.integer "lock_version",                         :default => 0,  :null => false
  end

  create_table "utenti", :force => true do |t|
    t.integer "profilo_id",                              :null => false
    t.string  "nominativo", :limit => 80
    t.string  "login",      :limit => 80
    t.string  "password",   :limit => 40
    t.integer "azienda_id",               :default => 1, :null => false
  end

end
