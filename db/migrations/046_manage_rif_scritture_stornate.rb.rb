class ManageRifScrittureStornate < ActiveRecord::Migration
  ### CLIENTI ###
  INCASSI_CLIENTI_CONGELATI = <<-EOS
  select prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  left join pagamenti_fatture_clienti on pagamenti_prima_nota.pagamento_fattura_cliente_id = pagamenti_fatture_clienti.id
  where pagamenti_prima_nota.pagamento_fattura_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_cliente_id is null and 
  pagamenti_fatture_clienti.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 1 and prima_nota.descrizione not like '%STORNO%'
  EOS

  ### FORNITORI ###
  
  PAGAMENTI_FORNITORI_CONGELATI = <<-EOS
  select prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  left join pagamenti_fatture_fornitori on pagamenti_prima_nota.pagamento_fattura_fornitore_id = pagamenti_fatture_fornitori.id
  where pagamenti_prima_nota.pagamento_fattura_cliente_id is null and 
  pagamenti_prima_nota.maxi_pagamento_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_cliente_id is null and 
  pagamenti_fatture_fornitori.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 1 and prima_nota.descrizione not like '%STORNO%'
  EOS

  def self.up
    
    conn = Models::Scrittura.connection
    
    ### CLIENTI ###
    scritture = conn.select_all(INCASSI_CLIENTI_CONGELATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      if scrittura.stornata?
        Models::PagamentoPrimaNota.delete_all(["prima_nota_id = ?", scrittura.id])
      end
    end

    ### FORNITORI ###
    scritture = conn.select_all(PAGAMENTI_FORNITORI_CONGELATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      if scrittura.stornata?
        Models::PagamentoPrimaNota.delete_all(["prima_nota_id = ?", scrittura.id])
      end
    end

  end

  def self.down

  end
end
