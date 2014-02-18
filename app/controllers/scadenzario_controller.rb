# encoding: utf-8

module Controllers
  module ScadenzarioController
    include Controllers::BaseController
    include Helpers::ScadenzarioHelper::Report
    

    # gestione interesse

    def save_interessi_liquidazione_trimestrale()
      interesse.save
    end

    def load_interessi_liquidazione_trimestrale()
      InteressiLiquidazioneTrimestrale.find(:first)
    end

    # gestione norma
    def save_norma()
      norma.save
    end

    def delete_norma()
      norma.destroy
    end

    def load_norma(id)
      Norma.find(id)
    end

    def load_norma_by_codice(codice)
      Norma.find_by_codice(codice)
    end

    def search_for_norma()
      Norma.search_for(filtro.ricerca,
        [:codice, :percentuale, :descrizione],
        build_norma_dialog_conditions())
    end

    def build_norma_dialog_conditions()
      query_str = []
      parametri = []

      filtro.build_conditions(query_str, parametri) if filtro

      {:conditions => [query_str.join(' AND '), *parametri],
       :order => 'codice'}
    end

    # gestione fattura cliente

    def load_fattura_cliente(id)
      FatturaClienteScadenzario.find(id)
    end
    
    def save_fattura_cliente()
      pagamenti = incassi_fattura_cliente_panel.result_set_lstrep_incassi_fattura

      FatturaCliente.transaction do
        fattura_cliente.save!

        pagamenti_da_eliminare = []

        pagamenti.each do |pagamento|
          case pagamento.instance_status
          when PagamentoFatturaCliente::ST_INSERT
            # associo l'id della fattura cliente alla riga
            pagamento.fattura_cliente = fattura_cliente
            pagamento.save!
          when PagamentoFatturaCliente::ST_UPDATE
            pagamento.save!
          when PagamentoFatturaCliente::ST_DELETE
            pagamenti_da_eliminare << pagamento
          end
        end

        elimina_pagamenti_fattura_cliente(fattura_cliente, pagamenti_da_eliminare)
        salva_righe_fattura_pdc_cliente(fattura_cliente)

      end

      # i pagamenti della fattura che ho salvato devono essere immediatamente
      # registrati in prima nota se la data di pagamento è <= ad oggi
      # NOTA:
      # SQLite non gestisce le sessioni sul db, quindi, se questa procedura
      # viene spostata all'interno della transazione, non funziona.
      pagamenti = PagamentoFatturaCliente.find(:all, :include => [:tipo_pagamento, :maxi_pagamento_cliente], :conditions => ["fattura_cliente_id = ? and pagamenti_fatture_clienti.data_pagamento <= ? and registrato_in_prima_nota = ? ", fattura_cliente, Date.today, 0])
      pagamenti.each do |pagamento|

        unless pagamento.tipo_pagamento.nil?
          if pagamento.tipo_pagamento.valido?
            if pagamento.maxi_pagamento_cliente_id.nil?
              descrizione = build_descrizione_pagamento_fattura_cliente(pagamento, fattura_cliente.nota_di_credito?)
              if scrittura = scrittura_prima_nota(fattura_cliente, pagamento, descrizione)
                relazione_pagamento_scrittura_prima_nota(scrittura, pagamento)
              end
            else
              # sommo tutti i pagamenti cliente con maxi_pagamento_cliente_id = pagamento.id
              # se la somma è >= maxi_pagamento_cliente associato al pagamento
              # costruisco la descrizione multipla, registro in prima nota e chiudo il maxi pagamento
              totale_pagamenti_multipli = PagamentoFatturaCliente.sum(:importo, :conditions => ["maxi_pagamento_cliente_id = ?", pagamento.maxi_pagamento_cliente_id])
#                sql = QueryHelper.totale_pagamenti_multipli_cliente_query_string(pagamento.maxi_pagamento_cliente_id)
#                totale_pagamenti_multipli = PagamentoFatturaCliente.find_by_sql(sql)[0][:totale_pagamenti_multipli].to_f
              if(Helpers::ApplicationHelper.real(totale_pagamenti_multipli) >= Helpers::ApplicationHelper.real(pagamento.maxi_pagamento_cliente.importo))
                descrizione = build_descrizione_multipla_pagamento_fattura_cliente(pagamento, fattura_cliente.nota_di_credito?)
                if scrittura = scrittura_multipla_prima_nota(fattura_cliente, pagamento.maxi_pagamento_cliente, descrizione)
                  relazione_multipla_pagamento_scrittura_prima_nota(scrittura, pagamento)
                end
              end
            end
          end
        end

      end

      # Chiudo i maxi pagamenti con residuo a 0.0 non ancora scaduti
      # 
      MaxiPagamentoCliente.find(:all, :conditions => ["chiuso = ?", 0]).collect do |maxi_pagamento|
        totale_pagamenti_multipli = PagamentoFatturaCliente.sum(:importo, :conditions => ["maxi_pagamento_cliente_id = ?", maxi_pagamento.id])
#          sql = QueryHelper.totale_pagamenti_multipli_cliente_query_string(maxi_pagamento.id)
#          totale_pagamenti_multipli = PagamentoFatturaCliente.find_by_sql(sql)[0][:totale_pagamenti_multipli].to_f
        if(Helpers::ApplicationHelper.real(totale_pagamenti_multipli) >= Helpers::ApplicationHelper.real(maxi_pagamento.importo)) 
          maxi_pagamento.update_attributes(:chiuso => 1)
        end

      end
        
      return true

    end

    def elimina_pagamenti_fattura_cliente(fattura, pagamenti_da_eliminare)
      pagamenti_da_eliminare.each do |pagamento|
        if pagamento.registrato_in_prima_nota?
          if pagamento.maxi_pagamento_cliente 
            totale_pagamenti_multipli = PagamentoFatturaCliente.sum(:importo, :conditions => ["maxi_pagamento_cliente_id = ?", pagamento.maxi_pagamento_cliente_id])
            if(Helpers::ApplicationHelper.real(totale_pagamenti_multipli) >= Helpers::ApplicationHelper.real(pagamento.maxi_pagamento_cliente.importo))
              # cerco la scrittura associata al pagamento
              if scrittura = pagamento.scrittura
                if scrittura.congelata?
                  descrizione = build_descrizione_multipla_storno_pagamento_fattura_cliente(pagamento, fattura.nota_di_credito?)
                  storno_scrittura_multipla_prima_nota(fattura, scrittura, pagamento.maxi_pagamento_cliente, descrizione)
                  # in caso di pagamenti multipli, devono essere rimossi tutti i riferimenti
                  PagamentoPrimaNota.delete_all("maxi_pagamento_cliente_id = #{pagamento.maxi_pagamento_cliente.id}")
                else
                  # il destroy direttamente su scrittura non funziona
                  Models::Scrittura.find(scrittura).destroy
                  pagamento.maxi_pagamento_cliente.update_attributes(:chiuso => 0)
                end
              else
                descrizione = build_descrizione_multipla_storno_pagamento_fattura_cliente(pagamento, fattura.nota_di_credito?)
                storno_scrittura_multipla_prima_nota(fattura, scrittura, pagamento.maxi_pagamento_cliente, descrizione)
              end
              # resetto il flag della registrazione in prima nota per tutti i pagamenti associati al maxi pagamento
              # viene fatto all'interno di storno_scrittura_multipla_prima_nota
              #PagamentoFatturaCliente.update_all(["registrato_in_prima_nota = ?", 0], ["maxi_pagamento_cliente_id = ?", pagamento.maxi_pagamento_cliente.id])
            end
          else
            # cerco la scrittura associata al pagamento
            if scrittura = pagamento.scrittura
              if scrittura.congelata?
                descrizione = build_descrizione_storno_pagamento_fattura_cliente(pagamento, fattura.nota_di_credito?)
                storno_scrittura_prima_nota(fattura, pagamento, descrizione)
                PagamentoPrimaNota.delete_all("prima_nota_id = #{scrittura.id}")
              else
                  # il destroy direttamente su scrittura non funziona
                Models::Scrittura.find(scrittura).destroy
              end
            else
              descrizione = build_descrizione_storno_pagamento_fattura_cliente(pagamento, fattura.nota_di_credito?)
              storno_scrittura_prima_nota(fattura, pagamento, descrizione)
            end
          end
        end
        pagamento.destroy
      end

    end

    def delete_fattura_cliente()
      elimina_pagamenti_fattura_cliente(fattura_cliente, fattura_cliente.pagamento_fattura_cliente)
      if fattura_cliente.da_fatturazione?
        PagamentoFatturaCliente.delete_all(["fattura_cliente_id = ?", fattura_cliente])
        # ActiveRecord BUG
        # un bug impedisce ai modelli ereditati (es Models::FatturaClienteScadenzario < Models::FatturaCliente)
        # di utilizzare update_attributes, update_attribute e non so cos'altro
        #fattura_cliente.update_attributes(:da_scadenzario => 0)
        Models::FatturaCliente.update(fattura_cliente, :da_scadenzario => 0)
      else
        fattura_cliente.destroy
      end
    end

    def search_incassi_fattura_cliente(fc)
      PagamentoFatturaCliente.search(:all, :conditions => ['fattura_cliente_id = ?', fc], :include => [:tipo_pagamento], :order => 'pagamenti_fatture_clienti.id')
    end

    # gestione fattura fornitore

    def load_fattura_fornitore(id)
      FatturaFornitore.find(id)
    end
    
    def save_fattura_fornitore()
      pagamenti = pagamenti_fattura_fornitore_panel.result_set_lstrep_pagamenti_fattura

      FatturaFornitore.transaction do
        fattura_fornitore.save!

        pagamenti_da_eliminare = []

        pagamenti.each do |pagamento|
          case pagamento.instance_status
          when PagamentoFatturaFornitore::ST_INSERT
            # associo l'id della fattura fornitore alla riga
            pagamento.fattura_fornitore = fattura_fornitore
            pagamento.save!
          when PagamentoFatturaFornitore::ST_UPDATE
            pagamento.save!
          when PagamentoFatturaFornitore::ST_DELETE
            pagamenti_da_eliminare << pagamento
          end
        end

        elimina_pagamenti_fattura_fornitore(fattura_fornitore, pagamenti_da_eliminare)
        salva_righe_fattura_pdc_fornitore(fattura_fornitore)

      end

      # i pagamenti della fattura che ho salvato devono essere immediatamente
      # registrati in prima nota se la data di pagamento è <= ad oggi
      # NOTA:
      # SQLite non gestisce le sessioni sul db, quindi, se questa procedura
      # viene spostata all'interno della transazione, non funziona.
      pagamenti = PagamentoFatturaFornitore.find(:all, :include => [:tipo_pagamento, :maxi_pagamento_fornitore], :conditions => ["fattura_fornitore_id = ? and pagamenti_fatture_fornitori.data_pagamento <= ? and registrato_in_prima_nota = ? ", fattura_fornitore, Date.today, 0])
      pagamenti.each do |pagamento|

        unless pagamento.tipo_pagamento.nil?
          if pagamento.tipo_pagamento.valido?
            if pagamento.maxi_pagamento_fornitore_id.nil?
              descrizione = build_descrizione_pagamento_fattura_fornitore(pagamento, fattura_fornitore.nota_di_credito?)
              if scrittura = scrittura_prima_nota(fattura_fornitore, pagamento, descrizione)
                relazione_pagamento_scrittura_prima_nota(scrittura, pagamento)
              end
            else
              # sommo tutti i pagamenti fornitore con maxi_pagamento_fornitore_id = pagamento.id
              # se la somma è >= maxi_pagamento_fornitore associato al pagamento
              # costruisco la descrizione multipla, registro in prima nota e chiudo il maxi pagamento
              totale_pagamenti_multipli = PagamentoFatturaFornitore.sum(:importo, :conditions => ["maxi_pagamento_fornitore_id = ?", pagamento.maxi_pagamento_fornitore_id])
#                sql = QueryHelper.totale_pagamenti_multipli_fornitore_query_string(pagamento.maxi_pagamento_fornitore_id)
#                totale_pagamenti_multipli = PagamentoFatturaFornitore.find_by_sql(sql)[0][:totale_pagamenti_multipli].to_f
              if(Helpers::ApplicationHelper.real(totale_pagamenti_multipli) >= Helpers::ApplicationHelper.real(pagamento.maxi_pagamento_fornitore.importo))
                descrizione = build_descrizione_multipla_pagamento_fattura_fornitore(pagamento, fattura_fornitore.nota_di_credito?)
                if scrittura = scrittura_multipla_prima_nota(fattura_fornitore, pagamento.maxi_pagamento_fornitore, descrizione)
                  relazione_multipla_pagamento_scrittura_prima_nota(scrittura, pagamento)
                end
              end
            end
          end
        end

      end

      # Chiudo i maxi pagamenti con residuo a 0.0 non ancora scaduti
      # 
      MaxiPagamentoFornitore.find(:all, :conditions => ["chiuso = ?", 0]).collect do |maxi_pagamento|
        totale_pagamenti_multipli = PagamentoFatturaFornitore.sum(:importo, :conditions => ["maxi_pagamento_fornitore_id = ?", maxi_pagamento.id])
#          sql = QueryHelper.totale_pagamenti_multipli_fornitore_query_string(maxi_pagamento.id)
#          totale_pagamenti_multipli = PagamentoFatturaFornitore.find_by_sql(sql)[0][:totale_pagamenti_multipli].to_f
        if(Helpers::ApplicationHelper.real(totale_pagamenti_multipli) >= Helpers::ApplicationHelper.real(maxi_pagamento.importo))
          maxi_pagamento.update_attributes(:chiuso => 1)
        end

      end
        
      return true

    end

    def elimina_pagamenti_fattura_fornitore(fattura, pagamenti_da_eliminare)
      pagamenti_da_eliminare.each do |pagamento|
        if pagamento.registrato_in_prima_nota?
          if pagamento.maxi_pagamento_fornitore 
            # solo se il totale dei pagamenti (associati al maxi_pagamento) e' uguale all'importo del maxi pagamento
            # c'e' sicuramente una registrazione i prima nota
            totale_pagamenti_multipli = PagamentoFatturaFornitore.sum(:importo, :conditions => ["maxi_pagamento_fornitore_id = ?", pagamento.maxi_pagamento_fornitore_id])
            if(Helpers::ApplicationHelper.real(totale_pagamenti_multipli) >= Helpers::ApplicationHelper.real(pagamento.maxi_pagamento_fornitore.importo))
              # cerco la scrittura associata al pagamento
              if scrittura = pagamento.scrittura
                if scrittura.congelata?
                  # lo storno viene fatto solo se la scrittura e' congelata
                  descrizione = build_descrizione_multipla_storno_pagamento_fattura_fornitore(pagamento, fattura.nota_di_credito?)
                  storno_scrittura_multipla_prima_nota(fattura, scrittura, pagamento.maxi_pagamento_fornitore, descrizione)
                  # in caso di pagamenti multipli, devono essere rimossi tutti i riferimenti
                  PagamentoPrimaNota.delete_all("maxi_pagamento_fornitore_id = #{pagamento.maxi_pagamento_fornitore.id}")
                else
                  # il destroy direttamente su scrittura non funziona
                  Models::Scrittura.find(scrittura).destroy
                  # deve essere riabilitato il maxi_pagamento
                  pagamento.maxi_pagamento_fornitore.update_attributes(:chiuso => 0)
                end
              else
                # non esiste per i pagamenti vecchi che non avevano ancora l'associazione con la scrittura
                # in questo caso lo storno e' necessario per risalire al pagamento
                # NOTA: non dovrebbe piu' verificarsi
                descrizione = build_descrizione_multipla_storno_pagamento_fattura_fornitore(pagamento, fattura.nota_di_credito?)
                storno_scrittura_multipla_prima_nota(fattura, scrittura, pagamento.maxi_pagamento_fornitore, descrizione)
              end
              # resetto il flag della registrazione in prima nota per tutti i pagamenti associati al maxi pagamento
              # viene fatto all'interno di storno_scrittura_multipla_prima_nota
              #PagamentoFatturaFornitore.update_all(["registrato_in_prima_nota = ?", 0], ["maxi_pagamento_fornitore_id = ?", pagamento.maxi_pagamento_fornitore.id])
            end
          else
            # cerco la scrittura associata al pagamento
            if scrittura = pagamento.scrittura
              if scrittura.congelata?
                descrizione = build_descrizione_storno_pagamento_fattura_fornitore(pagamento, fattura.nota_di_credito?)
                storno_scrittura_prima_nota(fattura, pagamento, descrizione)
                PagamentoPrimaNota.delete_all("prima_nota_id = #{scrittura.id}")
              else
                # il destroy direttamente su scrittura non funziona
                Models::Scrittura.find(scrittura).destroy
              end
            else
              descrizione = build_descrizione_storno_pagamento_fattura_fornitore(pagamento, fattura.nota_di_credito?)
              storno_scrittura_prima_nota(fattura, pagamento, descrizione)
            end
          end
        end
        pagamento.destroy
      end

    end

    def delete_fattura_fornitore()
      elimina_pagamenti_fattura_fornitore(fattura_fornitore, fattura_fornitore.pagamento_fattura_fornitore)
      fattura_fornitore.destroy
    end

    def search_pagamenti_fattura_fornitore(ff)
      PagamentoFatturaFornitore.search(:all, :conditions => ['fattura_fornitore_id = ?', ff], :include => [:tipo_pagamento], :order => 'pagamenti_fatture_fornitori.id')
    end

    # GESTIONE TIPI PAGAMENTO
    
    def search_for_tipi_pagamento()
      TipoPagamento.search_for(filtro.ricerca, [:codice, :descrizione], build_tipi_pagamento_dialog_conditions())
    end

    def build_tipi_pagamento_dialog_conditions()
      query_str = []
      parametri = []
      
      filtro.build_conditions(query_str, parametri) if filtro
      
      {:conditions => [query_str.join(' AND '), *parametri], 
        :order => 'tipi_pagamento.descrizione'}
    end

    # GESTIONE MAXI INCASSI
    
    def load_maxi_incasso(id)
      MaxiPagamentoCliente.find(id).calcola_residuo()
    end
    
    def search_maxi_incassi()
      MaxiPagamentoCliente.search(:all, :include => [:tipo_pagamento, :pagamenti_fattura_cliente], :conditions => ["chiuso = ?", 0], :order => 'maxi_pagamenti_clienti.id').collect { |maxi_incasso| maxi_incasso.calcola_residuo() }
    end

    def save_maxi_incasso()
      maxi_incasso.save!
    end

    def riapri_maxi_incasso(maxi_incasso)
      # reimposto il flag chiuso del maxi_pagamento a 0
      maxi_incasso.update_attribute(:chiuso,  0)

    end

    def delete_maxi_incasso()
      maxi_incasso.destroy
    end

    # GESTIONE MAXI PAGAMENTI
    
    def load_maxi_pagamento(id)
      MaxiPagamentoFornitore.find(id).calcola_residuo()
    end
    
    def search_maxi_pagamenti()
      MaxiPagamentoFornitore.search(:all, :include => [:tipo_pagamento, :pagamenti_fattura_fornitore], :conditions => ["chiuso = ?", 0], :order => 'maxi_pagamenti_fornitori.id').collect { |maxi_pagamento| maxi_pagamento.calcola_residuo() }
    end

    def save_maxi_pagamento()
      maxi_pagamento.save!
    end

    def riapri_maxi_pagamento(maxi_pagamento)
      # reimposto il flag chiuso del maxi_pagamento a 0
      maxi_pagamento.update_attribute(:chiuso,  0)

    end

    def delete_maxi_pagamento()
      maxi_pagamento.destroy
    end

    # GESTIONE TIPI PAGAMENTO
    
    def save_incasso()
      incasso.save!
    end
    
    def delete_incasso()
      incasso.destroy
    end
    
    def save_pagamento()
      pagamento.save!
    end
    
    def delete_pagamento()
      pagamento.destroy
    end

    # GESTIONE RIGHE FATTURA PDC

    def search_righe_fattura_pdc_fornitori(fattura)
      RigaFatturaPdc.search(:all, :conditions => ["fattura_fornitore_id = ?", fattura])
    end

    def search_righe_fattura_pdc_clienti(fattura)
      RigaFatturaPdc.search(:all, :conditions => ["fattura_cliente_id = ?", fattura])
    end

    def salva_righe_fattura_pdc_cliente(fattura)
      unless self.righe_fattura_pdc.blank?
        self.righe_fattura_pdc.each do |pdc|
          case pdc.instance_status
          when RigaFatturaPdc::ST_INSERT
            # associo l'id della fattura cliente alla riga
            pdc.fattura_cliente = fattura
            pdc.save!
          when RigaFatturaPdc::ST_UPDATE
            pdc.save!
          when RigaFatturaPdc::ST_DELETE
            pdc.destroy
          end
        end
      end
    end

    def salva_righe_fattura_pdc_fornitore(fattura)
      unless self.righe_fattura_pdc.blank?
        self.righe_fattura_pdc.each do |pdc|
          case pdc.instance_status
          when RigaFatturaPdc::ST_INSERT
            # associo l'id della fattura fornitore alla riga
            pdc.fattura_fornitore = fattura
            pdc.save!
          when RigaFatturaPdc::ST_UPDATE
            pdc.save!
          when RigaFatturaPdc::ST_DELETE
            pdc.destroy
          end
        end
      end
    end

    ###### GESTIONE PAGAMENTI IN SOSPESO ######

    def salva_incassi_in_sospeso()
      begin
        Scrittura.transaction do
          unless @@incassi.nil?
            @@incassi.each do |incasso|
              pagamento = PagamentoFatturaCliente.find(incasso.id, :include => [:fattura_cliente, :maxi_pagamento_cliente, :tipo_pagamento])

              if pagamento.tipo_pagamento && pagamento.tipo_pagamento.valid?
                logger.debug("maxi pagamento id: " + pagamento.maxi_pagamento_cliente_id.to_s)
                if pagamento.maxi_pagamento_cliente_id.nil?
                  descrizione = build_descrizione_pagamento_fattura_cliente(pagamento, pagamento.fattura_cliente.nota_di_credito?)
                  if scrittura = scrittura_prima_nota(pagamento.fattura_cliente, pagamento, descrizione)
                    relazione_pagamento_scrittura_prima_nota(scrittura, pagamento)
                  end
                else
                  # se si tratta di un pagamento in sospeso multiplo
                  # aggiorno il pagamento con i dati sul db
                  pagamento.reload()
                  # verifico che non sia gi� stato registrato in prima nota
                  unless pagamento.registrato_in_prima_nota?
                    # sommo tutti i pagamenti cliente con maxi_pagamento_cliente_id = pagamento.id
                    # se la somma è >= maxi_pagamento_cliente associato al pagamento
                    # costruisco la descrizione multipla, registro in prima nota e chiudo il maxi pagamento
                    #sql = QueryHelper.totale_pagamenti_multipli_cliente_query_string(pagamento.maxi_pagamento_cliente_id)
                    #totale_pagamenti_multipli = MaxiPagamentoCliente.find_by_sql(sql)[0][:totale_pagamenti_multipli].to_f
                    totale_pagamenti_multipli = PagamentoFatturaCliente.sum(:importo, :conditions => ["maxi_pagamento_cliente_id = ?", pagamento.maxi_pagamento_cliente_id])
                    # DA TESTARE
                    if(Helpers::ApplicationHelper.real(totale_pagamenti_multipli) >= Helpers::ApplicationHelper.real(pagamento.maxi_pagamento_cliente.importo))
                      descrizione = build_descrizione_multipla_pagamento_fattura_cliente(pagamento, pagamento.fattura_cliente.nota_di_credito?)
                      if scrittura = scrittura_multipla_prima_nota(pagamento.fattura_cliente, pagamento.maxi_pagamento_cliente, descrizione)
                        relazione_multipla_pagamento_scrittura_prima_nota(scrittura, pagamento)
                      end
                    end
                  end
                end
              end

            end
          end
        end # end transaction

      rescue ActiveRecord::RecordInvalid => err
        logger.error("Errore: #{err.message}")
      end

    end

    def salva_pagamenti_in_sospeso()
      begin
        Scrittura.transaction do
          unless @@pagamenti.nil?
            @@pagamenti.each do |pagamento|
              pagamento = PagamentoFatturaFornitore.find(pagamento.id, :include => [:fattura_fornitore, :maxi_pagamento_fornitore, :tipo_pagamento])

              if pagamento.tipo_pagamento && pagamento.tipo_pagamento.valid?
                if pagamento.maxi_pagamento_fornitore_id.nil?
                  descrizione = build_descrizione_pagamento_fattura_fornitore(pagamento, pagamento.fattura_fornitore.nota_di_credito?)
                  if scrittura = scrittura_prima_nota(pagamento.fattura_fornitore, pagamento, descrizione)
                    relazione_pagamento_scrittura_prima_nota(scrittura, pagamento)
                  end
                else
                  # se si tratta di un pagamento in sospeso multiplo
                  # aggiorno il pagamento con i dati sul db
                  pagamento.reload()
                  # verifico che non sia gi� stato registrato in prima nota
                  unless pagamento.registrato_in_prima_nota?
                    # sommo tutti i pagamenti fornitore con maxi_pagamento_fornitore_id = pagamento.id
                    # se la somma è >= maxi_pagamento_fornitore associato al pagamento
                    # costruisco la descrizione multipla, registro in prima nota e chiudo il maxi pagamento
                    #sql = QueryHelper.totale_pagamenti_multipli_fornitore_query_string(pagamento.maxi_pagamento_fornitore_id)
                    #totale_pagamenti_multipli = MaxiPagamentoFornitore.find_by_sql(sql)[0][:totale_pagamenti_multipli].to_f
                    totale_pagamenti_multipli = PagamentoFatturaFornitore.sum(:importo, :conditions => ["maxi_pagamento_fornitore_id = ?", pagamento.maxi_pagamento_fornitore_id])
                    # DA TESTARE
                    if(Helpers::ApplicationHelper.real(totale_pagamenti_multipli) >= Helpers::ApplicationHelper.real(pagamento.maxi_pagamento_fornitore.importo))
                      descrizione = build_descrizione_multipla_pagamento_fattura_fornitore(pagamento, pagamento.fattura_fornitore.nota_di_credito?)
                      if scrittura = scrittura_multipla_prima_nota(pagamento.fattura_fornitore, pagamento.maxi_pagamento_fornitore, descrizione)
                        relazione_multipla_pagamento_scrittura_prima_nota(scrittura, pagamento)
                      end
                    end
                  end
                end
              end

            end # end each
          end
        end # end transaction

      rescue ActiveRecord::RecordInvalid => err
        logger.error("Errore: #{err.message}")
      end

    end

    private
    
    def build_descrizione_pagamento_fattura_cliente(pagamento, nota_di_credito)
      descrizione = ""
      if(nota_di_credito)
        descrizione << "Pag. N.C. "
      else
        descrizione << "Inc. Fatt. "
      end

      descrizione  << pagamento.fattura_cliente.cliente.denominazione 
      descrizione << " n. " << pagamento.fattura_cliente.num 
      descrizione << " del " << pagamento.fattura_cliente.data_emissione.to_s(:italian_date)
      descrizione << " " << pagamento.tipo_pagamento.descrizione
      descrizione << " " << pagamento.note
      descrizione << " " << pagamento.banca.descrizione if pagamento.banca

      descrizione

    end

    def build_descrizione_pagamento_fattura_fornitore(pagamento, nota_di_credito)
      descrizione = ""
      if(nota_di_credito)
        descrizione << "Inc. N.C. "
      else
        descrizione << "Pag. Fatt. "
      end

      descrizione  << pagamento.fattura_fornitore.fornitore.denominazione 
      descrizione << " n. " << pagamento.fattura_fornitore.num 
      descrizione << " del " << pagamento.fattura_fornitore.data_emissione.to_s(:italian_date)
      descrizione << " " << pagamento.tipo_pagamento.descrizione
      descrizione << " " << pagamento.note
      descrizione << " " << pagamento.banca.descrizione if pagamento.banca

      descrizione

    end

    # STORNO SCRITTURA CLIENTE
    def build_descrizione_storno_pagamento_fattura_cliente(pagamento, nota_di_credito)
      descrizione = ""
      if(nota_di_credito)
        descrizione << "** STORNO SCRITTURA del #{pagamento.data_pagamento.to_s(:italian_date)} ** Pag. N.C. "
      else
        descrizione << "** STORNO SCRITTURA del #{pagamento.data_pagamento.to_s(:italian_date)} ** Inc. Fatt. "
      end

      descrizione  << pagamento.fattura_cliente.cliente.denominazione 
      descrizione << " n. " << pagamento.fattura_cliente.num 
      descrizione << " del " << pagamento.fattura_cliente.data_emissione.to_s(:italian_date)
      descrizione << " " << pagamento.tipo_pagamento.descrizione
      descrizione << " " << pagamento.note

      descrizione

    end

    # STORNO SCRITTURA FORNITORE
    def build_descrizione_storno_pagamento_fattura_fornitore(pagamento, nota_di_credito)
      descrizione = ""
      if(nota_di_credito)
        descrizione << "** STORNO SCRITTURA del #{pagamento.data_pagamento.to_s(:italian_date)} ** Inc. N.C. "
      else
        descrizione << "** STORNO SCRITTURA del #{pagamento.data_pagamento.to_s(:italian_date)} ** Pag. Fatt."
      end

      descrizione  << pagamento.fattura_fornitore.fornitore.denominazione 
      descrizione << " n. " << pagamento.fattura_fornitore.num 
      descrizione << " del " << pagamento.fattura_fornitore.data_emissione.to_s(:italian_date)
      descrizione << " " << pagamento.tipo_pagamento.descrizione
      descrizione << " " << pagamento.note

      descrizione

    end

    def build_descrizione_multipla_pagamento_fattura_cliente(pagamento, nota_di_credito)
      descrizione = ""
      if(nota_di_credito)
        descrizione << "Pag. N.C. "
      else
        descrizione << "Inc. Fatt. "
      end

      pagamenti_multipli = PagamentoFatturaCliente.find(:all, :include => [:fattura_cliente], :conditions => ["maxi_pagamento_cliente_id = ?", pagamento.maxi_pagamento_cliente_id])

      pagamenti_multipli.each do |pm|
        descrizione  << " " << pm.fattura_cliente.cliente.denominazione 
        descrizione << " n. " << pm.fattura_cliente.num 
        descrizione << " del " << pm.fattura_cliente.data_emissione.to_s(:italian_date)
      end

      descrizione << " " << pagamento.tipo_pagamento.descrizione
      descrizione << " " << pagamento.note

      descrizione

    end

    def build_descrizione_multipla_pagamento_fattura_fornitore(pagamento, nota_di_credito)
      descrizione = ""
      if(nota_di_credito)
        descrizione << "Inc. N.C. "
      else
        descrizione << "Pag. Fatt. "
      end

      pagamenti_multipli = PagamentoFatturaFornitore.find(:all, :include => [:fattura_fornitore], :conditions => ["maxi_pagamento_fornitore_id = ?", pagamento.maxi_pagamento_fornitore_id])

      pagamenti_multipli.each do |pm|
        descrizione  << " " << pm.fattura_fornitore.fornitore.denominazione 
        descrizione << " n. " << pm.fattura_fornitore.num 
        descrizione << " del " << pm.fattura_fornitore.data_emissione.to_s(:italian_date)
      end

      descrizione << " " << pagamento.tipo_pagamento.descrizione
      descrizione << " " << pagamento.note

      descrizione

    end

    def build_descrizione_multipla_storno_pagamento_fattura_cliente(pagamento, nota_di_credito)
      descrizione = ""
      if(nota_di_credito)
        descrizione << "** STORNO SCRITTURA del #{pagamento.data_pagamento.to_s(:italian_date)} ** Pag. N.C. "
      else
        descrizione << "** STORNO SCRITTURA del #{pagamento.data_pagamento.to_s(:italian_date)} ** Inc. Fatt. "
      end

      pagamenti_multipli = PagamentoFatturaCliente.find(:all, :include => [:fattura_cliente], :conditions => ["maxi_pagamento_cliente_id = ?", pagamento.maxi_pagamento_cliente_id])

      pagamenti_multipli.each do |pm|
        descrizione  << " " << pm.fattura_cliente.cliente.denominazione 
        descrizione << " n. " << pm.fattura_cliente.num 
        descrizione << " del " << pm.fattura_cliente.data_emissione.to_s(:italian_date)
      end

      descrizione << " " << pagamento.tipo_pagamento.descrizione
      descrizione << " " << pagamento.note

      descrizione

    end

    def build_descrizione_multipla_storno_pagamento_fattura_fornitore(pagamento, nota_di_credito)
      descrizione = ""
      if(nota_di_credito)
        descrizione << "** STORNO SCRITTURA del #{pagamento.data_pagamento.to_s(:italian_date)} ** Inc. N.C. "
      else
        descrizione << "** STORNO SCRITTURA del #{pagamento.data_pagamento.to_s(:italian_date)} ** Pag. Fatt. "
      end

      pagamenti_multipli = PagamentoFatturaFornitore.find(:all, :include => [:fattura_fornitore], :conditions => ["maxi_pagamento_fornitore_id = ?", pagamento.maxi_pagamento_fornitore_id])

      pagamenti_multipli.each do |pm|
        descrizione  << " " << pm.fattura_fornitore.fornitore.denominazione 
        descrizione << " n. " << pm.fattura_fornitore.num 
        descrizione << " del " << pm.fattura_fornitore.data_emissione.to_s(:italian_date)
      end

      descrizione << " " << pagamento.tipo_pagamento.descrizione
      descrizione << " " << pagamento.note

      descrizione

    end

    def scrittura_prima_nota(fattura, pagamento, descrizione)
      logger.debug("tipo pagamento: " + pagamento.tipo_pagamento.descrizione)
      logger.debug("descrizione: " + descrizione)
      logger.debug("nota_di_credito: " + fattura.nota_di_credito?.to_s)

      scrittura = Scrittura.new(:azienda => Azienda.current,
                                :banca => pagamento.banca,
                                :descrizione => descrizione,
                                :data_operazione => pagamento.data_pagamento,
                                :data_registrazione => Time.now,
                                :esterna => 1,
                                :congelata => 0)

      if(fattura.nota_di_credito?)
        if (pagamento.tipo_pagamento.nc_cassa_dare? ||
            pagamento.tipo_pagamento.nc_cassa_avere? ||
            pagamento.tipo_pagamento.nc_banca_dare? ||
            pagamento.tipo_pagamento.nc_banca_avere? ||
            pagamento.tipo_pagamento.nc_fuori_partita_dare? ||
            pagamento.tipo_pagamento.nc_fuori_partita_avere?)

          scrittura.cassa_dare = pagamento.importo if pagamento.tipo_pagamento.nc_cassa_dare?
          scrittura.cassa_avere = pagamento.importo if pagamento.tipo_pagamento.nc_cassa_avere?
          scrittura.banca_dare = pagamento.importo if pagamento.tipo_pagamento.nc_banca_dare?
          scrittura.banca_avere = pagamento.importo if pagamento.tipo_pagamento.nc_banca_avere?
          scrittura.fuori_partita_dare = pagamento.importo if pagamento.tipo_pagamento.nc_fuori_partita_dare?
          scrittura.fuori_partita_avere = pagamento.importo if pagamento.tipo_pagamento.nc_fuori_partita_avere?

          if configatron.bilancio.attivo
            if pagamento.kind_of? Models::PagamentoFatturaCliente
              scrittura.pdc_dare = pagamento.tipo_pagamento.pdc_dare
              scrittura.pdc_avere = pagamento.tipo_pagamento.pdc_avere || fattura.cliente.conto
            else
              scrittura.pdc_dare = pagamento.tipo_pagamento.pdc_dare || fattura.fornitore.conto
              scrittura.pdc_avere = pagamento.tipo_pagamento.pdc_avere
            end
          end

          scrittura.save_with_validation(false)
          pagamento.update_attributes(:registrato_in_prima_nota => 1)

          scritture = search_scritture()
          notify(:evt_prima_nota_changed, scritture)
          
        else
          scrittura = nil
        end      
      else
        if (pagamento.tipo_pagamento.cassa_dare? ||
            pagamento.tipo_pagamento.cassa_avere? ||
            pagamento.tipo_pagamento.banca_dare? ||
            pagamento.tipo_pagamento.banca_avere? ||
            pagamento.tipo_pagamento.fuori_partita_dare? ||
            pagamento.tipo_pagamento.fuori_partita_avere?)

          scrittura.cassa_dare = pagamento.importo if pagamento.tipo_pagamento.cassa_dare?
          scrittura.cassa_avere = pagamento.importo if pagamento.tipo_pagamento.cassa_avere?
          scrittura.banca_dare = pagamento.importo if pagamento.tipo_pagamento.banca_dare?
          scrittura.banca_avere = pagamento.importo if pagamento.tipo_pagamento.banca_avere?
          scrittura.fuori_partita_dare = pagamento.importo if pagamento.tipo_pagamento.fuori_partita_dare?
          scrittura.fuori_partita_avere = pagamento.importo if pagamento.tipo_pagamento.fuori_partita_avere?

          if configatron.bilancio.attivo
            if pagamento.kind_of? Models::PagamentoFatturaCliente
              scrittura.pdc_dare = pagamento.tipo_pagamento.pdc_dare
              scrittura.pdc_avere = pagamento.tipo_pagamento.pdc_avere || fattura.cliente.conto
            else
              scrittura.pdc_dare = pagamento.tipo_pagamento.pdc_dare || fattura.fornitore.conto
              scrittura.pdc_avere = pagamento.tipo_pagamento.pdc_avere
            end
          end

          scrittura.save_with_validation(false)
          pagamento.update_attributes(:registrato_in_prima_nota => 1)

          scritture = search_scritture()
          notify(:evt_prima_nota_changed, scritture)
          
        else
          scrittura = nil
        end      
      end

      scrittura

    end

    def storno_scrittura_prima_nota(fattura, pagamento, descrizione)
      logger.debug("tipo pagamento: " + pagamento.tipo_pagamento.descrizione)
      logger.debug("descrizione: " + descrizione)
      logger.debug("nota_di_credito: " + fattura.nota_di_credito?.to_s)

      scrittura = Scrittura.new(:azienda => Azienda.current,
                                :banca => pagamento.banca,
                                :descrizione => descrizione,
                                :data_operazione => Date.today,
                                :data_registrazione => Time.now,
                                :esterna => 1,
                                :congelata => 0)

      negativo = (pagamento.importo * -1)

      if(fattura.nota_di_credito?)
        if (pagamento.tipo_pagamento.nc_cassa_dare? ||
            pagamento.tipo_pagamento.nc_cassa_avere? ||
            pagamento.tipo_pagamento.nc_banca_dare? ||
            pagamento.tipo_pagamento.nc_banca_avere? ||
            pagamento.tipo_pagamento.nc_fuori_partita_dare? ||
            pagamento.tipo_pagamento.nc_fuori_partita_avere?)

          scrittura.cassa_dare = negativo if pagamento.tipo_pagamento.nc_cassa_dare?
          scrittura.cassa_avere = negativo if pagamento.tipo_pagamento.nc_cassa_avere?
          scrittura.banca_dare = negativo if pagamento.tipo_pagamento.nc_banca_dare?
          scrittura.banca_avere = negativo if pagamento.tipo_pagamento.nc_banca_avere?
          scrittura.fuori_partita_dare = negativo if pagamento.tipo_pagamento.nc_fuori_partita_dare?
          scrittura.fuori_partita_avere = negativo if pagamento.tipo_pagamento.nc_fuori_partita_avere?

          scrittura.parent = pagamento.scrittura
          
          if configatron.bilancio.attivo
            if pagamento.kind_of? Models::PagamentoFatturaCliente
              scrittura.pdc_dare = pagamento.tipo_pagamento.pdc_dare
              scrittura.pdc_avere = pagamento.tipo_pagamento.pdc_avere || fattura.cliente.conto
            else
              scrittura.pdc_dare = pagamento.tipo_pagamento.pdc_dare || fattura.fornitore.conto
              scrittura.pdc_avere = pagamento.tipo_pagamento.pdc_avere
            end
          end

          scrittura.save_with_validation(false)
          pagamento.update_attributes(:registrato_in_prima_nota => 1)

          scritture = search_scritture()
          notify(:evt_prima_nota_changed, scritture)
          
        end      
      else
        if (pagamento.tipo_pagamento.cassa_dare? ||
            pagamento.tipo_pagamento.cassa_avere? ||
            pagamento.tipo_pagamento.banca_dare? ||
            pagamento.tipo_pagamento.banca_avere? ||
            pagamento.tipo_pagamento.fuori_partita_dare? ||
            pagamento.tipo_pagamento.fuori_partita_avere?)

          scrittura.cassa_dare = negativo if pagamento.tipo_pagamento.cassa_dare?
          scrittura.cassa_avere = negativo if pagamento.tipo_pagamento.cassa_avere?
          scrittura.banca_dare = negativo if pagamento.tipo_pagamento.banca_dare?
          scrittura.banca_avere = negativo if pagamento.tipo_pagamento.banca_avere?
          scrittura.fuori_partita_dare = negativo if pagamento.tipo_pagamento.fuori_partita_dare?
          scrittura.fuori_partita_avere = negativo if pagamento.tipo_pagamento.fuori_partita_avere?

          scrittura.parent = pagamento.scrittura

          if configatron.bilancio.attivo
            if pagamento.kind_of? Models::PagamentoFatturaCliente
              scrittura.pdc_dare = pagamento.tipo_pagamento.pdc_dare
              scrittura.pdc_avere = pagamento.tipo_pagamento.pdc_avere || fattura.cliente.conto
            else
              scrittura.pdc_dare = pagamento.tipo_pagamento.pdc_dare || fattura.fornitore.conto
              scrittura.pdc_avere = pagamento.tipo_pagamento.pdc_avere
            end
          end

          scrittura.save_with_validation(false)
          pagamento.update_attributes(:registrato_in_prima_nota => 1)

          scritture = search_scritture()
          notify(:evt_prima_nota_changed, scritture)
          
        end      
      end

      scrittura

    end

    def relazione_pagamento_scrittura_prima_nota(scrittura, pagamento)
      if pagamento.kind_of? PagamentoFatturaCliente
        PagamentoPrimaNota.create(:prima_nota_id => scrittura.id,
                                  :pagamento_fattura_cliente_id => pagamento.id)
      else
        PagamentoPrimaNota.create(:prima_nota_id => scrittura.id,
                                  :pagamento_fattura_fornitore_id => pagamento.id)

      end
    end

    def scrittura_multipla_prima_nota(fattura, maxi_pagamento, descrizione)
      logger.debug("tipo maxi_pagamento: " + maxi_pagamento.tipo_pagamento.descrizione)
      logger.debug("descrizione: " + descrizione)
      logger.debug("nota_di_credito: " + fattura.nota_di_credito?.to_s)

      scrittura = Scrittura.new(:azienda => Azienda.current,
                                :banca => maxi_pagamento.banca,
                                :descrizione => descrizione,
                                :data_operazione => maxi_pagamento.data_pagamento,
                                :data_registrazione => Time.now,
                                :esterna => 1,
                                :congelata => 0)

      if(fattura.nota_di_credito?)
        if (maxi_pagamento.tipo_pagamento.nc_cassa_dare? ||
            maxi_pagamento.tipo_pagamento.nc_cassa_avere? ||
            maxi_pagamento.tipo_pagamento.nc_banca_dare? ||
            maxi_pagamento.tipo_pagamento.nc_banca_avere? ||
            maxi_pagamento.tipo_pagamento.nc_fuori_partita_dare? ||
            maxi_pagamento.tipo_pagamento.nc_fuori_partita_avere?)

          scrittura.cassa_dare = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.nc_cassa_dare?
          scrittura.cassa_avere = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.nc_cassa_avere?
          scrittura.banca_dare = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.nc_banca_dare?
          scrittura.banca_avere = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.nc_banca_avere?
          scrittura.fuori_partita_dare = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.nc_fuori_partita_dare?
          scrittura.fuori_partita_avere = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.nc_fuori_partita_avere?

          if configatron.bilancio.attivo
            if maxi_pagamento.kind_of? MaxiPagamentoCliente
              scrittura.pdc_dare = maxi_pagamento.tipo_pagamento.pdc_dare
              scrittura.pdc_avere = maxi_pagamento.tipo_pagamento.pdc_avere || fattura.cliente.conto
            else
              scrittura.pdc_dare = maxi_pagamento.tipo_pagamento.pdc_dare || fattura.fornitore.conto
              scrittura.pdc_avere = maxi_pagamento.tipo_pagamento.pdc_avere
            end
          end

          scrittura.save_with_validation(false)
          #pagamento.update_attributes(:registrato_in_prima_nota => 1)
          if(maxi_pagamento.kind_of? MaxiPagamentoCliente)
            PagamentoFatturaCliente.update_all(["registrato_in_prima_nota = ?", 1], ["maxi_pagamento_cliente_id = ?", maxi_pagamento.id])
          elsif(maxi_pagamento.kind_of? MaxiPagamentoFornitore)
            PagamentoFatturaFornitore.update_all(["registrato_in_prima_nota = ?", 1], ["maxi_pagamento_fornitore_id = ?", maxi_pagamento.id])
          end
          maxi_pagamento.update_attributes(:chiuso => 1)

          scritture = search_scritture()
          notify(:evt_prima_nota_changed, scritture)
          
        else
          scrittura = nil
        end      
      else
        if (maxi_pagamento.tipo_pagamento.cassa_dare? ||
            maxi_pagamento.tipo_pagamento.cassa_avere? ||
            maxi_pagamento.tipo_pagamento.banca_dare? ||
            maxi_pagamento.tipo_pagamento.banca_avere? ||
            maxi_pagamento.tipo_pagamento.fuori_partita_dare? ||
            maxi_pagamento.tipo_pagamento.fuori_partita_avere?)

          scrittura.cassa_dare = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.cassa_dare?
          scrittura.cassa_avere = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.cassa_avere?
          scrittura.banca_dare = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.banca_dare?
          scrittura.banca_avere = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.banca_avere?
          scrittura.fuori_partita_dare = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.fuori_partita_dare?
          scrittura.fuori_partita_avere = maxi_pagamento.importo if maxi_pagamento.tipo_pagamento.fuori_partita_avere?

          if configatron.bilancio.attivo
            if maxi_pagamento.kind_of? MaxiPagamentoCliente
              scrittura.pdc_dare = maxi_pagamento.tipo_pagamento.pdc_dare
              scrittura.pdc_avere = maxi_pagamento.tipo_pagamento.pdc_avere || fattura.cliente.conto
            else
              scrittura.pdc_dare = maxi_pagamento.tipo_pagamento.pdc_dare || fattura.fornitore.conto
              scrittura.pdc_avere = maxi_pagamento.tipo_pagamento.pdc_avere
            end
          end

          scrittura.save_with_validation(false)
          #pagamento.update_attributes(:registrato_in_prima_nota => 1)
          logger.debug("maxi pagamento: " + maxi_pagamento.inspect)
          if(maxi_pagamento.kind_of? MaxiPagamentoCliente)
            PagamentoFatturaCliente.update_all(["registrato_in_prima_nota = ?", 1], ["maxi_pagamento_cliente_id = ?", maxi_pagamento.id])
          elsif(maxi_pagamento.kind_of? MaxiPagamentoFornitore)
            PagamentoFatturaFornitore.update_all(["registrato_in_prima_nota = ?", 1], ["maxi_pagamento_fornitore_id = ?", maxi_pagamento.id])
          end
          maxi_pagamento.update_attributes(:chiuso => 1)

          scritture = search_scritture()
          notify(:evt_prima_nota_changed, scritture)
          
        else
          scrittura = nil
        end      
      end

      scrittura

    end

    def storno_scrittura_multipla_prima_nota(fattura, old_scrittura, maxi_pagamento, descrizione)
      logger.debug("tipo maxi_pagamento: " + maxi_pagamento.tipo_pagamento.descrizione)
      logger.debug("descrizione: " + descrizione)
      logger.debug("nota_di_credito: " + fattura.nota_di_credito?.to_s)

      scrittura = Scrittura.new(:azienda => Azienda.current,
                                :banca => maxi_pagamento.banca,
                                :descrizione => descrizione,
                                :data_operazione => Date.today,
                                :data_registrazione => Time.now,
                                :esterna => 1,
                                :congelata => 0)

      negativo = (maxi_pagamento.importo * -1)

      if(fattura.nota_di_credito?)
        if (maxi_pagamento.tipo_pagamento.nc_cassa_dare? ||
            maxi_pagamento.tipo_pagamento.nc_cassa_avere? ||
            maxi_pagamento.tipo_pagamento.nc_banca_dare? ||
            maxi_pagamento.tipo_pagamento.nc_banca_avere? ||
            maxi_pagamento.tipo_pagamento.nc_fuori_partita_dare? ||
            maxi_pagamento.tipo_pagamento.nc_fuori_partita_avere?)

          scrittura.cassa_dare = negativo if maxi_pagamento.tipo_pagamento.nc_cassa_dare?
          scrittura.cassa_avere = negativo if maxi_pagamento.tipo_pagamento.nc_cassa_avere?
          scrittura.banca_dare = negativo if maxi_pagamento.tipo_pagamento.nc_banca_dare?
          scrittura.banca_avere = negativo if maxi_pagamento.tipo_pagamento.nc_banca_avere?
          scrittura.fuori_partita_dare = negativo if maxi_pagamento.tipo_pagamento.nc_fuori_partita_dare?
          scrittura.fuori_partita_avere = negativo if maxi_pagamento.tipo_pagamento.nc_fuori_partita_avere?

          scrittura.parent = old_scrittura

          if configatron.bilancio.attivo
            if maxi_pagamento.kind_of? MaxiPagamentoCliente
              scrittura.pdc_dare = maxi_pagamento.tipo_pagamento.pdc_dare
              scrittura.pdc_avere = maxi_pagamento.tipo_pagamento.pdc_avere || fattura.cliente.conto
            else
              scrittura.pdc_dare = maxi_pagamento.tipo_pagamento.pdc_dare || fattura.fornitore.conto
              scrittura.pdc_avere = maxi_pagamento.tipo_pagamento.pdc_avere
            end
          end

          scrittura.save_with_validation(false)
          #pagamento.update_attributes(:registrato_in_prima_nota => 1)
          if(maxi_pagamento.kind_of? MaxiPagamentoCliente)
            PagamentoFatturaCliente.update_all(["registrato_in_prima_nota = ?", 0], ["maxi_pagamento_cliente_id = ?", maxi_pagamento.id])
          elsif(maxi_pagamento.kind_of? MaxiPagamentoFornitore)
            PagamentoFatturaFornitore.update_all(["registrato_in_prima_nota = ?", 0], ["maxi_pagamento_fornitore_id = ?", maxi_pagamento.id])
          end
          maxi_pagamento.update_attributes(:chiuso => 0)

          scritture = search_scritture()
          notify(:evt_prima_nota_changed, scritture)
          
        else
          scrittura = nil
        end      
      else
        if (maxi_pagamento.tipo_pagamento.cassa_dare? ||
            maxi_pagamento.tipo_pagamento.cassa_avere? ||
            maxi_pagamento.tipo_pagamento.banca_dare? ||
            maxi_pagamento.tipo_pagamento.banca_avere? ||
            maxi_pagamento.tipo_pagamento.fuori_partita_dare? ||
            maxi_pagamento.tipo_pagamento.fuori_partita_avere?)

          scrittura.cassa_dare = negativo if maxi_pagamento.tipo_pagamento.cassa_dare?
          scrittura.cassa_avere = negativo if maxi_pagamento.tipo_pagamento.cassa_avere?
          scrittura.banca_dare = negativo if maxi_pagamento.tipo_pagamento.banca_dare?
          scrittura.banca_avere = negativo if maxi_pagamento.tipo_pagamento.banca_avere?
          scrittura.fuori_partita_dare = negativo if maxi_pagamento.tipo_pagamento.fuori_partita_dare?
          scrittura.fuori_partita_avere = negativo if maxi_pagamento.tipo_pagamento.fuori_partita_avere?

          scrittura.parent = old_scrittura

          if configatron.bilancio.attivo
            if maxi_pagamento.kind_of? MaxiPagamentoCliente
              scrittura.pdc_dare = maxi_pagamento.tipo_pagamento.pdc_dare
              scrittura.pdc_avere = maxi_pagamento.tipo_pagamento.pdc_avere || fattura.cliente.conto
            else
              scrittura.pdc_dare = maxi_pagamento.tipo_pagamento.pdc_dare || fattura.fornitore.conto
              scrittura.pdc_avere = maxi_pagamento.tipo_pagamento.pdc_avere
            end
          end

          scrittura.save_with_validation(false)
          #pagamento.update_attributes(:registrato_in_prima_nota => 1)
          logger.debug("maxi pagamento: " + maxi_pagamento.inspect)
          if(maxi_pagamento.kind_of? MaxiPagamentoCliente)
            PagamentoFatturaCliente.update_all(["registrato_in_prima_nota = ?", 0], ["maxi_pagamento_cliente_id = ?", maxi_pagamento.id])
          elsif(maxi_pagamento.kind_of? MaxiPagamentoFornitore)
            PagamentoFatturaFornitore.update_all(["registrato_in_prima_nota = ?", 0], ["maxi_pagamento_fornitore_id = ?", maxi_pagamento.id])
          end
          maxi_pagamento.update_attributes(:chiuso => 0)

          scritture = search_scritture()
          notify(:evt_prima_nota_changed, scritture)
          
        end      
      end

      scrittura

    end

    def relazione_multipla_pagamento_scrittura_prima_nota(scrittura, pagamento)
      if pagamento.kind_of? PagamentoFatturaCliente
        pagamenti_multipli = PagamentoFatturaCliente.find(:all, :conditions => ["maxi_pagamento_cliente_id = ?", pagamento.maxi_pagamento_cliente_id])

        pagamenti_multipli.each do |pm|
          PagamentoPrimaNota.create(:prima_nota_id => scrittura.id,
                                    :pagamento_fattura_cliente_id => pm.id,
                                    :maxi_pagamento_cliente_id => pagamento.maxi_pagamento_cliente_id)
        end
      else
        pagamenti_multipli = PagamentoFatturaFornitore.find(:all, :conditions => ["maxi_pagamento_fornitore_id = ?", pagamento.maxi_pagamento_fornitore_id])

        pagamenti_multipli.each do |pm|
          PagamentoPrimaNota.create(:prima_nota_id => scrittura.id,
                                    :pagamento_fattura_fornitore_id => pm.id,
                                    :maxi_pagamento_fornitore_id => pagamento.maxi_pagamento_fornitore_id)
        end
      end
    end

  end
end