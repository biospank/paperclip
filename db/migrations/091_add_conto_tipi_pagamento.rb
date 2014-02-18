class AddContoTipiPagamento < ActiveRecord::Migration
  def self.up
    add_column :tipi_pagamento, :pdc_dare_id, :integer
    add_column :tipi_pagamento, :pdc_avere_id, :integer
  end

  def self.down
    remove_column :tipi_pagamento, :pdc_dare_id
    remove_column :tipi_pagamento, :pdc_avere_id
  end
end
