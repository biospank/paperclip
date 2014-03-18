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
      scrittura.save!
      return true
    end

    def load_scrittura(id)
      Scrittura.find(id)
    end
    
    def delete_scrittura()
      scrittura.destroy
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

      scritture.sort_by {|obj| obj.id}.each do |scrittura|
        dati_scrittura = []
        dati_scrittura << scrittura.data_operazione
        dati_scrittura << scrittura.descrizione
        dati_scrittura << conto.codice
        dati_scrittura << conto.descrizione
        if conto.id == scrittura.pdc_dare_id ||
            conto.id == scrittura.pdc_dare_id
          self.totale_dare += scrittura.importo
          dati_scrittura << scrittura.importo
          dati_scrittura << ''
        else
          self.totale_avere += scrittura.importo
          dati_scrittura << ''
          dati_scrittura << scrittura.importo
        end
        
        data_matrix << dati_scrittura
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

        if(Helpers::ApplicationHelper.real(somma_attivo) >= Helpers::ApplicationHelper.real(somma_passivo))
          attivita_data_matrix[conto.codice.to_i] = [conto.codice, conto.descrizione, (somma_attivo - somma_passivo)]
          self.totale_attivita += (somma_attivo - somma_passivo)
        else
          passivita_data_matrix[conto.codice.to_i] = [conto.codice, conto.descrizione, (somma_passivo - somma_attivo)]
          self.totale_passivita += (somma_passivo - somma_attivo)
        end
      end

      attivita = attivita_data_matrix.sort.map {|e| e.last}#.reject {|e| e[2].zero?}
      passivita = passivita_data_matrix.sort.map {|e| e.last}#.reject {|e| e[2].zero?}

      [attivita, passivita]
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

        if(Helpers::ApplicationHelper.real(somma_costi) >= Helpers::ApplicationHelper.real(somma_ricavi))
          costi_data_matrix[conto.codice.to_i] = [conto.codice, conto.descrizione, (somma_costi - somma_ricavi)]
          self.totale_costi += (somma_costi - somma_ricavi)
        else
          ricavi_data_matrix[conto.codice.to_i] = [conto.codice, conto.descrizione, (somma_ricavi - somma_costi)]
          self.totale_ricavi += (somma_ricavi - somma_costi)
        end
      end

      costi = costi_data_matrix.sort.map {|e| e.last}#.reject {|e| e[2].zero?}
      ricavi = ricavi_data_matrix.sort.map {|e| e.last}#.reject {|e| e[2].zero?}

      [costi, ricavi]
    end

    def seleziona_conti(partita, tipo)
      ScritturaPd.connection.select_values("select distinct(pd.#{partita})
        from partita_doppia pd
        inner join pdc p on pd.#{partita} = p.id
        inner join categorie_pdc cp on p.categoria_pdc_id = cp.id
        where pd.azienda_id = #{Azienda.current.id} and  pd.#{partita} is not null and cp.type in(#{tipo.join(',')})")
    end

    def report_stato_patrimoniale_old()
      attivita_data_matrix = {}
      passivita_data_matrix = {}

      saldi_attivi_data_matrix, saldi_passivi_data_matrix = report_saldi_stato_patrimoniale()

      attivi_data_matrix = {}
      passivi_data_matrix = {}

      # ATTIVI
      attivi = ScritturaPd.all(build_attivi_report_conditions())

      attivi.each do |dati_attivi|
        conto = dati_attivi.codice.to_i
        attivi_data_matrix[conto] = [conto, dati_attivi.descrizione, dati_attivi.importo]
      end

      attivi_nc = ScritturaPd.all(build_attivi_nc_report_conditions())

      attivi_nc.each do |dati_attivi_nc|
        conto = dati_attivi_nc.codice.to_i
        if attivi_data_matrix[conto]
          attivi_data_matrix[conto][2] += dati_attivi_nc.importo
        else
          attivi_data_matrix[conto] = [conto, dati_attivi_nc.descrizione, dati_attivi_nc.importo]
        end
      end

      # PASSIVI
      passivi = ScritturaPd.all(build_passivi_report_conditions())

      passivi.each do |dati_passivi|
        conto = dati_passivi.codice.to_i
        passivi_data_matrix[conto] = [conto, dati_passivi.descrizione, dati_passivi.importo]
      end

      passivi_nc = ScritturaPd.all(build_passivi_nc_report_conditions())

      passivi_nc.each do |dati_passivi_nc|
        conto = dati_passivi_nc.codice.to_i
        if passivi_data_matrix[conto]
          passivi_data_matrix[conto][2] += dati_passivi_nc.importo
        else
          passivi_data_matrix[conto] = [conto, dati_passivi_nc.descrizione, dati_passivi_nc.importo]
        end
      end

      # merge tra attivi, passivi e saldi
      attivi_data_matrix.each do |conto, attivo|
        totale_attivo = saldi_attivi_data_matrix.delete(conto)[2] rescue 0.0
        totale_attivo += attivo[2]
        totale_passivo = saldi_passivi_data_matrix.delete(conto)[2] rescue 0.0
        totale_passivo += passivi_data_matrix.delete(conto)[2] rescue 0.0


        if(Helpers::ApplicationHelper.real(totale_attivo) >= Helpers::ApplicationHelper.real(totale_passivo))
          attivita_data_matrix[conto] = [attivo[0], attivo[1], (totale_attivo - totale_passivo)]
          self.totale_attivita += (totale_attivo - totale_passivo)
        else
          passivita_data_matrix[conto] = [attivo[0], attivo[1], (totale_passivo - totale_attivo)]
          self.totale_passivita += (totale_passivo - totale_attivo)
        end

      end

      # RESIDUO PASSIVI
      passivi_data_matrix.each do |conto, passivo|
        passivita_data_matrix[conto] = passivo
        self.totale_passivita += passivo[2]
      end

      # RESIDUO SALDI ATTIVI
      saldi_attivi_data_matrix.each do |conto, attivo|
        attivita_data_matrix[conto] = attivo
        self.totale_attivita += attivo[2]
      end

      # RESIDUO SALDI PASSIVI
      saldi_passivi_data_matrix.each do |conto, passivo|
        passivita_data_matrix[conto] = passivo
        self.totale_passivita += passivo[2]
      end

      attivita = attivita_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}
      passivita = passivita_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}

      [attivita, passivita]

    end

    def report_saldi_stato_patrimoniale()
      attivita_data_matrix = {}
      passivita_data_matrix = {}

      attivi_data_matrix = {}
      passivi_data_matrix = {}

      attivi = ScritturaPd.all(build_attivi_report_conditions(true))

      attivi.each do |dati_attivi|
        conto = dati_attivi.codice.to_i
        attivi_data_matrix[conto] = [conto, dati_attivi.descrizione, dati_attivi.importo]
      end

      attivi_nc = ScritturaPd.all(build_attivi_nc_report_conditions(true))

      attivi_nc.each do |dati_attivi_nc|
        conto = dati_attivi_nc.codice.to_i
        if attivi_data_matrix[conto]
          attivi_data_matrix[conto][2] += dati_attivi_nc.importo
        else
          attivi_data_matrix[conto] = [conto, dati_attivi_nc.descrizione, dati_attivi_nc.importo]
        end
      end

      passivi = ScritturaPd.all(build_passivi_report_conditions(true))

      passivi.each do |dati_passivi|
        conto = dati_passivi.codice.to_i
        passivi_data_matrix[conto] = [conto, dati_passivi.descrizione, dati_passivi.importo]
      end

      passivi_nc = ScritturaPd.all(build_passivi_nc_report_conditions(true))

      passivi_nc.each do |dati_passivi_nc|
        conto = dati_passivi_nc.codice.to_i
        if passivi_data_matrix[conto]
          passivi_data_matrix[conto][2] += dati_passivi_nc.importo
        else
          passivi_data_matrix[conto] = [conto, dati_passivi_nc.descrizione, dati_passivi_nc.importo]
        end
      end

      attivi_data_matrix.each do |conto, attivo|
        if passivo = passivi_data_matrix.delete(conto)
          if(Helpers::ApplicationHelper.real(attivo[2]) >= Helpers::ApplicationHelper.real(passivo[2]))
            attivita_data_matrix[conto] = [attivo[0], attivo[1], (attivo[2] - passivo[2])]
          else
            passivita_data_matrix[conto] = [passivo[0], passivo[1], (passivo[2] - attivo[2])]
          end
        else
          attivita_data_matrix[conto] = attivo
        end
      end

      passivi_data_matrix.each do |conto, passivo|
        passivita_data_matrix[conto] = passivo
      end

      [attivita_data_matrix, passivita_data_matrix]

    end

    # gestione report bilancio conto economico
    def report_conto_economico_old()
      costi_data_matrix = {}
      ricavi_data_matrix = {}

      # COSTI
      c_data_matrix = {}
      r_data_matrix = {}

      costi = ScritturaPd.all(build_costi_report_conditions())

      costi.each do |dati_costi|
        conto = dati_costi.codice.to_i
        c_data_matrix[conto] = [conto, dati_costi.descrizione, dati_costi.importo]
        self.totale_costi += dati_costi.importo
      end

      costi_nc = ScritturaPd.all(build_costi_nc_report_conditions())

      costi_nc.each do |dati_costi_nc|
        conto = dati_costi_nc.codice.to_i
        if c_data_matrix[conto]
          c_data_matrix[conto][2] += dati_costi_nc.importo
        else
          c_data_matrix[conto] = [conto, dati_costi_nc.descrizione, dati_costi_nc.importo]
        end
        self.totale_costi += dati_costi_nc.importo
      end

      # RICAVI
      ricavi = ScritturaPd.all(build_ricavi_report_conditions())

      ricavi.each do |dati_ricavi|
        conto = dati_ricavi.codice.to_i
        r_data_matrix[conto] = [conto, dati_ricavi.descrizione, dati_ricavi.importo]
        self.totale_ricavi += dati_ricavi.importo
      end

      ricavi_nc = ScritturaPd.all(build_ricavi_nc_report_conditions())

      ricavi_nc.each do |dati_ricavi_nc|
        conto = dati_ricavi_nc.codice.to_i
        if r_data_matrix[conto]
          r_data_matrix[conto][2] += dati_ricavi_nc.importo
        else
          r_data_matrix[conto] = [conto, dati_ricavi_nc.descrizione, dati_ricavi_nc.importo]
        end
        self.totale_ricavi += dati_ricavi_nc.importo
      end

      c_data_matrix.each do |conto, costo|
        if ricavo = r_data_matrix.delete(conto)
          if(Helpers::ApplicationHelper.real(costo[2]) >= Helpers::ApplicationHelper.real(ricavo[2]))
            costi_data_matrix[conto] = [costo[0], costo[1], (costo[2] - ricavo[2])]
          else
            ricavi_data_matrix[conto] = [ricavo[0], ricavo[1], (ricavo[2] - costo[2])]
          end
        else
          costi_data_matrix[conto] = costo
        end
      end

      r_data_matrix.each do |conto, ricavo|
        ricavi_data_matrix[conto] = ricavo
      end

      costi = costi_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}
      ricavi = ricavi_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}

      [costi, ricavi]

    end

    def report_stato_patrimoniale_old()
      attivita_data_matrix = {}
      passivita_data_matrix = {}

      saldi_attivi_data_matrix, saldi_passivi_data_matrix = report_saldi_stato_patrimoniale()

      # ATTIVI
      attivi_data_matrix = {}
      passivi_data_matrix = {}

      attivi = ScritturaPd.all(build_attivi_report_conditions())

      attivi.each do |dati_attivi|
        conto = dati_attivi.codice.to_i
        attivi_data_matrix[conto] = [conto, dati_attivi.descrizione, dati_attivi.importo]
      end

      attivi_nc = ScritturaPd.all(build_attivi_nc_report_conditions())

      attivi_nc.each do |dati_attivi_nc|
        conto = dati_attivi_nc.codice.to_i
        if attivi_data_matrix[conto]
          attivi_data_matrix[conto][2] -= dati_attivi_nc.importo
        else
          attivi_data_matrix[conto] = [conto, dati_attivi_nc.descrizione, (dati_attivi_nc.importo * -1)]
        end
      end

      # PASSIVI
      passivi = ScritturaPd.all(build_passivi_report_conditions())

      passivi.each do |dati_passivi|
        conto = dati_passivi.codice.to_i
        passivi_data_matrix[conto] = [conto, dati_passivi.descrizione, dati_passivi.importo]
      end

      passivi_nc = ScritturaPd.all(build_passivi_nc_report_conditions())

      passivi_nc.each do |dati_passivi_nc|
        conto = dati_passivi_nc.codice.to_i
        if passivi_data_matrix[conto]
          passivi_data_matrix[conto][2] -= dati_passivi_nc.importo
        else
          passivi_data_matrix[conto] = [conto, dati_passivi_nc.descrizione, (dati_passivi_nc.importo * -1)]
        end
      end

      # merge tra attivi, passivi e saldi
      attivi_data_matrix.each do |conto, attivo|
        totale_attivo = saldi_attivi_data_matrix.delete(conto)[2] rescue 0.0
        totale_attivo += attivo[2]
        totale_passivo = saldi_passivi_data_matrix.delete(conto)[2] rescue 0.0
        totale_passivo += passivi_data_matrix.delete(conto)[2] rescue 0.0


        if(Helpers::ApplicationHelper.real(totale_attivo) >= Helpers::ApplicationHelper.real(totale_passivo))
          attivita_data_matrix[conto] = [attivo[0], attivo[1], (totale_attivo - totale_passivo)]
          self.totale_attivita += (totale_attivo - totale_passivo)
        else
          passivita_data_matrix[conto] = [attivo[0], attivo[1], (totale_passivo - totale_attivo)]
          self.totale_passivita += (totale_passivo - totale_attivo)
        end

#        if passivo = passivi_data_matrix.delete(conto)
#          if(Helpers::ApplicationHelper.real(attivo[2]) >= Helpers::ApplicationHelper.real(passivo[2]))
#            attivita_data_matrix[conto] = [attivo[0], attivo[1], (attivo[2] - passivo[2])]
#          else
#            passivita_data_matrix[conto] = [passivo[0], passivo[1], (passivo[2] - attivo[2])]
#          end
#        else
#          attivita_data_matrix[conto] = attivo
#        end
      end

      passivi_data_matrix.each do |conto, passivo|
        passivita_data_matrix[conto] = passivo
        self.totale_passivita += passivo[2]
      end

      # IVA
      iva_acquisti = RigaFatturaPdc.sum(:iva, build_acquisti_report_conditions())
      detrazione_iva_acquisti = RigaFatturaPdc.sum(:detrazione, build_acquisti_report_conditions())
      iva_vendite = RigaFatturaPdc.sum(:iva, build_vendite_report_conditions())
      detrazione_iva_vendite = RigaFatturaPdc.sum(:detrazione, build_vendite_report_conditions())

      iva_detraibile = (iva_acquisti - detrazione_iva_acquisti)
      iva_detraibile += saldi_attivi_data_matrix.delete(30000)[2] rescue 0.0
      iva_indetraibile = (iva_vendite - detrazione_iva_vendite)
      iva_indetraibile += saldi_passivi_data_matrix.delete(30000)[2] rescue 0.0
      iva_indetraibile += Corrispettivo.sum(:iva, build_iva_corrispettivi_report_conditions())

      if(Helpers::ApplicationHelper.real(iva_detraibile) >= Helpers::ApplicationHelper.real(iva_indetraibile))
        attivita_data_matrix[30000] = ['30000', 'IVA C/ERARIO', (iva_detraibile - iva_indetraibile)]
        self.totale_attivita += (iva_detraibile - iva_indetraibile)
      else
        passivita_data_matrix[30000] = ['30000', 'IVA C/ERARIO', (iva_indetraibile - iva_detraibile)]
        self.totale_passivita += (iva_indetraibile - iva_detraibile)
      end

      # FORNITORI
      totale_fatture_fornitori = FatturaFornitore.sum(:importo, build_fatture_fornitori_report_conditions("fatture_fornitori.nota_di_credito = 0"))
      totale_fatture_fornitori += saldi_passivi_data_matrix.delete(46000)[2] rescue 0.0
      totale_fatture_fornitori -= FatturaFornitore.sum(:importo, build_fatture_fornitori_report_conditions("fatture_fornitori.nota_di_credito = 1"))
      totale_pagamenti_fatture_fornitori = PagamentoFatturaFornitore.sum(:importo, build_pagamenti_fatture_fornitori_report_conditions("fatture_fornitori.nota_di_credito = 0"))
      totale_pagamenti_fatture_fornitori += saldi_attivi_data_matrix.delete(46000)[2] rescue 0.0
      totale_pagamenti_fatture_fornitori -= PagamentoFatturaFornitore.sum(:importo, build_pagamenti_fatture_fornitori_report_conditions("fatture_fornitori.nota_di_credito = 1"))

      if(Helpers::ApplicationHelper.real(totale_fatture_fornitori) >= Helpers::ApplicationHelper.real(totale_pagamenti_fatture_fornitori))
        passivita_data_matrix[46000] = ['46000', 'FORNITORI', (totale_fatture_fornitori - totale_pagamenti_fatture_fornitori)]
        self.totale_passivita += (totale_fatture_fornitori - totale_pagamenti_fatture_fornitori)
      else
        attivita_data_matrix[46000] = ['46000', 'FORNITORI', (totale_pagamenti_fatture_fornitori - totale_fatture_fornitori)]
        self.totale_attivita += (totale_pagamenti_fatture_fornitori - totale_fatture_fornitori)
      end

      # CLIENTI
      totale_fatture_clienti = FatturaClienteScadenzario.sum(:importo, build_fatture_clienti_report_conditions("fatture_clienti.nota_di_credito = 0"))
      totale_fatture_clienti += saldi_attivi_data_matrix.delete(22000)[2] rescue 0.0
      totale_fatture_clienti -= FatturaClienteScadenzario.sum(:importo, build_fatture_clienti_report_conditions("fatture_clienti.nota_di_credito = 1"))
      totale_incassi_fatture_clienti = PagamentoFatturaCliente.sum(:importo, build_incassi_fatture_clienti_report_conditions("fatture_clienti.nota_di_credito = 0"))
      totale_incassi_fatture_clienti += saldi_passivi_data_matrix.delete(22000)[2] rescue 0.0
      totale_incassi_fatture_clienti -= PagamentoFatturaCliente.sum(:importo, build_incassi_fatture_clienti_report_conditions("fatture_clienti.nota_di_credito = 1"))

      if(Helpers::ApplicationHelper.real(totale_fatture_clienti) >= Helpers::ApplicationHelper.real(totale_incassi_fatture_clienti))
        attivita_data_matrix[22000] = ['22000', 'CLIENTI', (totale_fatture_clienti - totale_incassi_fatture_clienti)]
        self.totale_attivita += (totale_fatture_clienti - totale_incassi_fatture_clienti)
      else
        passivita_data_matrix[22000] = ['22000', 'CLIENTI', (totale_incassi_fatture_clienti - totale_fatture_clienti)]
        self.totale_passivita += (totale_incassi_fatture_clienti - totale_fatture_clienti)
      end

      # CORRISPETTIVI
      corrispettivi = Corrispettivo.all(build_importi_corrispettivi_report_conditions())

      corrispettivi.each do |dati_corrispettivi|
        conto = dati_corrispettivi.codice.to_i
        totale_corrispettivi = dati_corrispettivi.importo
        totale_corrispettivi += saldi_attivi_data_matrix.delete(conto)[2] rescue 0.0
        if attivita_data_matrix[conto]
          attivita_data_matrix[conto][2] += totale_corrispettivi
        else
          attivita_data_matrix[conto] = [conto, dati_corrispettivi.descrizione, totale_corrispettivi]
        end
        self.totale_attivita += totale_corrispettivi
      end

      # SALDI CONTI ATTIVI RESIDUI
      saldi_attivi_data_matrix.each do |conto, attivo|
        attivita_data_matrix[conto] = attivo
        self.totale_attivita += attivo[2]
      end

      # SALDI CONTI PASSIVI RESIDUI
      saldi_passivi_data_matrix.each do |conto, passivo|
        passivita_data_matrix[conto] = passivo
        self.totale_passivita += passivo[2]
      end

      attivita = attivita_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}
      passivita = passivita_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}

      [attivita, passivita]

    end

    def report_saldi_stato_patrimoniale_old()
      attivita_data_matrix = {}
      passivita_data_matrix = {}

      attivi_data_matrix = {}
      passivi_data_matrix = {}

      attivi = ScritturaPd.all(build_attivi_report_conditions(true))

      attivi.each do |dati_attivi|
        conto = dati_attivi.codice.to_i
        attivi_data_matrix[conto] = [conto, dati_attivi.descrizione, dati_attivi.importo]
      end

      attivi_nc = ScritturaPd.all(build_attivi_nc_report_conditions(true))

      attivi_nc.each do |dati_attivi_nc|
        conto = dati_attivi_nc.codice.to_i
        if attivi_data_matrix[conto]
          attivi_data_matrix[conto][2] -= dati_attivi_nc.importo
        else
          attivi_data_matrix[conto] = [conto, dati_attivi_nc.descrizione, (dati_attivi_nc.importo * -1)]
        end
      end

      passivi = ScritturaPd.all(build_passivi_report_conditions(true))

      passivi.each do |dati_passivi|
        conto = dati_passivi.codice.to_i
        passivi_data_matrix[conto] = [conto, dati_passivi.descrizione, dati_passivi.importo]
      end

      passivi_nc = ScritturaPd.all(build_passivi_nc_report_conditions(true))

      passivi_nc.each do |dati_passivi_nc|
        conto = dati_passivi_nc.codice.to_i
        if passivi_data_matrix[conto]
          passivi_data_matrix[conto][2] -= dati_passivi_nc.importo
        else
          passivi_data_matrix[conto] = [conto, dati_passivi_nc.descrizione, (dati_passivi_nc.importo * -1)]
        end
      end

      attivi_data_matrix.each do |conto, attivo|
        if passivo = passivi_data_matrix.delete(conto)
          if(Helpers::ApplicationHelper.real(attivo[2]) >= Helpers::ApplicationHelper.real(passivo[2]))
            attivita_data_matrix[conto] = [attivo[0], attivo[1], (attivo[2] - passivo[2])]
          else
            passivita_data_matrix[conto] = [passivo[0], passivo[1], (passivo[2] - attivo[2])]
          end
        else
          attivita_data_matrix[conto] = attivo
        end
      end

      passivi_data_matrix.each do |conto, passivo|
        passivita_data_matrix[conto] = passivo
      end

      iva_acquisti = RigaFatturaPdc.sum(:iva, build_acquisti_report_conditions(true))
      detrazione_iva_acquisti = RigaFatturaPdc.sum(:detrazione, build_acquisti_report_conditions(true))
      iva_vendite = RigaFatturaPdc.sum(:iva, build_vendite_report_conditions(true))
      detrazione_iva_vendite = RigaFatturaPdc.sum(:detrazione, build_vendite_report_conditions(true))

      iva_detraibile = (iva_acquisti - detrazione_iva_acquisti)
      iva_indetraibile = (iva_vendite - detrazione_iva_vendite)
      iva_indetraibile += Corrispettivo.sum(:iva, build_iva_corrispettivi_report_conditions(true))

      if(Helpers::ApplicationHelper.real(iva_detraibile) >= Helpers::ApplicationHelper.real(iva_indetraibile))
        attivita_data_matrix[30000] = ['30000', 'IVA C/ERARIO', (iva_detraibile - iva_indetraibile)]
      else
        passivita_data_matrix[30000] = ['30000', 'IVA C/ERARIO', (iva_indetraibile - iva_detraibile)]
      end

      totale_fatture_fornitori = FatturaFornitore.sum(:importo, build_fatture_fornitori_report_conditions("fatture_fornitori.nota_di_credito = 0", true))
      totale_fatture_fornitori -= FatturaFornitore.sum(:importo, build_fatture_fornitori_report_conditions("fatture_fornitori.nota_di_credito = 1", true))
      totale_pagamenti_fatture_fornitori = PagamentoFatturaFornitore.sum(:importo, build_pagamenti_fatture_fornitori_report_conditions("fatture_fornitori.nota_di_credito = 0", true))
      totale_pagamenti_fatture_fornitori -= PagamentoFatturaFornitore.sum(:importo, build_pagamenti_fatture_fornitori_report_conditions("fatture_fornitori.nota_di_credito = 1", true))

      if(Helpers::ApplicationHelper.real(totale_fatture_fornitori) >= Helpers::ApplicationHelper.real(totale_pagamenti_fatture_fornitori))
        passivita_data_matrix[46000] = ['46000', 'FORNITORI', (totale_fatture_fornitori - totale_pagamenti_fatture_fornitori)]
      else
        attivita_data_matrix[46000] = ['46000', 'FORNITORI', (totale_pagamenti_fatture_fornitori - totale_fatture_fornitori)]
      end

      totale_fatture_clienti = FatturaClienteScadenzario.sum(:importo, build_fatture_clienti_report_conditions("fatture_clienti.nota_di_credito = 0", true))
      totale_fatture_clienti -= FatturaClienteScadenzario.sum(:importo, build_fatture_clienti_report_conditions("fatture_clienti.nota_di_credito = 1", true))
      totale_incassi_fatture_clienti = PagamentoFatturaCliente.sum(:importo, build_incassi_fatture_clienti_report_conditions("fatture_clienti.nota_di_credito = 0", true))
      totale_incassi_fatture_clienti -= PagamentoFatturaCliente.sum(:importo, build_incassi_fatture_clienti_report_conditions("fatture_clienti.nota_di_credito = 1", true))

      if(Helpers::ApplicationHelper.real(totale_fatture_clienti) >= Helpers::ApplicationHelper.real(totale_incassi_fatture_clienti))
        attivita_data_matrix[22000] = ['22000', 'CLIENTI', (totale_fatture_clienti - totale_incassi_fatture_clienti)]
      else
        passivita_data_matrix[22000] = ['22000', 'CLIENTI', (totale_incassi_fatture_clienti - totale_fatture_clienti)]
      end

      corrispettivi = Corrispettivo.all(build_importi_corrispettivi_report_conditions(true))

      corrispettivi.each do |dati_corrispettivi|
        conto = dati_corrispettivi.codice.to_i
        if attivita_data_matrix[conto]
          attivita_data_matrix[conto][2] += dati_corrispettivi.importo
        else
          attivita_data_matrix[conto] = [conto, dati_corrispettivi.descrizione, dati_corrispettivi.importo]
        end
      end

      [attivita_data_matrix, passivita_data_matrix]

    end

    # gestione report bilancio conto economico
    def report_conto_economico_old()
      costi_data_matrix = {}
      ricavi_data_matrix = {}

      # COSTI
      c_data_matrix = {}
      r_data_matrix = {}

      costi = ScritturaPd.all(build_costi_report_conditions())

      costi.each do |dati_costi|
        conto = dati_costi.codice.to_i
        c_data_matrix[conto] = [conto, dati_costi.descrizione, dati_costi.importo]
        self.totale_costi += dati_costi.importo
      end

      costi_nc = ScritturaPd.all(build_costi_nc_report_conditions())

      costi_nc.each do |dati_costi_nc|
        conto = dati_costi_nc.codice.to_i
        if c_data_matrix[conto]
          c_data_matrix[conto][2] -= dati_costi_nc.importo
        else
          c_data_matrix[conto] = [conto, dati_costi_nc.descrizione, (dati_costi_nc.importo * -1)]
        end
        self.totale_costi -= dati_costi_nc.importo
      end

      # RICAVI
      ricavi = ScritturaPd.all(build_ricavi_report_conditions())

      ricavi.each do |dati_ricavi|
        conto = dati_ricavi.codice.to_i
        r_data_matrix[conto] = [conto, dati_ricavi.descrizione, dati_ricavi.importo]
        self.totale_ricavi += dati_ricavi.importo
      end

      ricavi_nc = ScritturaPd.all(build_ricavi_nc_report_conditions())

      ricavi_nc.each do |dati_ricavi_nc|
        conto = dati_ricavi_nc.codice.to_i
        if r_data_matrix[conto]
          r_data_matrix[conto][2] -= dati_ricavi_nc.importo
        else
          r_data_matrix[conto] = [conto, dati_ricavi_nc.descrizione, (dati_ricavi_nc.importo * -1)]
        end
        self.totale_ricavi -= dati_ricavi_nc.importo
      end

      c_data_matrix.each do |conto, costo|
        if ricavo = r_data_matrix.delete(conto)
          if(Helpers::ApplicationHelper.real(costo[2]) >= Helpers::ApplicationHelper.real(ricavo[2]))
            costi_data_matrix[conto] = [costo[0], costo[1], (costo[2] - ricavo[2])]
          else
            ricavi_data_matrix[conto] = [ricavo[0], ricavo[1], (ricavo[2] - costo[2])]
          end
        else
          costi_data_matrix[conto] = costo
        end
      end

      r_data_matrix.each do |conto, ricavo|
        ricavi_data_matrix[conto] = ricavo
      end

      acquisti = RigaFatturaPdc.all(build_dettaglio_iva_acquisti_report_conditions("fatture_fornitori.nota_di_credito = 0"))
      vendite = RigaFatturaPdc.all(build_dettaglio_iva_vendite_report_conditions("fatture_clienti.nota_di_credito = 0"))

      acquisti.each do |dati_acquisti|
        conto = dati_acquisti.codice.to_i
        totale_acquisti = (dati_acquisti.imponibile + dati_acquisti.iva)
        if costi_data_matrix[conto]
          costi_data_matrix[conto][2] += totale_acquisti
        else
          costi_data_matrix[conto] = [conto, dati_acquisti.descrizione, totale_acquisti]
        end
        self.totale_costi += totale_acquisti
      end

      vendite.each do |dati_vendite|
        conto = dati_vendite.codice.to_i
        totale_vendite = (dati_vendite.imponibile + dati_vendite.iva)
        if ricavi_data_matrix[conto]
          ricavi_data_matrix[conto][2] += totale_vendite
        else
          ricavi_data_matrix[conto] = [conto, dati_vendite.descrizione, totale_vendite]
        end
        self.totale_ricavi += totale_vendite
      end

      acquisti_nc = RigaFatturaPdc.all(build_dettaglio_iva_acquisti_report_conditions("fatture_fornitori.nota_di_credito = 1"))
      vendite_nc = RigaFatturaPdc.all(build_dettaglio_iva_vendite_report_conditions("fatture_clienti.nota_di_credito = 1"))

      acquisti_nc.each do |dati_acquisti_nc|
        conto = dati_acquisti_nc.codice.to_i
        totale_acquisti_nc = (dati_acquisti_nc.imponibile + dati_acquisti_nc.iva)
        if costi_data_matrix[conto]
          costi_data_matrix[conto][2] -= totale_acquisti_nc
        else
          costi_data_matrix[conto] = [conto, dati_acquisti_nc.descrizione, (totale_acquisti_nc * -1)]
        end
        self.totale_costi -= totale_acquisti_nc
      end

      vendite_nc.each do |dati_vendite_nc|
        conto = dati_vendite_nc.codice.to_i
        totale_vendite_nc = (dati_vendite_nc.imponibile + dati_vendite_nc.iva)
        if ricavi_data_matrix[conto]
          ricavi_data_matrix[conto][2] -= totale_vendite_nc
        else
          ricavi_data_matrix[conto] = [conto, dati_vendite_nc.descrizione, (totale_vendite_nc * -1)]
        end
        self.totale_ricavi -= totale_vendite_nc
      end

      corrispettivi = Corrispettivo.all(build_imponibili_corrispettivi_report_conditions())

      corrispettivi.each do |dati_corrispettivi|
        conto = dati_corrispettivi.codice.to_i
        if ricavi_data_matrix[conto]
          ricavi_data_matrix[conto][2] += dati_corrispettivi.imponibile
        else
          ricavi_data_matrix[conto] = [conto, dati_corrispettivi.descrizione, dati_corrispettivi.imponibile]
        end
        self.totale_ricavi += dati_corrispettivi.imponibile
      end

      costi = costi_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}
      ricavi = ricavi_data_matrix.sort.map {|e| e.last}.reject {|e| e[2].zero?}

      [costi, ricavi]

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

    def build_attivi_nc_report_conditions(saldi = false)
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

      query_str << "partita_doppia.nc_pdc_dare_id is not null"

      query_str << "partita_doppia.azienda_id = ?"
      parametri << Azienda.current

      query_str << "categorie_pdc.type = 'Attivo'"

      {:select => "sum(partita_doppia.importo) as importo, pdc.codice as codice, pdc.descrizione as descrizione",
        :conditions => [query_str.join(' AND '), *parametri],
        :joins => "INNER JOIN pdc ON partita_doppia.nc_pdc_dare_id = pdc.id
                   INNER JOIN categorie_pdc ON pdc.categoria_pdc_id = categorie_pdc.id",
        :group => 'pdc.codice, pdc.descrizione'
      }
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

    def build_passivi_nc_report_conditions(saldi = false)
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
      
      query_str << "partita_doppia.nc_pdc_avere_id is not null"

      query_str << "partita_doppia.azienda_id = ?"
      parametri << Azienda.current

      query_str << "categorie_pdc.type = 'Passivo'"

      {:select => "sum(partita_doppia.importo) as importo, pdc.codice as codice, pdc.descrizione as descrizione",
        :conditions => [query_str.join(' AND '), *parametri],
        :joins => "INNER JOIN pdc ON partita_doppia.nc_pdc_avere_id = pdc.id
                   INNER JOIN categorie_pdc ON pdc.categoria_pdc_id = categorie_pdc.id",
        :group => 'pdc.codice, pdc.descrizione'
      }
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

    def build_costi_nc_report_conditions()
      query_str = []
      parametri = []

      query_str << "partita_doppia.data_operazione >= ? "
      parametri << get_date(:from)
      query_str << "partita_doppia.data_operazione <= ? "
      parametri << get_date(:to)

      query_str << "partita_doppia.nc_pdc_dare_id is not null"

      query_str << "partita_doppia.azienda_id = ?"
      parametri << Azienda.current

      query_str << "categorie_pdc.type = 'Costo'"

      {:select => "sum(partita_doppia.importo) as importo, pdc.codice as codice, pdc.descrizione as descrizione",
        :conditions => [query_str.join(' AND '), *parametri],
        :joins => "INNER JOIN pdc ON partita_doppia.nc_pdc_dare_id = pdc.id
                   INNER JOIN categorie_pdc ON pdc.categoria_pdc_id = categorie_pdc.id",
        :group => 'pdc.codice, pdc.descrizione'
      }
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

    def build_ricavi_nc_report_conditions()
      query_str = []
      parametri = []

      query_str << "partita_doppia.data_operazione >= ? "
      parametri << get_date(:from)
      query_str << "partita_doppia.data_operazione <= ? "
      parametri << get_date(:to)

      query_str << "partita_doppia.nc_pdc_avere_id is not null"

      query_str << "partita_doppia.azienda_id = ?"
      parametri << Azienda.current

      query_str << "categorie_pdc.type = 'Ricavo'"

      {:select => "sum(partita_doppia.importo) as importo, pdc.codice as codice, pdc.descrizione as descrizione",
        :conditions => [query_str.join(' AND '), *parametri],
        :joins => "INNER JOIN pdc ON partita_doppia.nc_pdc_avere_id = pdc.id
                   INNER JOIN categorie_pdc ON pdc.categoria_pdc_id = categorie_pdc.id",
        :group => 'pdc.codice, pdc.descrizione'
      }
    end

    def build_acquisti_report_conditions(saldi = false)
      query_str = []
      parametri = []

      if saldi
        query_str << "fatture_fornitori.data_registrazione < ? "
        parametri << get_date(:from)
      else
        query_str << "fatture_fornitori.data_registrazione >= ? "
        parametri << get_date(:from)
        query_str << "fatture_fornitori.data_registrazione <= ? "
        parametri << get_date(:to)
      end

      query_str << "fatture_fornitori.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri],
        :joins => :fattura_fornitore
      }
    end

    def build_dettaglio_iva_acquisti_report_conditions(additional_criteria)
      query_str = []
      parametri = []

      query_str << "fatture_fornitori.data_registrazione >= ? "
      parametri << get_date(:from)
      query_str << "fatture_fornitori.data_registrazione <= ? "
      parametri << get_date(:to)

      query_str << additional_criteria if additional_criteria

      query_str << "fatture_fornitori.azienda_id = ?"
      parametri << Azienda.current

      {:select => "sum(righe_fattura_pdc.imponibile) as imponibile, sum(righe_fattura_pdc.iva) as iva, pdc.codice as codice, pdc.descrizione as descrizione",
        :conditions => [query_str.join(' AND '), *parametri],
        :joins => "INNER JOIN fatture_fornitori on righe_fattura_pdc.fattura_fornitore_id = fatture_fornitori.id INNER JOIN pdc on righe_fattura_pdc.pdc_id = pdc.id",
        :group => 'pdc.codice, pdc.descrizione'
      }
    end

    def build_vendite_report_conditions(saldi = false)
      query_str = []
      parametri = []

      if saldi
        query_str << "fatture_clienti.data_emissione < ? "
        parametri << get_date(:from)
      else
        query_str << "fatture_clienti.data_emissione >= ? "
        parametri << get_date(:from)
        query_str << "fatture_clienti.data_emissione <= ? "
        parametri << get_date(:to)
      end

      query_str << "fatture_clienti.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri],
        :joins => :fattura_cliente
      }
    end

    def build_dettaglio_iva_vendite_report_conditions(additional_criteria)
      query_str = []
      parametri = []

      query_str << "fatture_clienti.data_emissione >= ? "
      parametri << get_date(:from)
      query_str << "fatture_clienti.data_emissione <= ? "
      parametri << get_date(:to)

      query_str << additional_criteria if additional_criteria

      query_str << "fatture_clienti.da_scadenzario = 1"

      query_str << "fatture_clienti.azienda_id = ?"
      parametri << Azienda.current

      {:select => "sum(righe_fattura_pdc.imponibile) as imponibile, sum(righe_fattura_pdc.iva) as iva, pdc.codice as codice, pdc.descrizione as descrizione",
        :conditions => [query_str.join(' AND '), *parametri],
        :joins => "INNER JOIN fatture_clienti on righe_fattura_pdc.fattura_cliente_id = fatture_clienti.id INNER JOIN pdc on righe_fattura_pdc.pdc_id = pdc.id",
        :group => 'pdc.codice, pdc.descrizione'
      }
    end

    def build_fatture_fornitori_report_conditions(additional_criteria, saldi = false)
      query_str = []
      parametri = []

      if saldi
        query_str << "fatture_fornitori.data_registrazione < ? "
        parametri << get_date(:from)
      else
        query_str << "fatture_fornitori.data_registrazione >= ? "
        parametri << get_date(:from)
        query_str << "fatture_fornitori.data_registrazione <= ? "
        parametri << get_date(:to)
      end

      query_str << additional_criteria if additional_criteria

      query_str << "fatture_fornitori.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri]}

    end

    def build_fatture_clienti_report_conditions(additional_criteria, saldi = false)
      query_str = []
      parametri = []

      if saldi
        query_str << "fatture_clienti.data_emissione < ? "
        parametri << get_date(:from)
      else
        query_str << "fatture_clienti.data_emissione >= ? "
        parametri << get_date(:from)
        query_str << "fatture_clienti.data_emissione <= ? "
        parametri << get_date(:to)
      end

      query_str << additional_criteria if additional_criteria

      query_str << "fatture_clienti.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri]}

    end

    def build_pagamenti_fatture_fornitori_report_conditions(additional_criteria, saldo = false)
      query_str = []
      parametri = []

      if saldo
        query_str << "pagamenti_fatture_fornitori.data_registrazione < ? "
        parametri << get_date(:from)
      else
        query_str << "pagamenti_fatture_fornitori.data_registrazione >= ? "
        parametri << get_date(:from)
        query_str << "pagamenti_fatture_fornitori.data_registrazione <= ? "
        parametri << get_date(:to)
      end

      query_str << "pagamenti_fatture_fornitori.registrato_in_prima_nota = 1 "

      query_str << additional_criteria if additional_criteria

      query_str << "fatture_fornitori.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri],
        :joins => :fattura_fornitore
      }

    end

    def build_incassi_fatture_clienti_report_conditions(additional_criteria, saldi = false)
      query_str = []
      parametri = []

      if saldi
        query_str << "pagamenti_fatture_clienti.data_registrazione < ? "
        parametri << get_date(:from)
      else
        query_str << "pagamenti_fatture_clienti.data_registrazione >= ? "
        parametri << get_date(:from)
        query_str << "pagamenti_fatture_clienti.data_registrazione <= ? "
        parametri << get_date(:to)
      end

      query_str << "pagamenti_fatture_clienti.registrato_in_prima_nota = 1 "

      query_str << additional_criteria if additional_criteria

      query_str << "fatture_clienti.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri],
        :joins => :fattura_cliente_scadenzario
      }

    end

    def build_iva_corrispettivi_report_conditions(saldi = false)
      query_str = []
      parametri = []

      if saldi
        query_str << "corrispettivi.data < ? "
        parametri << get_date(:from)
      else
        query_str << "corrispettivi.data >= ? "
        parametri << get_date(:from)
        query_str << "corrispettivi.data <= ? "
        parametri << get_date(:to)
      end

      query_str << "corrispettivi.azienda_id = ?"
      parametri << Azienda.current

      {:conditions => [query_str.join(' AND '), *parametri]}
    end

    def build_importi_corrispettivi_report_conditions(saldi = false)
      query_str = []
      parametri = []

      if saldi
        query_str << "corrispettivi.data < ? "
        parametri << get_date(:from)
      else
        query_str << "corrispettivi.data >= ? "
        parametri << get_date(:from)
        query_str << "corrispettivi.data <= ? "
        parametri << get_date(:to)
      end

      query_str << "corrispettivi.azienda_id = ?"
      parametri << Azienda.current

      {:select => "sum(corrispettivi.importo) as importo, pdc.codice as codice, pdc.descrizione as descrizione",
        :conditions => [query_str.join(' AND '), *parametri],
        :joins => "INNER JOIN pdc ON corrispettivi.pdc_dare_id = pdc.id",
        :group => 'pdc.codice, pdc.descrizione'
      }

    end

    def build_imponibili_corrispettivi_report_conditions()
      query_str = []
      parametri = []

      query_str << "corrispettivi.data >= ? "
      parametri << get_date(:from)
      query_str << "corrispettivi.data <= ? "
      parametri << get_date(:to)

      query_str << "corrispettivi.azienda_id = ?"
      parametri << Azienda.current

      {:select => "sum(corrispettivi.imponibile) as imponibile, pdc.codice as codice, pdc.descrizione as descrizione",
        :conditions => [query_str.join(' AND '), *parametri],
        :joins => "INNER JOIN pdc ON corrispettivi.pdc_avere_id = pdc.id",
        :group => 'pdc.codice, pdc.descrizione'
      }

    end
  end
end