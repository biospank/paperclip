# encoding: utf-8

module Controllers
  module FatturazioneController
    include Controllers::BaseController
    
    # gestione nota spese

    def load_nota_spese(id)
      NotaSpese.find(id)
    end
    
    def save_nota_spese()
      righe = ns_righe_fattura_panel.result_set_lstrep_righe_nota_spese

      NotaSpese.transaction do
        nota_spese.save!

        ProgressivoNotaSpese.aggiorna_progressivo(nota_spese) if nota_spese.num.match(/^[0-9]*$/) 

        righe.each do |riga|
          case riga.instance_status
          when RigaNotaSpese::ST_INSERT
            # associo l'id della nota_spese alla riga
            riga.nota_spese = nota_spese
            riga.save!
          when RigaNotaSpese::ST_UPDATE
            riga.save!
          when RigaNotaSpese::ST_DELETE
            riga.destroy
          end
        end

      end

      return true

    end

    def delete_nota_spese()
      nota_spese.destroy
    end

    def search_for_note_spese()
      NotaSpese.search_for(filtro.ricerca, [:num, 'clienti.denominazione'], build_note_spese_dialog_conditions())
    end

    def search_righe_nota_spese(ns)
      RigaNotaSpese.search(:all, :conditions => ['nota_spese_id = ?', ns], :include => [:aliquota], :order => 'righe_nota_spese.id')
    end

    def build_note_spese_dialog_conditions()
      query_str = []
      parametri = []
      
      filtro.build_conditions(query_str, parametri) if filtro
      
      {:conditions => [query_str.join(' AND '), *parametri], 
#        :joins => [:cliente], # produce una inner join, oppure
#        :joins => "LEFT OUTER JOIN clienti ON clienti.id = nota_spese.cliente_id,
        :include => [:cliente],
        :order => 'nota_spese.data_emissione desc, nota_spese.num desc'}
    end


    # gestione fattura cliente

    def load_fattura_cliente(id)
      FatturaClienteFatturazione.find(id)
    end
    
    def save_fattura_cliente()
      righe = righe_fattura_cliente_panel.result_set_lstrep_righe_fattura

      FatturaCliente.transaction do
        fattura_cliente.save!

        # Aggiorno eventuali note spese che sono entrate a far parte della fattura
        NotaSpese.update_all("fattura_cliente_id = #{fattura_cliente.id}", ["id in (?)", self.lista_ns]) unless self.lista_ns.empty?

        if fattura_cliente.nota_di_credito?
          ProgressivoNc.aggiorna_progressivo(fattura_cliente) if fattura_cliente.num.match(/^[0-9]*$/)
        else
          ProgressivoFatturaCliente.aggiorna_progressivo(fattura_cliente) if fattura_cliente.num.match(/^[0-9]*$/)
        end

        righe.each do |riga|
          case riga.instance_status
          when RigaFatturaCliente::ST_INSERT
            # associo l'id della nota_spese alla riga
            riga.fattura_cliente_id = fattura_cliente.id
            riga.save!
          when RigaFatturaCliente::ST_UPDATE
            riga.save!
          when RigaFatturaCliente::ST_DELETE
            riga.destroy
          end
        end

      end

      return true

    end

    def delete_fattura_cliente()
      FatturaCliente.transaction do
        NotaSpese.update_all("fattura_cliente_id = null", ["fattura_cliente_id = ?", fattura_cliente])
        fattura_cliente.destroy
      end
    end

    def search_for_fatture_clienti()
      FatturaCliente.search_for(filtro.ricerca, [:num, 'clienti.denominazione'], build_fatture_clienti_dialog_conditions())
    end

    # sta qua' perche non trova collocazione altrove
    def search_for_fatture_fornitori()
      FatturaFornitore.search_for(filtro.ricerca, [:num, 'fornitori.denominazione'], build_fatture_fornitori_dialog_conditions())
    end

    def build_fatture_clienti_dialog_conditions()
      query_str = []
      parametri = []
      
      filtro.build_conditions(query_str, parametri) if filtro
      
      {:conditions => [query_str.join(' AND '), *parametri], 
#        :joins => [:cliente], # produce una inner join, oppure
#        :joins => "LEFT OUTER JOIN clienti ON clienti.id = nota_spese.cliente_id,
        :include => [:cliente],
        :order => 'fatture_clienti.data_emissione desc, fatture_clienti.num desc'}
    end

    def build_fatture_fornitori_dialog_conditions()
      query_str = []
      parametri = []
      
      filtro.build_conditions(query_str, parametri) if filtro
      
      {:conditions => [query_str.join(' AND '), *parametri], 
#        :joins => [:cliente], # produce una inner join, oppure
#        :joins => "LEFT OUTER JOIN clienti ON clienti.id = nota_spese.cliente_id,
        :include => [:fornitore],
        :order => 'fatture_fornitori.data_emissione desc, fatture_fornitori.num desc'}
    end

    # gestione corrispettivi

    def save_corrispettivi()
      righe = righe_corrispettivi_panel.result_set_lstrep_righe_corrispettivi

      corrispettivi_da_eliminare = []

      righe.each do |riga|
        case riga.instance_status
        when Corrispettivo::ST_INSERT, Corrispettivo::ST_UPDATE
          riga.save!
        when Corrispettivo::ST_DELETE
          corrispettivi_da_eliminare << riga
        end
      end

      elimina_scritture_corrispettivi_partita_doppia(corrispettivi_da_eliminare) if configatron.bilancio.attivo
      elimina_corrispettivi(corrispettivi_da_eliminare)

      # le scritture che ho salvato devono essere immediatamente
      # registrate in prima nota
      # NOTA:
      # SQLite non gestisce le sessioni sul db, quindi, se questa procedura
      # viene spostata all'interno della transazione, non funziona.
      corrispettivi = Corrispettivo.find(:all, :conditions => ["registrato_in_prima_nota = ? ", 0])
      corrispettivi.each do |corrispettivo|
        descrizione = build_descrizione_scrittura_corrispettivo(corrispettivo)
        if scrittura = scrittura_corrispettivo(corrispettivo, descrizione)
          relazione_scrittura_corrispettivo(scrittura, corrispettivo)
        end
        if configatron.bilancio.attivo
          scrittura_corrispettivo_partita_doppia(corrispettivo)
        end
      end

      return true

    end

    def elimina_corrispettivi(corrispettivi_da_eliminare)
      corrispettivi_da_eliminare.each do |corrispettivo|
        if corrispettivo.registrato_in_prima_nota?
            # cerco la scrittura associata al corrispettivo
            if scrittura = corrispettivo.scrittura
              if scrittura.congelata?
                descrizione = build_descrizione_storno_scrittura_corrispettivo(corrispettivo)
                storno_scrittura_corrispettivo(corrispettivo, descrizione)
                CorrispettivoPrimaNota.delete_all("prima_nota_id = #{scrittura.id}")
              else
                  # il destroy direttamente su scrittura non funziona
                Models::Scrittura.find(scrittura).destroy
              end
            else
              descrizione = build_descrizione_storno_scrittura_corrispettivo(corrispettivo)
              storno_scrittura_corrispettivo(corrispettivo, descrizione)
            end
        end
        corrispettivo.destroy
      end

    end

    def elimina_scritture_corrispettivi_partita_doppia(corrispettivi_da_eliminare)
      corrispettivi_da_eliminare.each do |corrispettivo|
        delete_scrittura_corrispettivo_partita_doppia(corrispettivo)
      end
    end

    # SCRITTURA CORRISPETTIVO
    def build_descrizione_scrittura_corrispettivo(corrispettivo)
      "Incasso giornaliero corrispettivi del #{corrispettivo.data.to_s(:italian_date)}"
    end

    def scrittura_corrispettivo(corrispettivo, descrizione)
      scrittura = Scrittura.new(:azienda => Azienda.current,
                                :cassa_dare => corrispettivo.importo,
                                :banca => nil,
                                :descrizione => descrizione,
                                :data_operazione => corrispettivo.data,
                                :data_registrazione => Time.now,
                                :esterna => 1,
                                :congelata => 0)

      scrittura.save_with_validation(false)
      corrispettivo.update_attributes(:registrato_in_prima_nota => 1)

      scrittura

    end

    def scrittura_corrispettivo_partita_doppia(corrispettivo)

      conto_iva = Models::Pdc.find_by_codice('30000')

      importo = ScritturaPd.new(:azienda => Azienda.current,
                              :importo => corrispettivo.importo,
                              :descrizione => '',
                              :pdc_dare => corrispettivo.pdc_dare,
                              :data_operazione => corrispettivo.data,
                              :data_registrazione => Time.now,
                              :esterna => 1,
                              :congelata => 0)

      imponibile = ScritturaPd.new(:azienda => Azienda.current,
                              :importo => corrispettivo.imponibile,
                              :descrizione => '',
                              :pdc_avere => corrispettivo.pdc_avere,
                              :data_operazione => corrispettivo.data,
                              :data_registrazione => Time.now,
                              :esterna => 1,
                              :congelata => 0)

      iva = ScritturaPd.new(:azienda => Azienda.current,
                              :importo => corrispettivo.iva,
                              :descrizione => '',
                              :pdc_avere => conto_iva,
                              :data_operazione => corrispettivo.data,
                              :data_registrazione => Time.now,
                              :esterna => 1,
                              :congelata => 0)

      [importo, imponibile, iva].each do |scrittura|
        scrittura.save_with_validation(false)
        CorrispettivoPartitaDoppia.create(:partita_doppia_id => scrittura.id,
                                  :corrispettivo_id => corrispettivo.id)
      end

      corrispettivo.update_attributes(:registrato_in_partita_doppia => 1)

      scritture = search_scritture_pd()

      # TODO gestire la notifica evt_partita_doppia_changed
      notify(:evt_partita_doppia_changed, scritture)

    end

    def relazione_scrittura_corrispettivo(scrittura, corrispettivo)
      CorrispettivoPrimaNota.create(:prima_nota_id => scrittura.id,
                                :corrispettivo_id => corrispettivo.id)
    end

    # STORNO SCRITTURA CORRISPETTIVO
    def build_descrizione_storno_scrittura_corrispettivo(corrispettivo)
      "** STORNO SCRITTURA CORRISPETTIVI del #{corrispettivo.data.to_s(:italian_date)} **"
    end

    def storno_scrittura_corrispettivo(corrispettivo, descrizione)
      scrittura = Scrittura.new(:azienda => Azienda.current,
                                :cassa_avere => corrispettivo.importo,
                                :banca => nil,
                                :descrizione => descrizione,
                                :data_operazione => Date.today,
                                :data_registrazione => Time.now,
                                :esterna => 1,
                                :congelata => 0)

      scrittura.parent = corrispettivo.scrittura

      scrittura.save_with_validation(false)
      corrispettivo.update_attributes(:registrato_in_prima_nota => 1)

      scrittura

    end

    def delete_scrittura_corrispettivo_partita_doppia(corrispettivo)
      corrispettivi_pd = CorrispettivoPartitaDoppia.all(:conditions => "corrispettivo_id = #{corrispettivo.id}")
      corrispettivi_pd.each do |corrispettivo_pd|
        ScritturaPd.delete(corrispettivo_pd.partita_doppia_id)
        corrispettivo_pd.delete()
      end
    end

    def report_corrispettivi
      data_matrix = []

      corrispettivi = Corrispettivo.search(:all, build_corrispettivi_report_conditions())

      array_group_aliquote = corrispettivi.group_by(&:aliquota_id)

      if filtro.corrispettivi == 1
        corrispettivi.group_by(&:data).each do |data, corrrispettivi_data|

          dati_corrispettivi = []
          dati_corrispettivi << data.to_s(:italian_date)
          dati_corrispettivi << corrrispettivi_data.sum(&:importo)

          array_aliquota_corrispettivi = corrrispettivi_data.group_by(&:aliquota_id)
          array_group_aliquote.keys.sort.each do |chiave_aliquota|
            if corrispettivi_aliquota = array_aliquota_corrispettivi[chiave_aliquota]
              dati_corrispettivi << corrispettivi_aliquota.sum(&:importo)
            else
              dati_corrispettivi << '' # importo x aliquota
            end
          end

          data_matrix << dati_corrispettivi

        end

        totali = ['', corrispettivi.sum(&:importo)]
        array_group_aliquote.keys.sort.each do |chiave_aliquota|
          totali << array_group_aliquote[chiave_aliquota].sum(&:importo)
        end

        data_matrix << totali

      else
        corrispettivi.group_by(&:data).each do |data, corrrispettivi_data|

          dati_corrispettivi = []
          dati_corrispettivi << data.to_s(:italian_date)
          dati_corrispettivi << corrrispettivi_data.sum(&:importo)

          array_aliquota_corrispettivi = corrrispettivi_data.group_by(&:aliquota_id)
          array_group_aliquote.keys.sort.each do |chiave_aliquota|
            if corrispettivi_aliquota = array_aliquota_corrispettivi[chiave_aliquota]
              dati_corrispettivi << corrispettivi_aliquota.sum(&:imponibile)
              dati_corrispettivi << corrispettivi_aliquota.sum(&:iva)
            else
              dati_corrispettivi << '' # imponibile
              dati_corrispettivi << '' # iva
            end
          end

          data_matrix << dati_corrispettivi

        end

        totali = ['', corrispettivi.sum(&:importo)]
        array_group_aliquote.keys.sort.each do |chiave_aliquota|
          totali.concat([array_group_aliquote[chiave_aliquota].sum(&:imponibile),
            array_group_aliquote[chiave_aliquota].sum(&:iva)
          ])
        end

        data_matrix << totali

      end

      [data_matrix, array_group_aliquote, corrispettivi.sum(&:importo)]
    end

    def build_corrispettivi_report_conditions()
      query_str = []
      parametri = []
      
      data_dal = get_date(:from)
      data_al = get_date(:to)

      query_str << "corrispettivi.data >= ?"
      parametri << data_dal
      query_str << "corrispettivi.data <= ?"
      parametri << data_al
        
      if filtro.anno
        query_str << "#{to_sql_year('data')} = ? "
        parametri << filtro.anno
      end

      if filtro.mese
        query_str << "#{to_sql_month('data')} = ? "
        parametri << filtro.mese
      end

      if filtro.aliquota
        query_str << "corrispettivi.aliquota_id = ? "
        parametri << filtro.aliquota
      end
      
      {:conditions => [query_str.join(' AND '), *parametri],
        :include => [:pdc_dare, :pdc_avere],
        :order => 'corrispettivi.data'}
    end
    
    def search_corrispettivi()
      Corrispettivo.search(:all, build_corrispettivi_search_conditions())
    end
    
    def build_corrispettivi_search_conditions()
      query_str = []
      parametri = []
      
      if filtro.anno
        query_str << "#{to_sql_year('data')} = ? "
        parametri << filtro.anno
      end

      if filtro.mese
        query_str << "#{to_sql_month('data')} = ? "
        parametri << filtro.mese
      end

#      if filtro.aliquota
#        query_str << "corrispettivi.aliquota_id = ? "
#        parametri << filtro.aliquota
#      end
      
      {:conditions => [query_str.join(' AND '), *parametri],
        :order => 'corrispettivi.data'}
    end

    # gestione ddt

    def load_ddt(id)
      Ddt.find(id)
    end
    
    def save_ddt()
      righe = righe_ddt_panel.result_set_lstrep_righe_ddt

      Ddt.transaction do
        ddt.save!

        ProgressivoDdt.aggiorna_progressivo(ddt) if ddt.num.match(/^[0-9]*$/) 

        righe.each do |riga|
          case riga.instance_status
          when RigaDdt::ST_INSERT
            # associo l'id della ddt alla riga
            riga.ddt = ddt
            riga.save!
          when RigaDdt::ST_UPDATE
            riga.save!
          when RigaDdt::ST_DELETE
            riga.destroy
          end
        end

      end

      return true

    end

    def delete_ddt()
      ddt.destroy
    end

    def search_for_ddt()
      if filtro.cliente 
        if filtro.cliente.new_record?
          Ddt.search_for(filtro.ricerca, [:num, 'clienti.denominazione', 'fornitori.denominazione'], build_ddt_dialog_conditions())
        else
          Ddt.search_for(filtro.ricerca, [:num, 'clienti.denominazione'], build_ddt_dialog_conditions())
        end
      else
          Ddt.search_for(filtro.ricerca, [:num, 'fornitori.denominazione'], build_ddt_dialog_conditions())
      end
    end

    def search_righe_ddt(doc)
      RigaDdt.search(:all, :conditions => ['ddt_id = ?', doc], :order => 'righe_ddt.id')
    end

    def build_ddt_dialog_conditions()
      query_str = []
      parametri = []
      
      if filtro.anno
        query_str << "#{to_sql_year('data_emissione')} = ? "
        parametri << filtro.anno
      end

      unless filtro.cliente.new_record?
        query_str << "cliente_id = ?"
        parametri << filtro.cliente.id
      end
      
      # usando :include con associazione polimorfica e condizione sull'associazione non funziona
      {:conditions => [query_str.join(' AND '), *parametri], 
#        :joins => [:cliente], # produce una inner join, oppure
        :joins => "LEFT JOIN clienti ON clienti.id = ddt.cliente_id LEFT JOIN fornitori ON fornitori.id = ddt.cliente_id ",
#        :include => :cliente, 
        :order => 'ddt.data_emissione desc, ddt.num desc'}
    end

    # common
    
    def search_incassi_ricorrenti()
      IncassoRicorrente.search(:all)
    end
    
    # gestione aliquote
    
    def save_aliquota()
      aliquota.save
    end

    def delete_aliquota()
      aliquota.destroy
    end

    def search_for_aliquote()
      Aliquota.search_for(filtro.ricerca, 
        [:codice, :percentuale, :descrizione], 
        build_aliquote_dialog_conditions())
    end

    def build_aliquote_dialog_conditions()
      query_str = []
      parametri = []
      
      filtro.build_conditions(query_str, parametri) if filtro
    
      {:conditions => [query_str.join(' AND '), *parametri], 
       :order => 'codice'}
    end
    
    # gestione ritenute
    
    def load_ritenuta(id)
      Ritenuta.find(id)
    end
    
    def load_ritenuta_by_codice(codice)
      Ritenuta.find_by_codice(codice)
    end
    
    def save_ritenuta()
      ritenuta.save
    end

    def delete_ritenuta()
      ritenuta.destroy
    end

    def search_for_ritenute()
      Ritenuta.search_for(filtro.ricerca, 
        [:codice, :percentuale, :descrizione], 
        build_ritenute_dialog_conditions())
    end

    def build_ritenute_dialog_conditions()
      query_str = []
      parametri = []
      
      filtro.build_conditions(query_str, parametri) if filtro
    
      {:conditions => [query_str.join(' AND '), *parametri], 
       :order => 'codice'}
    end
    
    # gestione incassi ricorrenti
    
    def load_incasso_ricorrente(id)
      IncassoRicorrente.find(id, :include => [:cliente])
    end
    
    def save_incasso_ricorrente()
      incasso_ricorrente.save
    end

    def delete_incasso_ricorrente()
      incasso_ricorrente.destroy
    end

    def search_for_incassi_ricorrenti()
      IncassoRicorrente.search_for(filtro.ricerca, 
        ['clienti.denominazione', :descrizione], 
        build_incasso_ricorrente_dialog_conditions())
    end

    def build_incasso_ricorrente_dialog_conditions()
      query_str = []
      parametri = []
      
      filtro.build_conditions(query_str, parametri) if filtro
    
      {:conditions => [query_str.join(' AND '), *parametri],
#        :joins => [:cliente],
       :include => [:cliente]
      }
    end
    
    
    # gestione report estratto
    def report_estratto
      data_matrix = []

#      if(filtro.dal.nil? && filtro.al.nil?)
        filtro.residuo = true
        self.ripresa_saldo = NotaSpese.sum(:importo, build_estratto_report_conditions())

        dati_ns = []
        dati_ns << 'RIPRESA SALDO'
        dati_ns << ''
        dati_ns << ''
        dati_ns << ''
        dati_ns << self.ripresa_saldo

        data_matrix << dati_ns

        self.totale_ns += self.ripresa_saldo
#      end

      filtro.residuo = false

      NotaSpese.search(:all, build_estratto_report_conditions()).each do |ns|
        dati_ns = IdentModel.new(ns.id, NotaSpese)
        dati_ns << ns.cliente.denominazione
        dati_ns << ns.num
        dati_ns << ''
        dati_ns << ns.data_emissione
        dati_ns << ns.importo

        data_matrix << dati_ns

        if fattura = ns.fattura_cliente
          dati_fattura = IdentModel.new(fattura.id, FatturaClienteFatturazione)
          dati_fattura << ''
          dati_fattura << ''
          dati_fattura << fattura.num
          dati_fattura << fattura.data_emissione
          dati_fattura << ''
          dati_fattura << fattura.importo

          data_matrix << dati_fattura

          self.totale_incassi += ns.importo
        end
 
        self.totale_ns += ns.importo

      end

      data_matrix
    end

    def build_estratto_report_conditions()
      query_str = []
      parametri = []
      
      data_dal = get_date(:from)
      data_al = get_date(:to)

      if(filtro.residuo)
        query_str << "nota_spese.data_emissione < ?" 
        parametri << data_dal
        query_str << "nota_spese.fattura_cliente_id is null" 
      else
        query_str << "nota_spese.data_emissione >= ?"
        parametri << data_dal
        query_str << "nota_spese.data_emissione <= ?"
        parametri << data_al
      end
        
      if (filtro.cliente)
        query_str << "nota_spese.cliente_id = ?" 
        parametri << filtro.cliente
      end

      # aggiunto per la chiamata alla funzione sum
      query_str << "nota_spese.azienda_id = ?" 
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri]}.merge(
        (filtro.residuo ? {} : {:include => [:cliente, :fattura_cliente], 
          :order => "clienti.denominazione, nota_spese.data_emissione"}
        )
      )
    end
    
    # gestione report partitario
#    def report_partitario
#      data_matrix = []
#
##      if(filtro.dal.nil? && filtro.al.nil?)
#        filtro.residuo = true
#        self.ripresa_saldo = NotaSpese.sum(:importo, build_partitario_report_conditions())
#        dati_ns = []
#        dati_ns << 'RIPRESA SALDO'
#        dati_ns << ''
#        dati_ns << ''
#        dati_ns << nil
#        dati_ns << self.ripresa_saldo
#
#        data_matrix << dati_ns
#
#        self.totale_ns += self.ripresa_saldo
##      end
#
#      if(filtro.al.nil?)
#        filtro_data = Date.new(filtro.anno.to_i).end_of_year()
#      else
#        filtro_data = filtro.al
#      end
#
#      filtro.residuo = false
#
#      NotaSpese.search(:all, build_partitario_report_conditions()).each do |ns|
#        dati_ns = IdentModel.new(ns.id, NotaSpese)
#        dati_ns << ns.cliente.denominazione
#        dati_ns << ns.num
#        dati_ns << ''
#        dati_ns << ns.data_emissione
#        dati_ns << ns.importo
#
#        data_matrix << dati_ns
#
#        if((fattura = ns.fattura_cliente) && (fattura.data_emissione <= filtro_data)) 
#          dati_fattura = IdentModel.new(fattura.id, FatturaClienteFatturazione)
#          dati_fattura << ''
#          dati_fattura << ''
#          dati_fattura << fattura.num
#          dati_fattura << fattura.data_emissione
#          dati_fattura << ''
#          dati_fattura << fattura.importo
#
#          data_matrix << dati_fattura
#
#          self.totale_incassi += ns.importo
#        end
# 
#        self.totale_ns += ns.importo
#
#      end
#
#      data_matrix
#    end
#
#    def build_partitario_report_conditions()
#      query_str = []
#      parametri = []
#      
#      if(filtro.dal)
#        if(filtro.residuo)
#          query_str << "nota_spese.data_emissione < ?" 
#          parametri << filtro.dal
#          query_str << "(nota_spese.fattura_cliente_id is null or #{to_sql_year('fatture_clienti.data_emissione')} >= ?)" 
#          parametri << filtro.dal.year.to_s
#        else
#          query_str << "nota_spese.data_emissione >= ?"
#          parametri << filtro.dal
#          if (filtro.al)
#            query_str << "nota_spese.data_emissione <= ?"
#            parametri << filtro.al
#          end
#        end
#      elsif(filtro.al)
#        if(filtro.residuo)
#          query_str << "#{to_sql_year('nota_spese.data_emissione')} < ?" 
#          parametri << filtro.al.year.to_s
#          query_str << "(nota_spese.fattura_cliente_id is null or #{to_sql_year('fatture_clienti.data_emissione')} >= ?)" 
#          parametri << filtro.al.year.to_s
#        else
#          query_str << "#{to_sql_year('nota_spese.data_emissione')} >= ?" 
#          parametri << filtro.al.year.to_s
#          query_str << "nota_spese.data_emissione <= ?"
#          parametri << filtro.al
#        end
#      else
#        if(filtro.residuo)
#          query_str << "#{to_sql_year('nota_spese.data_emissione')} < ?" 
#          parametri << filtro.anno
#          query_str << "(nota_spese.fattura_cliente_id is null or #{to_sql_year('fatture_clienti.data_emissione')} >= ?)" 
#          parametri << filtro.anno
#        else
#          query_str << "#{to_sql_year('nota_spese.data_emissione')} = ?" 
#          parametri << filtro.anno
#        end
#      end
#      
#      if (filtro.cliente)
#        query_str << "nota_spese.cliente_id = ?" 
#        parametri << filtro.cliente
#      end
#
#      # aggiunto per la chiamata alla funzione sum
#      query_str << "nota_spese.azienda_id = ?" 
#      parametri << Azienda.current
#
#      {:conditions => [query_str.join(' AND '), *parametri]}.merge(
#        (filtro.residuo ? {:include => [:fattura_cliente]} : {:include => [:cliente, :fattura_cliente], 
#          :order => "clienti.denominazione, nota_spese.data_emissione"}
#        )
#      )
#    end
    
    # gestione report da fatturare
    def report_da_fatturare
      data_matrix = []

#      if(filtro.dal.nil? && filtro.al.nil?)
        filtro.residuo = true
        self.ripresa_saldo = NotaSpese.sum(:importo, build_da_fatturare_report_conditions())

        dati_ns = []
        dati_ns << 'RIPRESA SALDO'
        dati_ns << ''
        dati_ns << ''
        dati_ns << ''
        dati_ns << ''
        dati_ns << self.ripresa_saldo

        data_matrix << dati_ns

        self.totale_ns += self.ripresa_saldo
#      end

      filtro.residuo = false

      NotaSpese.search(:all, build_da_fatturare_report_conditions()).each do |ns|

        if filtro.riepilogo
          dati_ns = []
          dati_ns << ns.denominazione
          dati_ns << ''
          dati_ns << ''
          dati_ns << ns.imponibile
          dati_ns << ns.iva
          dati_ns << ns.importo

          data_matrix << dati_ns

          self.totale_imponibile += ns.imponibile
          self.totale_iva += ns.iva
          self.totale_ns += ns.importo

        else
          dati_ns = IdentModel.new(ns.id, NotaSpese)
          dati_ns << ns.cliente.denominazione
          dati_ns << ns.num
          dati_ns << ns.data_emissione
          dati_ns << ns.imponibile
          dati_ns << ns.iva
          dati_ns << ns.importo

          data_matrix << dati_ns

          self.totale_imponibile += ns.imponibile
          self.totale_iva += ns.iva
          self.totale_ns += ns.importo

        end
      end

      data_matrix
    end

    def build_da_fatturare_report_conditions()
      query_str = []
      parametri = []
      
      data_dal = get_date(:from)
      data_al = get_date(:to)

      if(filtro.residuo)
        query_str << "nota_spese.data_emissione < ?" 
        parametri << data_dal
      else
        query_str << "nota_spese.data_emissione >= ?"
        parametri << data_dal
        query_str << "nota_spese.data_emissione <= ?"
        parametri << data_al
      end
        
      query_str << "nota_spese.fattura_cliente_id is null"
      
      if (filtro.cliente)
        query_str << "nota_spese.cliente_id = ?" 
        parametri << filtro.cliente
      end

      if filtro.riepilogo
        if filtro.residuo
          {:conditions => [query_str.join(' AND '), *parametri]}
        else
          {:select => "clienti.denominazione as denominazione, sum(nota_spese.imponibile) as imponibile, sum(nota_spese.iva) as iva, sum(nota_spese.importo) as importo",
            :conditions => [query_str.join(' AND '), *parametri]}.merge(
              {:joins => :cliente,
                :group => "clienti.denominazione",
                :order => "clienti.denominazione"}
            )
        end
      else
        {:conditions => [query_str.join(' AND '), *parametri]}.merge(
          (filtro.residuo ? {} : {:include => [:cliente, :fattura_cliente],
            :order => "clienti.denominazione, nota_spese.data_emissione"}
          )
        )

      end
    end
    
    # gestione report fatture
    def report_fatture
      data_matrix = []

      FatturaCliente.search(:all, build_fatture_report_conditions()).each do |fattura|
        if filtro.riepilogo
          dati_fattura = []
          dati_fattura << fattura.denominazione
          dati_fattura << ''
          dati_fattura << ''
          dati_fattura << fattura.imponibile
          dati_fattura << fattura.iva
          dati_fattura << fattura.importo

          data_matrix << dati_fattura

          self.totale_imponibile += fattura.imponibile
          self.totale_iva += fattura.iva
          self.totale_fatture += fattura.importo

        else
          dati_fattura = IdentModel.new(fattura.id, FatturaCliente)
          dati_fattura << fattura.cliente.denominazione
          dati_fattura << fattura.num
          dati_fattura << fattura.data_emissione
          dati_fattura << fattura.imponibile
          dati_fattura << fattura.iva
          dati_fattura << fattura.importo

          data_matrix << dati_fattura

          self.totale_imponibile += fattura.imponibile
          self.totale_iva += fattura.iva
          self.totale_fatture += fattura.importo

        end
      end

      data_matrix
    end

    def build_fatture_report_conditions()
      query_str = []
      parametri = []
      
      data_dal = get_date(:from)
      data_al = get_date(:to)

      query_str << "fatture_clienti.data_emissione >= ?"
      parametri << data_dal
      query_str << "fatture_clienti.data_emissione <= ?"
      parametri << data_al
        
      if (filtro.cliente)
        query_str << "fatture_clienti.cliente_id = ?" 
        parametri << filtro.cliente
      end

      if filtro.riepilogo
        {:select => "clienti.denominazione as denominazione, sum(fatture_clienti.imponibile) as imponibile, sum(fatture_clienti.iva) as iva, sum(fatture_clienti.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => :cliente,
            :group => "clienti.denominazione",
            :order => "clienti.denominazione"}
          )

      else
        {:conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:include => [:cliente],
            :order => "clienti.denominazione, fatture_clienti.data_emissione"}
          )

      end

    end
    
    # gestione report flussi
    def report_flussi
      data_matrix = []

      search_clienti().each do |cliente|
        if cliente.attivo?
          filtro.cliente = cliente

          flussi_ns = NotaSpese.search(:all, build_flussi_report_conditions())

          dati_ns = []
          if flussi_ns.empty?
            dati_ns << cliente.denominazione
            dati_ns.concat(([''] * 12))
          else
            dati_ns << cliente.denominazione
            flussi_x_mese = {}

            flussi_ns.each do |ns|
              if flusso = flussi_x_mese[ns.data_emissione.month]
                begin
                  Date.strptime(flusso, '%d/%m/%y')
                  flussi_x_mese[ns.data_emissione.month] = ns.fattura_cliente_id.nil? ? '--/**/--' : ns.fattura_cliente.data_emissione.to_s(:italian_short_date) + '*'
                rescue ArgumentError
                  flussi_x_mese[ns.data_emissione.month] = '--/**/--'
                  next
                end
              else
                flussi_x_mese[ns.data_emissione.month] = ns.fattura_cliente_id.nil? ? '--/--/--' : ns.fattura_cliente.data_emissione.to_s(:italian_short_date)
              end

            end

            1.upto(12) do |mese|
              if flusso = flussi_x_mese[mese]
                dati_ns << flusso
              else
                dati_ns << ''
              end
            end

          end
          data_matrix << dati_ns
        end
      end
      data_matrix
    end

    def build_flussi_report_conditions()
      query_str = []
      parametri = []
      
      query_str << "#{to_sql_year('nota_spese.data_emissione')} = ? " 
      parametri << filtro.anno
      
      query_str << "nota_spese.cliente_id = ?" 
      parametri << filtro.cliente

      {:conditions => [query_str.join(' AND '), *parametri]}.merge(
        (filtro.residuo ? {} : {:include => [:cliente, :fattura_cliente], 
          :order => "clienti.denominazione, nota_spese.data_emissione"}
        )
      )
    end
    
  end
end