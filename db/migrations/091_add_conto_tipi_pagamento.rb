class AddContoTipiPagamento < ActiveRecord::Migration
  def self.up
    add_column :tipi_pagamento, :pdc_dare_id, :integer
    add_column :tipi_pagamento, :pdc_avere_id, :integer
    add_column :tipi_pagamento, :nc_pdc_dare_id, :integer
    add_column :tipi_pagamento, :nc_pdc_avere_id, :integer


    # pdc associati agli incassi impostati da sistema
    execute("update tipi_pagamento set pdc_dare_id = 34100, nc_pdc_avere_id = 34100 where categoria_id = 1 and descrizione = 'CONTANTI'")
    execute("update tipi_pagamento set pdc_dare_id = 34105, nc_pdc_avere_id = 34105 where categoria_id = 1 and descrizione = 'ASSEGNO'")
    execute("update tipi_pagamento set pdc_dare_id = 33001, nc_pdc_avere_id = 33001 where categoria_id = 1 and descrizione = 'BONIFICO'")
    execute("update tipi_pagamento set pdc_dare_id = 33001, pdc_avere_id = 29504, nc_pdc_dare_id = 49805, nc_pdc_avere_id = 33001 where categoria_id = 1 and descrizione like 'CAMBIALI%'")
    execute("update tipi_pagamento set pdc_dare_id = 33001, nc_pdc_avere_id = 33001 where categoria_id = 1 and descrizione = 'RI.BA.'")

    # pdc associati ai pagamenti impostati da sistema
    execute("update tipi_pagamento set pdc_avere_id = 34100, nc_pdc_dare_id = 34100 where categoria_id = 2 and descrizione = 'CONTANTI'")
    execute("update tipi_pagamento set pdc_avere_id = 34105, nc_pdc_dare_id = 34105 where categoria_id = 2 and descrizione = 'ASSEGNO'")
    execute("update tipi_pagamento set pdc_avere_id = 33001, nc_pdc_dare_id = 33001 where categoria_id = 2 and descrizione = 'BONIFICO'")
    execute("update tipi_pagamento set pdc_avere_id = 33001, pdc_dare_id = 29504, nc_pdc_avere_id = 49805, nc_pdc_dare_id = 33001 where categoria_id = 2 and descrizione like 'CAMBIALI%'")
    execute("update tipi_pagamento set pdc_avere_id = 33001, nc_pdc_dare_id = 33001 where categoria_id = 2 and descrizione = 'RI.BA.'")

  end

  def self.down
    remove_column :tipi_pagamento, :nc_pdc_dare_id
    remove_column :tipi_pagamento, :nc_pdc_avere_id
    remove_column :tipi_pagamento, :pdc_dare_id
    remove_column :tipi_pagamento, :pdc_avere_id
  end
end
