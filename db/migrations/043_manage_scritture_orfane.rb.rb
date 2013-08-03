class ManageScrittureOrfane < ActiveRecord::Migration
  DESCRIZIONE_STORNO = "** STORNO SCRITTURA del %s ** "
  
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

  
  INCASSI_MULTIPLI_CONGELATI_NON_ELIMINATI = <<-EOS
  select distinct prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  inner join maxi_pagamenti_clienti on pagamenti_prima_nota.maxi_pagamento_cliente_id = maxi_pagamenti_clienti.id
  left join pagamenti_fatture_clienti on pagamenti_prima_nota.pagamento_fattura_cliente_id = pagamenti_fatture_clienti.id
  where pagamenti_prima_nota.pagamento_fattura_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_fornitore_id is null and 
  pagamenti_fatture_clienti.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 1 and prima_nota.descrizione not like '%STORNO%'
  EOS
  
  INCASSI_MULTIPLI_CONGELATI_ELIMINATI = <<-EOS
  select distinct prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  left join maxi_pagamenti_clienti on pagamenti_prima_nota.maxi_pagamento_cliente_id = maxi_pagamenti_clienti.id
  left join pagamenti_fatture_clienti on pagamenti_prima_nota.pagamento_fattura_cliente_id = pagamenti_fatture_clienti.id
  where pagamenti_prima_nota.pagamento_fattura_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_cliente_id is not null and 
  pagamenti_prima_nota.pagamento_fattura_cliente_id is not null and 
  pagamenti_fatture_clienti.id is null and 
  maxi_pagamenti_clienti.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 1 and prima_nota.descrizione not like '%STORNO%'
  EOS
  
  INCASSI_CLIENTI = <<-EOS
  select prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  left join pagamenti_fatture_clienti on pagamenti_prima_nota.pagamento_fattura_cliente_id = pagamenti_fatture_clienti.id
  where pagamenti_prima_nota.pagamento_fattura_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_cliente_id is null and 
  pagamenti_fatture_clienti.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 0 and prima_nota.descrizione not like '%STORNO%'
  EOS

  INCASSI_MULTIPLI_NON_ELIMINATI = <<-EOS
  select distinct prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  inner join maxi_pagamenti_clienti on pagamenti_prima_nota.maxi_pagamento_cliente_id = maxi_pagamenti_clienti.id
  left join pagamenti_fatture_clienti on pagamenti_prima_nota.pagamento_fattura_cliente_id = pagamenti_fatture_clienti.id
  where pagamenti_prima_nota.pagamento_fattura_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_fornitore_id is null and 
  pagamenti_fatture_clienti.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 0 and prima_nota.descrizione not like '%STORNO%'
  EOS

  INCASSI_MULTIPLI_ELIMINATI = <<-EOS
  select distinct prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  left join maxi_pagamenti_clienti on pagamenti_prima_nota.maxi_pagamento_cliente_id = maxi_pagamenti_clienti.id
  left join pagamenti_fatture_clienti on pagamenti_prima_nota.pagamento_fattura_cliente_id = pagamenti_fatture_clienti.id
  where pagamenti_prima_nota.pagamento_fattura_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_cliente_id is not null and 
  pagamenti_prima_nota.pagamento_fattura_cliente_id is not null and 
  pagamenti_fatture_clienti.id is null and 
  maxi_pagamenti_clienti.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 0 and prima_nota.descrizione not like '%STORNO%'
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

  
  PAGAMENTI_MULTIPLI_CONGELATI_NON_ELIMINATI = <<-EOS
  select distinct prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  inner join maxi_pagamenti_fornitori on pagamenti_prima_nota.maxi_pagamento_fornitore_id = maxi_pagamenti_fornitori.id
  left join pagamenti_fatture_fornitori on pagamenti_prima_nota.pagamento_fattura_fornitore_id = pagamenti_fatture_fornitori.id
  where pagamenti_prima_nota.pagamento_fattura_cliente_id is null and 
  pagamenti_prima_nota.maxi_pagamento_cliente_id is null and 
  pagamenti_fatture_fornitori.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 1 and prima_nota.descrizione not like '%STORNO%'
  EOS
  
  PAGAMENTI_MULTIPLI_CONGELATI_ELIMINATI = <<-EOS
  select distinct prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  left join maxi_pagamenti_fornitori on pagamenti_prima_nota.maxi_pagamento_fornitore_id = maxi_pagamenti_fornitori.id
  left join pagamenti_fatture_fornitori on pagamenti_prima_nota.pagamento_fattura_fornitore_id = pagamenti_fatture_fornitori.id
  where pagamenti_prima_nota.pagamento_fattura_cliente_id is null and 
  pagamenti_prima_nota.maxi_pagamento_cliente_id is null and 
  pagamenti_prima_nota.maxi_pagamento_fornitore_id is not null and 
  pagamenti_prima_nota.pagamento_fattura_fornitore_id is not null and 
  pagamenti_fatture_fornitori.id is null and 
  maxi_pagamenti_fornitori.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 1 and prima_nota.descrizione not like '%STORNO%'
  EOS
  
  PAGAMENTI_FORNITORI = <<-EOS
  select prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  left join pagamenti_fatture_fornitori on pagamenti_prima_nota.pagamento_fattura_fornitore_id = pagamenti_fatture_fornitori.id
  where pagamenti_prima_nota.pagamento_fattura_cliente_id is null and 
  pagamenti_prima_nota.maxi_pagamento_fornitore_id is null and 
  pagamenti_prima_nota.maxi_pagamento_cliente_id is null and 
  pagamenti_fatture_fornitori.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 0 and prima_nota.descrizione not like '%STORNO%'
  EOS

  PAGAMENTI_MULTIPLI_NON_ELIMINATI = <<-EOS
  select distinct prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  inner join maxi_pagamenti_fornitori on pagamenti_prima_nota.maxi_pagamento_fornitore_id = maxi_pagamenti_fornitori.id
  left join pagamenti_fatture_fornitori on pagamenti_prima_nota.pagamento_fattura_fornitore_id = pagamenti_fatture_fornitori.id
  where pagamenti_prima_nota.pagamento_fattura_cliente_id is null and 
  pagamenti_prima_nota.maxi_pagamento_cliente_id is null and 
  pagamenti_fatture_fornitori.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 0 and prima_nota.descrizione not like '%STORNO%'
  EOS

  PAGAMENTI_MULTIPLI_ELIMINATI = <<-EOS
  select distinct prima_nota.id as scrittura_id from pagamenti_prima_nota 
  inner join prima_nota on pagamenti_prima_nota.prima_nota_id = prima_nota.id
  left join maxi_pagamenti_fornitori on pagamenti_prima_nota.maxi_pagamento_fornitore_id = maxi_pagamenti_fornitori.id
  left join pagamenti_fatture_fornitori on pagamenti_prima_nota.pagamento_fattura_fornitore_id = pagamenti_fatture_fornitori.id
  where pagamenti_prima_nota.pagamento_fattura_cliente_id is null and 
  pagamenti_prima_nota.maxi_pagamento_cliente_id is null and 
  pagamenti_prima_nota.maxi_pagamento_fornitore_id is not null and 
  pagamenti_prima_nota.pagamento_fattura_fornitore_id is not null and 
  pagamenti_fatture_fornitori.id is null and 
  maxi_pagamenti_fornitori.id is null and 
  prima_nota.esterna = 1 and prima_nota.congelata = 0 and prima_nota.descrizione not like '%STORNO%'
  EOS

  def self.up
    change_column :tipi_pagamento, :descrizione_agg, :string, :null => true, :limit => 50
    change_column :azienda, :attivita_merc, :integer, :limit => 1
    change_column :nota_spese, :fattura_cliente_id, :integer
    change_column :ddt, :mezzo_trasporto, :string, :limit => 100
    # solo per i nuovi clienti che hanno ricevuto il pacchetto con l'errore nella migrazione
    if Models::PagamentoPrimaNota.column_names.include? 'maxi_pagamento_fattura_cliente_id'
      rename_column :pagamenti_prima_nota, :maxi_pagamento_fattura_cliente_id, :maxi_pagamento_cliente_id
      rename_column :pagamenti_prima_nota, :maxi_pagamento_fattura_fornitore_id, :maxi_pagamento_fornitore_id
    end
    
    conn = Models::Scrittura.connection
    
    ### CLIENTI ###
    scritture = conn.select_all(INCASSI_CLIENTI_CONGELATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      storno = Models::Scrittura.new(:azienda => scrittura.azienda,
                              :parent => scrittura,
                              :descrizione => DESCRIZIONE_STORNO % scrittura.data_operazione.to_s(:italian_date) + scrittura.descrizione,
                              :data_operazione => Date.today,
                              :data_registrazione => Time.now,
                              :esterna => 1,
                              :congelata => 0)

      storno.cassa_dare = (scrittura.cassa_dare * -1) if scrittura.cassa_dare
      storno.cassa_avere = (scrittura.cassa_avere * -1) if scrittura.cassa_avere
      storno.banca_dare = (scrittura.banca_dare * -1) if scrittura.banca_dare
      storno.banca_avere = (scrittura.banca_avere * -1) if scrittura.banca_avere
      storno.fuori_partita_dare = (scrittura.fuori_partita_dare * -1) if scrittura.fuori_partita_dare
      storno.fuori_partita_avere = (scrittura.fuori_partita_avere * -1) if scrittura.fuori_partita_avere
      
      storno.save_with_validation(false)
      Models::PagamentoPrimaNota.delete_all(["prima_nota_id = ?", scrittura.id])
    end

    scritture = conn.select_all(INCASSI_MULTIPLI_CONGELATI_NON_ELIMINATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      storno = Models::Scrittura.new(:azienda => scrittura.azienda,
                              :parent => scrittura,
                              :descrizione => DESCRIZIONE_STORNO % scrittura.data_operazione.to_s(:italian_date) + scrittura.descrizione,
                              :data_operazione => Date.today,
                              :data_registrazione => Time.now,
                              :esterna => 1,
                              :congelata => 0)

      storno.cassa_dare = (scrittura.cassa_dare * -1) if scrittura.cassa_dare
      storno.cassa_avere = (scrittura.cassa_avere * -1) if scrittura.cassa_avere
      storno.banca_dare = (scrittura.banca_dare * -1) if scrittura.banca_dare
      storno.banca_avere = (scrittura.banca_avere * -1) if scrittura.banca_avere
      storno.fuori_partita_dare = (scrittura.fuori_partita_dare * -1) if scrittura.fuori_partita_dare
      storno.fuori_partita_avere = (scrittura.fuori_partita_avere * -1) if scrittura.fuori_partita_avere
      
      storno.save_with_validation(false)
      Models::PagamentoPrimaNota.delete_all(["prima_nota_id = ?", scrittura.id])
    end

    scritture = conn.select_all(INCASSI_MULTIPLI_CONGELATI_ELIMINATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      storno = Models::Scrittura.new(:azienda => scrittura.azienda,
                              :parent => scrittura,
                              :descrizione => DESCRIZIONE_STORNO % scrittura.data_operazione.to_s(:italian_date) + scrittura.descrizione,
                              :data_operazione => Date.today,
                              :data_registrazione => Time.now,
                              :esterna => 1,
                              :congelata => 0)

      storno.cassa_dare = (scrittura.cassa_dare * -1) if scrittura.cassa_dare
      storno.cassa_avere = (scrittura.cassa_avere * -1) if scrittura.cassa_avere
      storno.banca_dare = (scrittura.banca_dare * -1) if scrittura.banca_dare
      storno.banca_avere = (scrittura.banca_avere * -1) if scrittura.banca_avere
      storno.fuori_partita_dare = (scrittura.fuori_partita_dare * -1) if scrittura.fuori_partita_dare
      storno.fuori_partita_avere = (scrittura.fuori_partita_avere * -1) if scrittura.fuori_partita_avere
      
      storno.save_with_validation(false)
      Models::PagamentoPrimaNota.delete_all(["prima_nota_id = ?", scrittura.id])
    end

    scritture = conn.select_all(INCASSI_CLIENTI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      scrittura.destroy
    end

    scritture = conn.select_all(INCASSI_MULTIPLI_NON_ELIMINATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      scrittura.destroy
    end

    scritture = conn.select_all(INCASSI_MULTIPLI_ELIMINATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      scrittura.destroy
    end

    ### FORNITORI ###
    scritture = conn.select_all(PAGAMENTI_FORNITORI_CONGELATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      storno = Models::Scrittura.new(:azienda => scrittura.azienda,
                              :parent => scrittura,
                              :descrizione => DESCRIZIONE_STORNO % scrittura.data_operazione.to_s(:italian_date) + scrittura.descrizione,
                              :data_operazione => Date.today,
                              :data_registrazione => Time.now,
                              :esterna => 1,
                              :congelata => 0)

      storno.cassa_dare = (scrittura.cassa_dare * -1) if scrittura.cassa_dare
      storno.cassa_avere = (scrittura.cassa_avere * -1) if scrittura.cassa_avere
      storno.banca_dare = (scrittura.banca_dare * -1) if scrittura.banca_dare
      storno.banca_avere = (scrittura.banca_avere * -1) if scrittura.banca_avere
      storno.fuori_partita_dare = (scrittura.fuori_partita_dare * -1) if scrittura.fuori_partita_dare
      storno.fuori_partita_avere = (scrittura.fuori_partita_avere * -1) if scrittura.fuori_partita_avere
      
      storno.save_with_validation(false)
      Models::PagamentoPrimaNota.delete_all(["prima_nota_id = ?", scrittura.id])
    end

    scritture = conn.select_all(PAGAMENTI_MULTIPLI_CONGELATI_NON_ELIMINATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      storno = Models::Scrittura.new(:azienda => scrittura.azienda,
                              :parent => scrittura,
                              :descrizione => DESCRIZIONE_STORNO % scrittura.data_operazione.to_s(:italian_date) + scrittura.descrizione,
                              :data_operazione => Date.today,
                              :data_registrazione => Time.now,
                              :esterna => 1,
                              :congelata => 0)

      storno.cassa_dare = (scrittura.cassa_dare * -1) if scrittura.cassa_dare
      storno.cassa_avere = (scrittura.cassa_avere * -1) if scrittura.cassa_avere
      storno.banca_dare = (scrittura.banca_dare * -1) if scrittura.banca_dare
      storno.banca_avere = (scrittura.banca_avere * -1) if scrittura.banca_avere
      storno.fuori_partita_dare = (scrittura.fuori_partita_dare * -1) if scrittura.fuori_partita_dare
      storno.fuori_partita_avere = (scrittura.fuori_partita_avere * -1) if scrittura.fuori_partita_avere
      
      storno.save_with_validation(false)
      Models::PagamentoPrimaNota.delete_all(["prima_nota_id = ?", scrittura.id])
    end

    scritture = conn.select_all(PAGAMENTI_MULTIPLI_CONGELATI_ELIMINATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      storno = Models::Scrittura.new(:azienda => scrittura.azienda,
                              :parent => scrittura,
                              :descrizione => DESCRIZIONE_STORNO % scrittura.data_operazione.to_s(:italian_date) + scrittura.descrizione,
                              :data_operazione => Date.today,
                              :data_registrazione => Time.now,
                              :esterna => 1,
                              :congelata => 0)

      storno.cassa_dare = (scrittura.cassa_dare * -1) if scrittura.cassa_dare
      storno.cassa_avere = (scrittura.cassa_avere * -1) if scrittura.cassa_avere
      storno.banca_dare = (scrittura.banca_dare * -1) if scrittura.banca_dare
      storno.banca_avere = (scrittura.banca_avere * -1) if scrittura.banca_avere
      storno.fuori_partita_dare = (scrittura.fuori_partita_dare * -1) if scrittura.fuori_partita_dare
      storno.fuori_partita_avere = (scrittura.fuori_partita_avere * -1) if scrittura.fuori_partita_avere
      
      storno.save_with_validation(false)
      Models::PagamentoPrimaNota.delete_all(["prima_nota_id = ?", scrittura.id])
    end

    scritture = conn.select_all(PAGAMENTI_FORNITORI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      scrittura.destroy
    end

    scritture = conn.select_all(PAGAMENTI_MULTIPLI_NON_ELIMINATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      scrittura.destroy
    end

    scritture = conn.select_all(PAGAMENTI_MULTIPLI_ELIMINATI)
    scritture.each do |item|
      scrittura = Models::Scrittura.find(item["scrittura_id"].to_i)
      scrittura.destroy
    end

  end

  def self.down

  end
end
