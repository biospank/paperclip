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
        [:codice, :descrizione],
        build_pdc_dialog_conditions())
    end

    def build_pdc_dialog_conditions()
      query_str = []
      parametri = []

      filtro.build_conditions(query_str, parametri) if filtro

      {:conditions => [query_str.join(' AND '), *parametri],
       :order => 'codice'}
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

    # gestione aliquote

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
    
  end
end