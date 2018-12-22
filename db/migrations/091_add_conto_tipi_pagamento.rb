require 'wx'
require 'app/helpers/application_helper'
require 'app/models/tipo_pagamento'

class AddContoTipiPagamento < ActiveRecord::Migration
  def self.up
    add_column :tipi_pagamento, :pdc_dare_id, :integer
    add_column :tipi_pagamento, :pdc_avere_id, :integer
    add_column :tipi_pagamento, :nc_pdc_dare_id, :integer
    add_column :tipi_pagamento, :nc_pdc_avere_id, :integer

    execute "CREATE INDEX TP_PDC_DARE_FK_IDX ON tipi_pagamento (pdc_dare_id)"
    execute "CREATE INDEX TP_PDC_AVERE_FK_IDX ON tipi_pagamento (pdc_avere_id)"
    execute "CREATE INDEX TP_NC_PDC_DARE_FK_IDX ON tipi_pagamento (nc_pdc_dare_id)"
    execute "CREATE INDEX TP_NC_PDC_AVERE_FK_IDX ON tipi_pagamento (nc_pdc_avere_id)"

    # pdc associati agli incassi impostati da sistema

    contanti = Models::TipoPagamento.find(:first,
      :conditions => ["categoria_id = 1 and descrizione = 'CONTANTI'"])
    contanti.pdc_dare = Models::Pdc.find_by_codice("34100")
    contanti.nc_pdc_avere = Models::Pdc.find_by_codice("34100")
    contanti.save_with_validation(false)

    assegno = Models::TipoPagamento.find(:first,
      :conditions => ["categoria_id = 1 and descrizione = 'ASSEGNO'"])
    assegno.pdc_dare = Models::Pdc.find_by_codice("34105")
    assegno.nc_pdc_avere = Models::Pdc.find_by_codice("33001")
    assegno.save_with_validation(false)

    bonifico = Models::TipoPagamento.find(:first,
      :conditions => ["categoria_id = 1 and descrizione = 'BONIFICO'"])
    bonifico.pdc_dare = Models::Pdc.find_by_codice("33001")
    bonifico.nc_pdc_avere = Models::Pdc.find_by_codice("33001")
    bonifico.save_with_validation(false)

    cambiali = Models::TipoPagamento.find(:first,
      :conditions => "categoria_id = 1 and descrizione like 'CAMBIALI%'",
      :order => 'id'
    )
    cambiali.pdc_dare = Models::Pdc.find_by_codice("33001")
    cambiali.pdc_avere = Models::Pdc.find_by_codice("29301")
    cambiali.nc_pdc_dare = Models::Pdc.find_by_codice("49801")
    cambiali.nc_pdc_avere = Models::Pdc.find_by_codice("33001")
    cambiali.save_with_validation(false)

    riba = Models::TipoPagamento.find(:first,
      :conditions => ["categoria_id = 1 and descrizione = 'RI.BA.'"])
    riba.pdc_dare = Models::Pdc.find_by_codice("33001")
    riba.nc_pdc_avere = Models::Pdc.find_by_codice("33001")
    riba.save_with_validation(false)

    # pdc associati ai pagamenti impostati da sistema

    contanti = Models::TipoPagamento.find(:first,
      :conditions => ["categoria_id = 2 and descrizione = 'CONTANTI'"])
    contanti.pdc_avere = Models::Pdc.find_by_codice("34100")
    contanti.nc_pdc_dare = Models::Pdc.find_by_codice("34100")
    contanti.save_with_validation(false)

    assegno = Models::TipoPagamento.find(:first,
      :conditions => ["categoria_id = 2 and descrizione = 'ASSEGNO'"])
    assegno.pdc_avere = Models::Pdc.find_by_codice("33001")
    assegno.nc_pdc_dare = Models::Pdc.find_by_codice("34105")
    assegno.save_with_validation(false)

    bonifico = Models::TipoPagamento.find(:first,
      :conditions => ["categoria_id = 2 and descrizione = 'BONIFICO'"])
    bonifico.pdc_avere = Models::Pdc.find_by_codice("33001")
    bonifico.nc_pdc_dare = Models::Pdc.find_by_codice("33001")
    bonifico.save_with_validation(false)

    cambiali = Models::TipoPagamento.find(:first,
      :conditions => "categoria_id = 2 and descrizione like 'CAMBIALI%'",
      :order => 'id'
    )
    cambiali.pdc_dare = Models::Pdc.find_by_codice("49801")
    cambiali.pdc_avere = Models::Pdc.find_by_codice("33001")
    cambiali.nc_pdc_dare = Models::Pdc.find_by_codice("33001")
    cambiali.nc_pdc_avere = Models::Pdc.find_by_codice("29301")
    cambiali.save_with_validation(false)

    riba = Models::TipoPagamento.find(:first,
      :conditions => ["categoria_id = 2 and descrizione = 'RI.BA.'"])
    riba.pdc_avere = Models::Pdc.find_by_codice("33001")
    riba.nc_pdc_dare = Models::Pdc.find_by_codice("33001")
    riba.save_with_validation(false)

  end

  def self.down
    remove_column :tipi_pagamento, :nc_pdc_dare_id
    remove_column :tipi_pagamento, :nc_pdc_avere_id
    remove_column :tipi_pagamento, :pdc_dare_id
    remove_column :tipi_pagamento, :pdc_avere_id
  end
end
