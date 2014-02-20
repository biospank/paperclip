# encoding: utf-8

module Controllers
  module BaseController
    include Helpers::Logger
    include Models
      
    # flag che indica se l'applicazione e' loccata
    @@locked = false
    # flag che indica la presenza della finestra delle scadenze
    # da eliminare
    #@@waiting = false

    # accessor
    def locked=(bool)
      @@locked = bool
    end
    
    def locked()
      @@locked
    end
    
    alias locked? locked 
    
    def to_sql_year(column)
      case ActiveRecord::Base.connection.adapter_name().downcase.to_sym
      when :sqlite
        "strftime('%Y', #{column})"
      when :postgresql
        "to_char(#{column}, 'YYYY')"
      end
    end

    def to_sql_month(column)
      case ActiveRecord::Base.connection.adapter_name().downcase.to_sym
      when :sqlite
        "strftime('%m', #{column})"
      when :postgresql
        "to_char(#{column}, 'MM')"
      end
    end

    def get_date(which)
      case which
      when :from
        if filtro.dal
          return filtro.dal
        else
          if filtro.al
            return filtro.al.beginning_of_year
          else
            return Date.new((filtro.anno || Date.today.year).to_i).beginning_of_year
          end
        end
      when :to
        if filtro.al
          return filtro.al
        else
          if filtro.dal
            return filtro.dal.end_of_year
          else
            return Date.new((filtro.anno || Date.today.year).to_i).end_of_year
          end
        end
      end
    end

    def load_azienda(id)
      Azienda.find(id, :include => [:dati_azienda])
    end

    def load_moduli_azienda()
      ModuloAzienda.search(:all, :conditions => {:attivo => 1}, :include => [:modulo])
    end

    def load_cliente(id)
      Cliente.find(id)
    end
    
    def load_cliente_by_p_iva(p_iva)
      Cliente.search(:first, :conditions => {:p_iva => p_iva})
    end
    
    def load_fornitore(id)
      Fornitore.find(id)
    end
    
    def load_incasso(id)
      PagamentoFatturaCliente.find(id)
    end
    
    def load_pagamento(id)
      PagamentoFatturaFornitore.find(id)
    end
    
    def load_tipo_pagamento_cliente(id)
      TipoPagamentoCliente.find(id)
    end
      
    def load_tipo_pagamento_cliente_by_codice(codice)
      TipoPagamentoCliente.by_codice(codice).first
    end
      
    def load_tipo_pagamento_fornitore(id)
      TipoPagamentoFornitore.find(id)
    end
      
    def load_tipo_pagamento_fornitore_by_codice(codice)
      TipoPagamentoFornitore.by_codice(codice).first
    end
      
    def load_banca(id)
      Banca.find(id)
    end
      
    def load_aliquota(id)
      Aliquota.find(id)
    end

    def load_norma(id)
      Norma.find(id)
    end

    def load_pdc(id)
      Pdc.find(id)
    end

    def load_categoria_pdc(id)
      CategoriaPdc.find(id)
    end

    def load_aliquota_by_codice(codice)
      Aliquota.find_by_codice(codice)
    end
    
    def search_progressivo(klass, anno)
      klass.search(:first, :conditions => ["anno_rif = ?", anno])
    end
      
    def load_anni_contabili(klass, column=nil)
      # non funziona
      #klass.calculate(:distinct, "strftime('%Y', #{(column || 'data_emissione')})")
      # non funziona con order
#        klass.find(:all, 
#                    :select => "distinct(strftime('%Y', #{(column || 'data_emissione')})) as anno",
#                    :order => "anno").map {|row| row[:anno]}
#        klass.find(:all, 
#                    :select => "strftime('%Y', #{(column || 'data_emissione')}) as anno",
#                    :conditions => ["azienda_id = ?", Azienda.current],
#                    :group => "anno",
#                    :order => "anno").map {|row| row[:anno]}
      klass.search(:all, :select => "#{to_sql_year((column || 'data_emissione'))} as anno",
                  :group => "anno",
                  :order => "anno").map {|row| row[:anno]}.push(Date.today.year.to_s).compact.uniq
    end

    def load_anni_contabili_progressivi(klass)
      klass.search(:all, :order => "anno_rif").map {|row| row[:anno_rif].to_s}
    end

    def search_ritenute()
      Ritenuta.search(:all, :order => 'codice')
    end

    def search_aliquote()
      Aliquota.search(:all, :order => 'codice')
    end

    def search_norma()
      Norma.search(:all, :order => 'codice')
    end

    def search_righe_fattura_cliente(fattura)
      RigaFatturaCliente.search(:all, :conditions => ['fattura_cliente_id = ?', fattura], :include => [:aliquota], :order => 'righe_fatture_clienti.id')
    end

    def search_pdc()
      Pdc.search(:all, :conditions => {:hidden => 0}, :order => 'codice')
    end

    def search_categorie_pdc()
      CategoriaPdc.search(:all, :order => 'codice')
    end

    def search_clienti()
      Cliente.search(:all, :order => 'denominazione')
    end

    def search_fornitori()
      Fornitore.search(:all, :order => 'denominazione')
    end

    def search_banche()
      Banca.search(:all, :order => 'descrizione')
    end

    def search_causali()
      Causale.search(:all, :order => 'descrizione')
    end

    def search_prodotti()
      Prodotto.search(:all, :order => 'descrizione')
    end

    def search_scritture()
      Scrittura.search(:all, 
        :conditions => ["data_registrazione >= ?", Date.today], 
        :include => [:storno, :causale, :banca],
        :order => 'data_registrazione desc')
    end
    
    def search_tipi_pagamento(categoria)
      TipoPagamento.search(:all, :conditions => ["categoria_id = ?", categoria], :order => 'descrizione')
    end

    def carica_movimenti_in_sospeso
      @@incassi = PagamentoFatturaCliente.find(:all,
                                      :conditions => ["pagamenti_fatture_clienti.data_pagamento <= ? and registrato_in_prima_nota = ? and fatture_clienti.azienda_id = ? and (maxi_pagamento_cliente_id is null or maxi_pagamenti_clienti.chiuso = 1)", 
                                      Date.today, 
                                      0, 
                                      Azienda.current.id],
                                      :include => [:fattura_cliente, :maxi_pagamento_cliente],
                                      :order => 'pagamenti_fatture_clienti.data_pagamento')

      @@pagamenti = PagamentoFatturaFornitore.find(:all,
                                      :conditions => ["pagamenti_fatture_fornitori.data_pagamento <= ? and registrato_in_prima_nota = ? and fatture_fornitori.azienda_id = ? and (maxi_pagamento_fornitore_id is null or maxi_pagamenti_fornitori.chiuso = 1)", 
                                      Date.today, 
                                      0, 
                                      Azienda.current.id],
                                      :include => [:fattura_fornitore, :maxi_pagamento_fornitore],
                                      :order => 'pagamenti_fatture_fornitori.data_pagamento')
    end

    def movimenti_in_sospeso?
      return (incassi_sospesi.size > 0 || pagamenti_sospesi.size > 0)
    end

    def incassi_sospesi
      @@incassi ||= []
    end

    def pagamenti_sospesi
      @@pagamenti ||= []
    end
    
    def registra_licenza()
      licenza.update_attribute(:data_scadenza, nil)
    end

    def licenza()
      @@licenza ||= Licenza.find(:first)
    end
  end
end