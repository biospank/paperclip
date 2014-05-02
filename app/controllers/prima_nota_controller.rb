# encoding: utf-8

module Controllers
  module PrimaNotaController
    include Controllers::BaseController
    
    attr_accessor :totali, :saldi, :ripresa_saldi, :dati_ripresa_saldo
    
    # gestione prima nota
    
    def saldo_cassa()
      Scrittura.sum(:cassa_dare, :conditions => ["azienda_id = ?", Azienda.current]) - Scrittura.sum(:cassa_avere, :conditions => ["azienda_id = ?", Azienda.current])
    end

    def saldo_banca()
      Scrittura.sum(:banca_dare, :conditions => ["azienda_id = ?", Azienda.current]) - Scrittura.sum(:banca_avere, :conditions => ["azienda_id = ?", Azienda.current])
    end

    def save_scrittura()
      Scrittura.transaction do
        scrittura.save!

        logger.debug("scrittura.instance_status: #{scrittura.instance_status}")
        if scrittura.new_record?
          create_scrittura_partita_doppia() if configatron.bilancio.attivo
        else
          update_scrittura_partita_doppia() if configatron.bilancio.attivo
        end
      end
      
      return true
    end

    def load_scrittura(id)
      Scrittura.find(id)
    end
    
    def delete_scrittura()
      scrittura.prima_nota_partita_doppia.each do |pnpd|
        pnpd.destroy
      end
      scrittura.destroy
    end


    def create_scrittura_partita_doppia()

      scrittura_pd = ScritturaPd.new(:azienda => Azienda.current,
                              :importo => (scrittura.cassa_dare || scrittura.cassa_avere ||
                                  scrittura.banca_dare || scrittura.banca_avere ||
                                  scrittura.fuori_partita_dare || scrittura.fuori_partita_avere),
                              :descrizione => scrittura.descrizione,
                              :pdc_dare => scrittura.pdc_dare,
                              :pdc_avere => scrittura.pdc_avere,
                              :data_operazione => scrittura.data_operazione,
                              :data_registrazione => Time.now,
                              :esterna => 0,
                              :congelata => 0,
                              :tipo => 'Models::Scrittura')

      scrittura_pd.save_with_validation(false)
      PrimaNotaPartitaDoppia.create(:prima_nota_id => scrittura.id,
                                    :partita_doppia_id => scrittura_pd.id)

    end

    def update_scrittura_partita_doppia()
      logger.debug("update_scrittura_partita_doppia")
      scrittura.prima_nota_partita_doppia.each do |pnpd|
        pnpd.destroy
      end
      create_scrittura_partita_doppia()
    end


    # STORNO SCRITTURA
    def storno_scrittura(scrittura)
      descrizione = build_descrizione_storno_scrittura(scrittura)
      storno = Scrittura.new(:azienda => Azienda.current,
                                :banca => scrittura.banca,
                                :causale => scrittura.causale,
                                :descrizione => descrizione,
                                :data_operazione => Date.today,
                                :data_registrazione => Time.now,
                                :esterna => 1,
                                :congelata => 0)

      storno.cassa_dare = (scrittura.cassa_dare * -1) if scrittura.cassa_dare?
      storno.cassa_avere = (scrittura.cassa_avere * -1) if scrittura.cassa_avere?
      storno.banca_dare = (scrittura.banca_dare * -1) if scrittura.banca_dare?
      storno.banca_avere = (scrittura.banca_avere * -1) if scrittura.banca_avere?
      storno.fuori_partita_dare = (scrittura.fuori_partita_dare * -1) if scrittura.fuori_partita_dare?
      storno.fuori_partita_avere = (scrittura.fuori_partita_avere * -1) if scrittura.fuori_partita_avere?
      
      storno.parent = scrittura

      storno.save_with_validation(false)

      storno

    end

    def build_descrizione_storno_scrittura(scrittura)
      descrizione = ""
      descrizione << "** STORNO SCRITTURA del #{scrittura.data_operazione.to_s(:italian_date)} ** "

      descrizione  << scrittura.descrizione

      descrizione

    end

    def ricerca_scritture()
      Scrittura.search(:all, build_scritture_search_conditions())
    end

    def build_scritture_search_conditions()
      query_str = []
      parametri = []
      
      data_dal = get_date(:from)
      data_al = get_date(:to)

      query_str << "data_operazione >= ?"
      parametri << data_dal
      query_str << "data_operazione <= ?"
      parametri << data_al
        
      {:conditions => [query_str.join(' AND '), *parametri], 
        :include => [:storno, :causale, :banca],
        :order => 'data_operazione'}
    end

    # gestione causali

    def load_causale(id)
      Causale.find(id)
    end

    def load_causale_by_codice(codice)
      Causale.find_by_codice(codice)
    end

    def save_causale()
      causale.save
    end

    def delete_causale()
      causale.destroy
    end

    def search_for_causali()
      Causale.search_for(filtro.ricerca,
        [:codice, :descrizione],
        build_causali_dialog_conditions())
    end

    def build_causali_dialog_conditions()
      query_str = []
      parametri = []

      filtro.build_conditions(query_str, parametri) if filtro

      {:conditions => [query_str.join(' AND '), *parametri],
       :order => 'codice'}
    end

    # gestione pdc

    def load_pdc_by_codice(codice)
      Pdc.find_by_codice(codice)
    end

    def save_pdc()
      pdc.save
    end

    def delete_pdc()
      pdc.destroy
    end

    def search_for_pdc()
      Pdc.search_for(filtro.ricerca,
        ['pdc.codice', 'pdc.descrizione'],
        build_pdc_dialog_conditions())
    end

    def build_pdc_dialog_conditions()
      query_str = []
      parametri = []

      unless filtro.hidden
        query_str << "pdc.hidden = ?"
        parametri << 0
      end
      
      filtro.build_conditions(query_str, parametri) if filtro

      {:conditions => [query_str.join(' AND '), *parametri],
        :include => :categoria_pdc,
       :order => 'pdc.codice'}
    end

    # gestione categoria pdc

    def load_categoria_pdc_by_codice(codice)
      CategoriaPdc.find_by_codice(codice)
    end

    def save_categoria_pdc()
      categoria_pdc.save
    end

    def delete_categoria_pdc()
      categoria_pdc.destroy
    end

    def search_for_categorie_pdc()
      CategoriaPdc.search_for(filtro.ricerca,
        [:codice, :descrizione],
        build_categorie_pdc_dialog_conditions())
    end

    def build_categorie_pdc_dialog_conditions()
      query_str = []
      parametri = []

      filtro.build_conditions(query_str, parametri) if filtro

      {:conditions => [query_str.join(' AND '), *parametri],
       :order => 'codice'}
    end

    # gestione storico residui
    
    def search_storico_residui()
      Scrittura.search(:all, :select => "data_residuo",
                        :conditions => ["#{to_sql_year('data_residuo')} = ? ", filtro.anno], 
                        :group => "data_residuo",
                        :order => "data_residuo")

    end
     
    # gestione report
    def report_scritture
      data_matrix = []

      Scrittura.search(:all, build_scritture_report_conditions()).each do |scrittura|
        dati_scrittura = IdentModel.new(scrittura.id, Scrittura)
        dati_scrittura << scrittura.data_operazione
        if scrittura.esterna?
          tipo = 'A'
          if scrittura.stornata?
            tipo = 'AS'
          end
        else
          tipo = 'M'
          if scrittura.stornata?
            tipo = 'MS'
          end
        end
        dati_scrittura << tipo
        dati_scrittura << scrittura.descrizione
        dati_scrittura << scrittura.cassa_dare
        dati_scrittura << scrittura.cassa_avere
        dati_scrittura << scrittura.banca_dare
        dati_scrittura << scrittura.banca_avere
        dati_scrittura << scrittura.fuori_partita_dare
        dati_scrittura << scrittura.fuori_partita_avere
        dati_scrittura << scrittura.causale
        dati_scrittura << scrittura.banca

        data_matrix << dati_scrittura

      end

      data_matrix
    end

    def build_scritture_report_conditions()
      query_str = []
      parametri = []
      
      if filtro.stampa_residuo
        if filtro.data_storico_residuo
          query_str << "prima_nota.data_residuo = ?" 
          parametri << filtro.data_storico_residuo
        else
          query_str << "prima_nota.congelata = 0" 
        end
      else
        # DA RIVEDERE FORSE SAREBBE MEGLIO > 0.0
        case filtro.partita
        when Helpers::PrimaNotaHelper::CASSA
          query_str << "(prima_nota.cassa_dare is not null or prima_nota.cassa_avere is not null)" 
        when Helpers::PrimaNotaHelper::BANCA
          query_str << "(prima_nota.banca_dare is not null or prima_nota.banca_avere is not null)" 
        when Helpers::PrimaNotaHelper::FUORI_PARTITA
          query_str << "(prima_nota.fuori_partita_dare is not null or prima_nota.fuori_partita_avere is not null)" 
        end

        data_dal = get_date(:from)
        data_al = get_date(:to)

        query_str << "prima_nota.data_operazione >= ?"
        parametri << data_dal
        query_str << "prima_nota.data_operazione <= ?"
        parametri << data_al

        if (filtro.causale)
          query_str << "prima_nota.causale_id = ?"
          parametri << filtro.causale
        end

        if (filtro.banca)
          query_str << "prima_nota.banca_id = ?"
          parametri << filtro.banca
        end
      end
      
      {:conditions => [query_str.join(' AND '), *parametri], 
        :include => [:causale, :banca, :storno],
        :order => "prima_nota.data_operazione"}
    end
    
    def report_partitario
      data_matrix = []
      self.totali = {:cassa => {:dare => 0, :avere => 0}, :banca => {:dare => 0, :avere => 0}, :fuori_partita => {:dare => 0, :avere => 0}}
      self.ripresa_saldi = {:cassa => {:dare => 0, :avere => 0}, :banca => {:dare => 0, :avere => 0}, :fuori_partita => {:dare => 0, :avere => 0}}
      self.saldi = {:cassa => {:dare => 0, :avere => 0}, :banca => {:dare => 0, :avere => 0}, :fuori_partita => {:dare => 0, :avere => 0}}

      self.dati_ripresa_saldo = ['', '', 'RIPRESA SALDO', '', '', '', '', '', '']

      filtro.residuo = true
      case filtro.partita
      when Helpers::PrimaNotaHelper::CASSA
        calcola_ripresa_saldo(:cassa)
      when Helpers::PrimaNotaHelper::BANCA
        calcola_ripresa_saldo(:banca)
      when Helpers::PrimaNotaHelper::FUORI_PARTITA
        calcola_ripresa_saldo(:fuori_partita)
      else
        calcola_ripresa_saldo(:cassa)
        calcola_ripresa_saldo(:banca)
        calcola_ripresa_saldo(:fuori_partita)
      end

      data_matrix << self.riga_dati_ripresa_saldo

      filtro.residuo = false

      Scrittura.search(:all, build_partitario_report_conditions()).each do |scrittura|
        dati_scrittura = IdentModel.new(scrittura.id, Scrittura)
        dati_scrittura << scrittura.data_operazione
        if scrittura.esterna?
          dati_scrittura << 'A'
        else
          dati_scrittura << 'M'
        end
        dati_scrittura << scrittura.descrizione
        dati_scrittura << scrittura.cassa_dare
        dati_scrittura << scrittura.cassa_avere
        dati_scrittura << scrittura.banca_dare
        dati_scrittura << scrittura.banca_avere
        dati_scrittura << scrittura.fuori_partita_dare
        dati_scrittura << scrittura.fuori_partita_avere

        case filtro.partita
        when Helpers::PrimaNotaHelper::CASSA
          self.totali[:cassa][:dare] += scrittura.cassa_dare if scrittura.cassa_dare
          self.totali[:cassa][:avere] += scrittura.cassa_avere if scrittura.cassa_avere
        when Helpers::PrimaNotaHelper::BANCA
          self.totali[:banca][:dare] += scrittura.banca_dare if scrittura.banca_dare
          self.totali[:banca][:avere] += scrittura.banca_avere if scrittura.banca_avere
        when Helpers::PrimaNotaHelper::FUORI_PARTITA
          self.totali[:fuori_partita][:dare] += scrittura.fuori_partita_dare if scrittura.fuori_partita_dare
          self.totali[:fuori_partita][:avere] += scrittura.fuori_partita_avere if scrittura.fuori_partita_avere
        else
          self.totali[:cassa][:dare] += scrittura.cassa_dare if scrittura.cassa_dare
          self.totali[:cassa][:avere] += scrittura.cassa_avere if scrittura.cassa_avere
          self.totali[:banca][:dare] += scrittura.banca_dare if scrittura.banca_dare
          self.totali[:banca][:avere] += scrittura.banca_avere if scrittura.banca_avere
          self.totali[:fuori_partita][:dare] += scrittura.fuori_partita_dare if scrittura.fuori_partita_dare
          self.totali[:fuori_partita][:avere] += scrittura.fuori_partita_avere if scrittura.fuori_partita_avere
        end

        dati_scrittura << scrittura.causale
        dati_scrittura << scrittura.banca

        data_matrix << dati_scrittura
      end

      logger.debug("totali: #{self.totali.inspect}")
      logger.debug("ripresa saldi: #{self.ripresa_saldi.inspect}")
      logger.debug("saldi: #{self.saldi.inspect}")

      data_matrix << ['', '', '', '', '', '', '', '', ''] # riga vuota

      data_matrix << riga_dati_totali()

      case filtro.partita
      when Helpers::PrimaNotaHelper::CASSA
        calcola_saldo(:cassa)
      when Helpers::PrimaNotaHelper::BANCA
        calcola_saldo(:banca)
      when Helpers::PrimaNotaHelper::FUORI_PARTITA
        calcola_saldo(:fuori_partita)
      else
        calcola_saldo(:cassa)
        calcola_saldo(:banca)
        calcola_saldo(:fuori_partita)
      end

      data_matrix << riga_dati_saldi()

      data_matrix
    end

    def report_partitario_bilancio
      data_matrix = []

      dati_ripresa_saldo = ['', 'RIPRESA SALDO', '', '']

      conto = filtro.pdc

      ripresa_saldo_dare = 0.0
      ripresa_saldo_avere = 0.0

      if conto.conto_patrimoniale?
        residuo_attivo = ScritturaPd.sum(:importo, build_attivi_report_conditions(conto, true))
        residuo_passivo = ScritturaPd.sum(:importo, build_passivi_report_conditions(conto, true))
        if(Helpers::ApplicationHelper.real(residuo_attivo) >= Helpers::ApplicationHelper.real(residuo_passivo))
          ripresa_saldo_dare = (residuo_attivo - residuo_passivo)
          unless ripresa_saldo_dare.zero?
            dati_ripresa_saldo << ripresa_saldo_dare
            dati_ripresa_saldo << ''

            data_matrix << dati_ripresa_saldo

          end
        else
          ripresa_saldo_avere = (residuo_passivo - residuo_attivo)
          unless ripresa_saldo_avere.zero?
            dati_ripresa_saldo << ''
            dati_ripresa_saldo << ripresa_saldo_avere

            data_matrix << dati_ripresa_saldo

          end
        end

        scritture = ScritturaPd.all(build_attivi_report_conditions(conto))
        scritture.concat(ScritturaPd.all(build_passivi_report_conditions(conto)))
      else
        scritture = ScritturaPd.all(build_costi_report_conditions(conto))
        scritture.concat(ScritturaPd.all(build_ricavi_report_conditions(conto)))
      end

      scritture.sort_by {|obj| obj.data_operazione}.each do |scrittura|
        dati_scrittura = []
        dati_scrittura << scrittura.data_operazione
        dati_scrittura << scrittura.descrizione
        if codice_conto_scrittura = [scrittura.pdc_dare_id,
                            scrittura.pdc_avere_id,
                            scrittura.nc_pdc_dare_id,
                            scrittura.nc_pdc_avere_id
                          ].compact.find {|id_conto| id_conto != conto.id}
          conto_scrittura = Pdc.find(codice_conto_scrittura)
          dati_scrittura << conto_scrittura.codice
          dati_scrittura << conto_scrittura.descrizione
        else
          case scrittura.tipo
          when 'Pdc::DettaglioImponibileFatturaCliente',
              'Pdc::DettaglioIvaFatturaCliente'
            dfpd = DettaglioFatturaPartitaDoppia.find_by_partita_doppia_id(scrittura.id)
            cliente = dfpd.dettaglio_fattura_cliente.fattura_cliente.cliente
            dati_scrittura << cliente.conto
            dati_scrittura << cliente.denominazione
          when 'Pdc::DettaglioImponibileFatturaFornitore',
              'Pdc::DettaglioIvaFatturaFornitore'
            dfpd = DettaglioFatturaPartitaDoppia.find_by_partita_doppia_id(scrittura.id)
            fornitore = dfpd.dettaglio_fattura_fornitore.fattura_fornitore.fornitore
            dati_scrittura << fornitore.conto
            dati_scrittura << fornitore.denominazione
          else
            dati_scrittura << conto.codice
            dati_scrittura << conto.descrizione
          end
        end
        if((conto.id == scrittura.pdc_dare_id) ||
          (conto.id == scrittura.nc_pdc_dare_id))
          self.totale_dare += scrittura.importo
          dati_scrittura << scrittura.importo
          dati_scrittura << ''
        else
          self.totale_avere += scrittura.importo
          dati_scrittura << ''
          dati_scrittura << scrittura.importo
        end

        if(((dati_scrittura[4] != '') && (dati_scrittura[4] > 0)) ||
              ((dati_scrittura[5] != '') && (dati_scrittura[5] > 0)))
          data_matrix << dati_scrittura
        end
      end

      self.totale_dare += ripresa_saldo_dare
      self.totale_avere += ripresa_saldo_avere

      data_matrix
    end

    def calcola_ripresa_saldo(partita)
      dare = Scrittura.sum("#{partita}_dare".to_sym, build_ripresa_saldo_report_conditions())
      avere = Scrittura.sum("#{partita}_avere".to_sym, build_ripresa_saldo_report_conditions())
      if dare > avere
        ripresa_saldo =  dare - avere
        self.ripresa_saldi[partita][:dare] = ripresa_saldo
      elsif dare < avere
        ripresa_saldo =  avere - dare
        self.ripresa_saldi[partita][:avere] = ripresa_saldo
      end
      
      ripresa_saldo
    end
    
    def calcola_saldo(partita)
      sub_totale_dare = self.totali[partita][:dare] + self.ripresa_saldi[partita][:dare]
      sub_totale_avere = self.totali[partita][:avere] + self.ripresa_saldi[partita][:avere]
      if sub_totale_dare > sub_totale_avere
        saldo =  sub_totale_dare - sub_totale_avere
        self.saldi[partita][:dare] = saldo
      elsif sub_totale_dare < sub_totale_avere
        saldo =  sub_totale_avere - sub_totale_dare
        self.saldi[partita][:avere] = saldo
      end
      
      saldo
    end
    
    def build_partitario_report_conditions()
      query_str = []
      parametri = []
      
      date_conditions(query_str, parametri)
      common_conditions(query_str, parametri)
      
      {:conditions => [query_str.join(' AND '), *parametri], 
        :include => [:causale, :banca],
        :joins => "LEFT JOIN prima_nota as storni ON prima_nota.id = storni.parent_id",
        :order => "prima_nota.data_operazione"}
    end
    
    def build_ripresa_saldo_report_conditions()
      query_str = []
      parametri = []

      date_conditions(query_str, parametri)
      common_conditions(query_str, parametri)

      # aggiunto per la chiamata alla funzione sum
      query_str << "prima_nota.azienda_id = ?" 
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri],
        :joins => "LEFT JOIN prima_nota as storni ON prima_nota.id = storni.parent_id"
      }

    end

    def date_conditions(query_str, parametri)

      data_dal = get_date(:from)
      data_al = get_date(:to)

      if(filtro.residuo)
        query_str << "prima_nota.data_operazione < ?"
        parametri << data_dal
      else
        query_str << "prima_nota.data_operazione >= ?"
        parametri << data_dal
        query_str << "prima_nota.data_operazione <= ?"
        parametri << data_al
      end
        
    end

    def common_conditions(query_str, parametri)
      case filtro.partita
      when Helpers::PrimaNotaHelper::CASSA
        query_str << "(prima_nota.cassa_dare is not null or prima_nota.cassa_avere is not null)" 
      when Helpers::PrimaNotaHelper::BANCA
        query_str << "(prima_nota.banca_dare is not null or prima_nota.banca_avere is not null)" 
      when Helpers::PrimaNotaHelper::FUORI_PARTITA
        query_str << "(prima_nota.fuori_partita_dare is not null or prima_nota.fuori_partita_avere is not null)" 
      end

      if (filtro.causale)
        query_str << "prima_nota.causale_id = ?"
        parametri << filtro.causale
      end

      if (filtro.banca)
        query_str << "prima_nota.banca_id = ?"
        parametri << filtro.banca
      end
      
      # escludo le scritture stornate
      query_str << "storni.parent_id is null" 
      # e gli storni
      query_str << "prima_nota.parent_id is null" 

    end

    def riga_dati_ripresa_saldo()
      
      dati_ripresa_saldo = []
      dati_ripresa_saldo << ''
      dati_ripresa_saldo << ''
      dati_ripresa_saldo << 'RIPRESA SALDO'
      dati_ripresa_saldo << (self.ripresa_saldi[:cassa][:dare].zero? ? '' : self.ripresa_saldi[:cassa][:dare])
      dati_ripresa_saldo << (self.ripresa_saldi[:cassa][:avere].zero? ? '' : self.ripresa_saldi[:cassa][:avere])
      dati_ripresa_saldo << (self.ripresa_saldi[:banca][:dare].zero? ? '' : self.ripresa_saldi[:banca][:dare])
      dati_ripresa_saldo << (self.ripresa_saldi[:banca][:avere].zero? ? '' : self.ripresa_saldi[:banca][:avere])
      dati_ripresa_saldo << (self.ripresa_saldi[:fuori_partita][:dare].zero? ? '' : self.ripresa_saldi[:fuori_partita][:dare])
      dati_ripresa_saldo << (self.ripresa_saldi[:fuori_partita][:avere].zero? ? '' : self.ripresa_saldi[:fuori_partita][:avere])

      dati_ripresa_saldo

    end

    def riga_dati_totali()
      dati_totali = []
      dati_totali << ''
      dati_totali << ''
      dati_totali << 'TOTALE'
      dati_totali << (self.totali[:cassa][:dare].zero? ? '' : self.totali[:cassa][:dare])
      dati_totali << (self.totali[:cassa][:avere].zero? ? '' : self.totali[:cassa][:avere])
      dati_totali << (self.totali[:banca][:dare].zero? ? '' : self.totali[:banca][:dare])
      dati_totali << (self.totali[:banca][:avere].zero? ? '' : self.totali[:banca][:avere])
      dati_totali << (self.totali[:fuori_partita][:dare].zero? ? '' : self.totali[:fuori_partita][:dare])
      dati_totali << (self.totali[:fuori_partita][:avere].zero? ? '' : self.totali[:fuori_partita][:avere])

      dati_totali
      
    end
    
    def riga_dati_saldi()
      dati_saldi = []
      dati_saldi << ''
      dati_saldi << ''
      dati_saldi << 'SALDO'
      dati_saldi << (self.saldi[:cassa][:dare].zero? ? '' : self.saldi[:cassa][:dare])
      dati_saldi << (self.saldi[:cassa][:avere].zero? ? '' : self.saldi[:cassa][:avere])
      dati_saldi << (self.saldi[:banca][:dare].zero? ? '' : self.saldi[:banca][:dare])
      dati_saldi << (self.saldi[:banca][:avere].zero? ? '' : self.saldi[:banca][:avere])
      dati_saldi << (self.saldi[:fuori_partita][:dare].zero? ? '' : self.saldi[:fuori_partita][:dare])
      dati_saldi << (self.saldi[:fuori_partita][:avere].zero? ? '' : self.saldi[:fuori_partita][:avere])

      dati_saldi
      
    end
    
    # gestione report bilancio stato patrimoniale
    def report_stato_patrimoniale()
      attivita_data_matrix = {}
      passivita_data_matrix = {}

      tipo_conti = %w('Attivo' 'Passivo')
      
      conti_ids = seleziona_conti(:pdc_dare_id, tipo_conti)
      conti_ids << seleziona_conti(:nc_pdc_dare_id, tipo_conti)
      conti_ids << seleziona_conti(:pdc_avere_id, tipo_conti)
      conti_ids << seleziona_conti(:nc_pdc_avere_id, tipo_conti)

      conti = Pdc.find(conti_ids.flatten.uniq)

      conti.each do |conto|
        somma_attivo = ScritturaPd.sum(:importo, build_attivi_report_conditions(conto, true))
        somma_attivo += ScritturaPd.sum(:importo, build_attivi_report_conditions(conto))
        somma_passivo = ScritturaPd.sum(:importo, build_passivi_report_conditions(conto, true))
        somma_passivo += ScritturaPd.sum(:importo, build_passivi_report_conditions(conto))

        conto_ident = IdentModel.new(conto.id, Pdc)

        if(Helpers::ApplicationHelper.real(somma_attivo) >= Helpers::ApplicationHelper.real(somma_passivo))
          attivo = (somma_attivo - somma_passivo)

          conto_ident << conto.codice
          conto_ident << conto.descrizione
          conto_ident << attivo

          attivita_data_matrix[conto.codice.to_i] = conto_ident

          self.totale_attivita += attivo
        else
          passivo = (somma_passivo - somma_attivo)

          conto_ident << conto.codice
          conto_ident << conto.descrizione
          conto_ident << passivo

          passivita_data_matrix[conto.codice.to_i] = conto_ident

          self.totale_passivita += passivo
        end
      end

      attivita = attivita_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}
      passivita = passivita_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}

      [attivita, passivita]
    end

    def report_stato_patrimoniale_aggregato()
      attivita_data_matrix = {}
      passivita_data_matrix = {}

      tipo_conti = %w('Attivo' 'Passivo')

      conti_ids = seleziona_conti(:pdc_dare_id, tipo_conti)
      conti_ids << seleziona_conti(:nc_pdc_dare_id, tipo_conti)
      conti_ids << seleziona_conti(:pdc_avere_id, tipo_conti)
      conti_ids << seleziona_conti(:nc_pdc_avere_id, tipo_conti)

      conti = Pdc.find(conti_ids.flatten.uniq, :include => :categoria_pdc)

      conti.each do |conto|
        somma_attivo = ScritturaPd.sum(:importo, build_attivi_report_conditions(conto, true))
        somma_attivo += ScritturaPd.sum(:importo, build_attivi_report_conditions(conto))
        somma_passivo = ScritturaPd.sum(:importo, build_passivi_report_conditions(conto, true))
        somma_passivo += ScritturaPd.sum(:importo, build_passivi_report_conditions(conto))

        conto_ident = IdentModel.new(conto.id, Pdc)

        categoria = conto.categoria_pdc

        if(Helpers::ApplicationHelper.real(somma_attivo) >= Helpers::ApplicationHelper.real(somma_passivo))

          attivo = (somma_attivo - somma_passivo)

          conto_ident << conto.codice
          conto_ident << conto.descrizione
          conto_ident << attivo
          conto_ident << categoria.codice.to_i

          attivita_data_matrix[conto.codice.to_i] = conto_ident

          self.totale_attivita += attivo
        else
          passivo = (somma_passivo - somma_attivo)

          conto_ident << conto.codice
          conto_ident << conto.descrizione
          conto_ident << passivo
          conto_ident << categoria.codice.to_i

          passivita_data_matrix[conto.codice.to_i] = conto_ident

          self.totale_passivita += passivo
        end

        conto_ident << categoria.codice
      end

      res_attivita = []
      res_passivita = []

      attivita = attivita_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}

      attivita.group_by { |e|  e[3]}.each do |e|
        codice_categoria = e.first
        array_conti = e.last
        categoria = CategoriaPdc.find_by_codice(codice_categoria)
        case codice_categoria
        when Models::CategoriaPdc::FORNITORI.to_i
          #res_attivita << [Models::Pdc::Categoria::FORNITORI, categoria.descrizione, array_conti.sum {|e| e[2]}]
        when Models::CategoriaPdc::CLIENTI.to_i
          #res_attivita << [Models::Pdc::Categoria::CLIENTI, categoria.descrizione, array_conti.sum {|e| e[2]}]
        else
          res_attivita.concat(array_conti)
        end
        categoria_ident = IdentModel.new(categoria.id, CategoriaPdc)
        categoria_ident << categoria.codice
        categoria_ident << categoria.descrizione
        categoria_ident << (array_conti.map {|c| c[2]}.inject {|sum, n| sum + n})
        res_attivita << categoria_ident
      end

      passivita = passivita_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}
      passivita.group_by { |e|  e[3]}.each do |e|
        codice_categoria = e.first
        array_conti = e.last
        categoria = CategoriaPdc.find_by_codice(codice_categoria)
        case codice_categoria
        when Models::CategoriaPdc::FORNITORI.to_i
          #res_passivita << [Models::Pdc::Categoria::FORNITORI, categoria.descrizione, array_conti.sum {|e| e[2]}]
        when Models::CategoriaPdc::CLIENTI.to_i
          #res_passivita << [Models::Pdc::Categoria::CLIENTI, categoria.descrizione, array_conti.sum {|e| e[2]}]
        else
          res_passivita.concat(array_conti)
        end
        categoria_ident = IdentModel.new(categoria.id, CategoriaPdc)
        categoria_ident << categoria.codice
        categoria_ident << categoria.descrizione
        categoria_ident << (array_conti.map {|c| c[2]}.inject {|sum, n| sum + n})
        res_passivita << categoria_ident
      end

      [res_attivita, res_passivita]
    end

    def report_conto_economico()
      costi_data_matrix = {}
      ricavi_data_matrix = {}

      tipo_conti = %w('Costo' 'Ricavo')

      conti_ids = seleziona_conti(:pdc_dare_id, tipo_conti)
      conti_ids << seleziona_conti(:nc_pdc_dare_id, tipo_conti)
      conti_ids << seleziona_conti(:pdc_avere_id, tipo_conti)
      conti_ids << seleziona_conti(:nc_pdc_avere_id, tipo_conti)

      conti = Pdc.find(conti_ids.flatten.uniq)

      conti.each do |conto|
        somma_costi = ScritturaPd.sum(:importo, build_costi_report_conditions(conto))
        somma_ricavi = ScritturaPd.sum(:importo, build_ricavi_report_conditions(conto))

        conto_ident = IdentModel.new(conto.id, Pdc)

        if(Helpers::ApplicationHelper.real(somma_costi) >= Helpers::ApplicationHelper.real(somma_ricavi))
          costo = (somma_costi - somma_ricavi)

          conto_ident << conto.codice
          conto_ident << conto.descrizione
          conto_ident << costo

          costi_data_matrix[conto.codice.to_i] = conto_ident

          self.totale_costi += costo
#          costi_data_matrix[conto.codice.to_i] = [conto.codice, conto.descrizione, (somma_costi - somma_ricavi)]
#          self.totale_costi += (somma_costi - somma_ricavi)
        else
          ricavo = (somma_ricavi - somma_costi)

          conto_ident << conto.codice
          conto_ident << conto.descrizione
          conto_ident << ricavo

          ricavi_data_matrix[conto.codice.to_i] = conto_ident

          self.totale_ricavi += ricavo
#          ricavi_data_matrix[conto.codice.to_i] = [conto.codice, conto.descrizione, (somma_ricavi - somma_costi)]
#          self.totale_ricavi += (somma_ricavi - somma_costi)
        end
      end

      costi = costi_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}
      ricavi = ricavi_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}

      [costi, ricavi]
    end

    def report_conto_economico_aggregato()
      costi_data_matrix = {}
      ricavi_data_matrix = {}

      tipo_conti = %w('Costo' 'Ricavo')

      conti_ids = seleziona_conti(:pdc_dare_id, tipo_conti)
      conti_ids << seleziona_conti(:nc_pdc_dare_id, tipo_conti)
      conti_ids << seleziona_conti(:pdc_avere_id, tipo_conti)
      conti_ids << seleziona_conti(:nc_pdc_avere_id, tipo_conti)

      conti = Pdc.find(conti_ids.flatten.uniq)

      conti.each do |conto|
        somma_costi = ScritturaPd.sum(:importo, build_costi_report_conditions(conto))
        somma_ricavi = ScritturaPd.sum(:importo, build_ricavi_report_conditions(conto))

        conto_ident = IdentModel.new(conto.id, Pdc)

        categoria = conto.categoria_pdc

        if(Helpers::ApplicationHelper.real(somma_costi) >= Helpers::ApplicationHelper.real(somma_ricavi))

          costo = (somma_costi - somma_ricavi)

          conto_ident << conto.codice
          conto_ident << conto.descrizione
          conto_ident << costo
          conto_ident << categoria.codice.to_i

          costi_data_matrix[conto.codice.to_i] = conto_ident

          self.totale_costi += costo
        else
          ricavo = (somma_ricavi - somma_costi)

          conto_ident << conto.codice
          conto_ident << conto.descrizione
          conto_ident << ricavo
          conto_ident << categoria.codice.to_i

          ricavi_data_matrix[conto.codice.to_i] = conto_ident

          self.totale_ricavi += ricavo
        end

        conto_ident << categoria.codice
      end

      res_costi = []
      res_ricavi = []

      costi = costi_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}

      costi.group_by { |e|  e[3]}.each do |e|
        codice_categoria = e.first
        array_conti = e.last
        categoria = CategoriaPdc.find_by_codice(codice_categoria)
        res_costi.concat(array_conti)
        categoria_ident = IdentModel.new(categoria.id, CategoriaPdc)
        categoria_ident << categoria.codice
        categoria_ident << categoria.descrizione
        categoria_ident << (array_conti.map {|c| c[2]}.inject {|sum, n| sum + n})
        res_costi << categoria_ident
      end

      ricavi = ricavi_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}
      
      ricavi.group_by { |e|  e[3]}.each do |e|
        codice_categoria = e.first
        array_conti = e.last
        categoria = CategoriaPdc.find_by_codice(codice_categoria)
        res_ricavi.concat(array_conti)
        categoria_ident = IdentModel.new(categoria.id, CategoriaPdc)
        categoria_ident << categoria.codice
        categoria_ident << categoria.descrizione
        categoria_ident << (array_conti.map {|c| c[2]}.inject {|sum, n| sum + n})
        res_ricavi << categoria_ident
      end

      [res_costi, res_ricavi]
    end

    def report_dettaglio_clienti_fornitori()
      clienti_data_matrix = {}
      fornitori_data_matrix = {}

      tipo_conti = %w('Attivo' 'Passivo')
      codici_categoria = %W('#{Models::CategoriaPdc::CLIENTI}' '#{Models::CategoriaPdc::FORNITORI}')

      conti_ids = seleziona_conti(:pdc_dare_id, tipo_conti, codici_categoria)
      conti_ids << seleziona_conti(:nc_pdc_dare_id, tipo_conti, codici_categoria)
      conti_ids << seleziona_conti(:pdc_avere_id, tipo_conti, codici_categoria)
      conti_ids << seleziona_conti(:nc_pdc_avere_id, tipo_conti, codici_categoria)

      conti = Pdc.find(conti_ids.flatten.uniq)

      conti.each do |conto|
        somma_attivo = ScritturaPd.sum(:importo, build_attivi_report_conditions(conto))
        somma_passivo = ScritturaPd.sum(:importo, build_passivi_report_conditions(conto))

        conto_ident = IdentModel.new(conto.id, Pdc)

        conto_ident << conto.codice
        conto_ident << conto.descrizione
        
        if(conto.cliente?)
          differenza = (somma_attivo - somma_passivo)
          conto_ident << differenza
          clienti_data_matrix[conto.codice.to_i] = conto_ident
          self.totale_clienti += differenza
        else
          differenza = (somma_passivo - somma_attivo)
          conto_ident << differenza
          fornitori_data_matrix[conto.codice.to_i] = conto_ident
          self.totale_fornitori += differenza
        end
      end

      clienti = clienti_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}
      fornitori = fornitori_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}

      [clienti, fornitori]
    end

    def seleziona_conti(partita, tipo, codici_categoria = nil)
      if codici_categoria
        ScritturaPd.connection.select_values("select distinct(pd.#{partita})
          from partita_doppia pd
          inner join pdc p on pd.#{partita} = p.id
          inner join categorie_pdc cp on p.categoria_pdc_id = cp.id
          where pd.azienda_id = #{Azienda.current.id} and
            pd.#{partita} is not null and cp.type in(#{tipo.join(',')}) and
            cp.codice in(#{codici_categoria.join(',')})")
      else
        ScritturaPd.connection.select_values("select distinct(pd.#{partita})
          from partita_doppia pd
          inner join pdc p on pd.#{partita} = p.id
          inner join categorie_pdc cp on p.categoria_pdc_id = cp.id
          where pd.azienda_id = #{Azienda.current.id} and
            pd.#{partita} is not null and cp.type in(#{tipo.join(',')})")
      end
    end

    def build_attivi_report_conditions(conto, saldi = false)
      query_str = []
      parametri = []

      if saldi
        query_str << "partita_doppia.data_operazione < ? "
        parametri << get_date(:from)
      else
        query_str << "partita_doppia.data_operazione >= ? "
        parametri << get_date(:from)
        query_str << "partita_doppia.data_operazione <= ? "
        parametri << get_date(:to)
      end

      query_str << "(partita_doppia.pdc_dare_id = #{conto.id} or partita_doppia.nc_pdc_dare_id  = #{conto.id})"

      query_str << "partita_doppia.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri]}

#      {:select => "sum(partita_doppia.importo) as importo, pdc.codice as codice, pdc.descrizione as descrizione",
#        :conditions => [query_str.join(' AND '), *parametri],
#        :joins => "INNER JOIN pdc ON partita_doppia.pdc_dare_id = pdc.id
#                   INNER JOIN categorie_pdc ON pdc.categoria_pdc_id = categorie_pdc.id#",
#        :group => 'pdc.codice, pdc.descrizione'
#      }
    end

    def build_passivi_report_conditions(conto, saldi = false)
      query_str = []
      parametri = []

      if saldi
        query_str << "partita_doppia.data_operazione < ? "
        parametri << get_date(:from)
      else
        query_str << "partita_doppia.data_operazione >= ? "
        parametri << get_date(:from)
        query_str << "partita_doppia.data_operazione <= ? "
        parametri << get_date(:to)
      end

      query_str << "(partita_doppia.pdc_avere_id = #{conto.id} or partita_doppia.nc_pdc_avere_id = #{conto.id})"

      query_str << "partita_doppia.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri]}

#      {:select => "sum(partita_doppia.importo) as importo, pdc.codice as codice, pdc.descrizione as descrizione",
#        :conditions => [query_str.join(' AND '), *parametri],
#        :joins => "INNER JOIN pdc ON partita_doppia.pdc_avere_id = pdc.id
#                   INNER JOIN categorie_pdc ON pdc.categoria_pdc_id = categorie_pdc.id#",
#        :group => 'pdc.codice, pdc.descrizione'
#      }
    end

    def build_costi_report_conditions(conto)
      query_str = []
      parametri = []

      query_str << "partita_doppia.data_operazione >= ? "
      parametri << get_date(:from)
      query_str << "partita_doppia.data_operazione <= ? "
      parametri << get_date(:to)

      query_str << "(partita_doppia.pdc_dare_id = #{conto.id} or partita_doppia.nc_pdc_dare_id  = #{conto.id})"

      query_str << "partita_doppia.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri]}

#      {:select => "sum(partita_doppia.importo) as importo, pdc.codice as codice, pdc.descrizione as descrizione",
#        :conditions => [query_str.join(' AND '), *parametri],
#        :joins => "INNER JOIN pdc ON partita_doppia.pdc_dare_id = pdc.id
#                   INNER JOIN categorie_pdc ON pdc.categoria_pdc_id = categorie_pdc.id#",
#        :group => 'pdc.codice, pdc.descrizione'
#      }
    end

    def build_ricavi_report_conditions(conto)
      query_str = []
      parametri = []

      query_str << "partita_doppia.data_operazione >= ? "
      parametri << get_date(:from)
      query_str << "partita_doppia.data_operazione <= ? "
      parametri << get_date(:to)

      query_str << "(partita_doppia.pdc_avere_id = #{conto.id} or partita_doppia.nc_pdc_avere_id = #{conto.id})"

      query_str << "partita_doppia.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri]}

#      {:select => "sum(partita_doppia.importo) as importo, pdc.codice as codice, pdc.descrizione as descrizione",
#        :conditions => [query_str.join(' AND '), *parametri],
#        :joins => "INNER JOIN pdc ON partita_doppia.pdc_avere_id = pdc.id
#                   INNER JOIN categorie_pdc ON pdc.categoria_pdc_id = categorie_pdc.id#",
#        :group => 'pdc.codice, pdc.descrizione'
#      }
    end

  end
end