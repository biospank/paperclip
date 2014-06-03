# encoding: utf-8

module Controllers
  module MagazzinoController
    include Controllers::BaseController

    # gestione fattura cliente

    def load_ordine(id)
      Ordine.find(id)
    end

    def save_ordine()
      righe_ordine = righe_ordine_panel.result_set_lstrep_righe_ordine

      Ordine.transaction do
        ordine.save!

        righe_da_eliminare = []

        righe_ordine.each do |riga|
          case riga.instance_status
          when RigaOrdine::ST_INSERT
            # associo l'id dell'ordine alla riga
            riga.ordine = ordine
            riga.save!
          when RigaOrdine::ST_UPDATE
            riga.save!
          when RigaOrdine::ST_DELETE
            righe_da_eliminare << riga
          end
        end

        elimina_righe_ordine(ordine, righe_da_eliminare)

      end

      return true

    end

    def elimina_righe_ordine(ordine, righe_da_eliminare)
      righe_da_eliminare.each do |riga|
        riga.destroy
      end

    end

    def delete_ordine()
      elimina_righe_ordine(ordine, ordine.righe_ordine)
      ordine.destroy
    end

    def search_for_ordini()
      Ordine.search_for(filtro.ricerca, [:num, 'fornitori.denominazione'], build_ordini_dialog_conditions())
    end

    def search_righe_ordine(ordine)
      RigaOrdine.search(:all, :conditions => ['ordine_id = ?', ordine], :order => 'righe_ordini.id')
    end

    def build_ordini_dialog_conditions()
      query_str = []
      parametri = []

      filtro.build_conditions(query_str, parametri) if filtro

      {:conditions => [query_str.join(' AND '), *parametri],
#        :joins => [:cliente], # produce una inner join, oppure
#        :joins => "LEFT OUTER JOIN clienti ON clienti.id = nota_spese.cliente_id,
        :include => [:fornitore],
        :order => 'ordini.data_emissione desc, ordini.num desc'}
    end


    # gestione prodotti

    def load_prodotto(id)
      Prodotto.find(id)
    end

    def load_prodotto_by_codice(codice)
      Prodotto.find_by_codice(codice, :conditions => ["azienda_id = ?", Azienda.current])
    end

    def load_prodotto_by_bar_code(barcode)
      Prodotto.find_by_bar_code(barcode, :conditions => ["azienda_id = ?", Azienda.current])
    end

    def load_scarico_prodotto_by_bar_code(magazzino, barcode)
      if prd = Prodotto.find_by_bar_code(barcode,
        {:select => "prodotti.id",
           :conditions => ["prodotti.azienda_id = ? and movimenti.magazzino_id = ?", Azienda.current, magazzino],
           :joins => :movimenti,
           :group => "prodotti.id"}
        )
        Prodotto.find(prd)
      end
    end


    def save_prodotto()
      prodotto.save
    end

    def delete_prodotto()
      prodotto.destroy
    end

    def search_for_prodotti()
      Prodotto.search_for(filtro.ricerca,
        [:codice, :bar_code, :descrizione],
        build_prodotti_dialog_conditions())
    end

    def build_prodotti_dialog_conditions()
      query_str = []
      parametri = []

      filtro.build_conditions(query_str, parametri) if filtro

      if filtro.magazzino
        query_str << "movimenti.magazzino_id = ?"
        parametri << filtro.magazzino
        return {:select => "prodotti.id, prodotti.codice, prodotti.descrizione",
         :conditions => [query_str.join(' AND '), *parametri],
         :joins => :movimenti,
         :group => "prodotti.id, prodotti.codice, prodotti.descrizione",
         :order => 'prodotti.codice'}
       else
        return {:conditions => [query_str.join(' AND '), *parametri],
         :order => 'codice'}
      end

    end

    # gestione magazzini

    def load_magazzino(id)
      Magazzino.find(id)
    end

    def save_magazzino()
      magazzino.save
    end

    def delete_magazzino()
      magazzino.destroy
    end

    def search_for_magazzini()
      Magazzino.search_for(filtro.ricerca,
        [:nome],
        build_magazzini_dialog_conditions())
    end

    def build_magazzini_dialog_conditions()
      query_str = []
      parametri = []

      filtro.build_conditions(query_str, parametri) if filtro

      {:conditions => [query_str.join(' AND '), *parametri],
       :order => 'nome'}
    end

    # gestione carichi

    def save_movimenti_carico()
      righe_carico = righe_carico_panel.result_set_lstrep_righe_carico

      while riga_to_save = righe_carico.pop
        if riga_to_save.valid_record?
          righe_carico.each do |riga|
            if riga.valid_record?
              if riga_to_save.prodotto_id == riga.prodotto_id
                riga_to_save.qta += riga.qta
              end
            end
          end
          righe_carico.delete_if { |carico| riga_to_save.prodotto_id == carico.prodotto_id  }
          riga_to_save.save_with_validation(false)
        end
      end

      return true

    end

    def save_movimenti_scarico(crea_fattura=false)
      righe_scarico = righe_scarico_panel.result_set_lstrep_righe_scarico

#      while riga_to_save = righe_scarico.pop
#        if riga_to_save.valid_record?
#          righe_scarico.each do |riga|
#            if riga.valid_record?
#              if riga_to_save.prodotto_id == riga.prodotto_id
#                riga_to_save.qta += riga.qta
#              end
#            end
#          end
#          righe_scarico.delete_if { |scarico| riga_to_save.prodotto_id == scarico.prodotto_id  }
#          riga_to_save.save_with_validation(false)
#        end
#      end
      if crea_fattura
        fattura = FatturaClienteFatturazione.new(
          :azienda => Azienda.current,
          :cliente => cliente,
          :num => fattura_cliente.num,
          :data_emissione => fattura_cliente.data_emissione,
          :imponibile => righe_scarico_panel.totale_imponibile,
          :iva => righe_scarico_panel.totale_iva,
          :importo => righe_scarico_panel.totale_fattura,
          :da_fatturazione => 1
        )

        fattura.transaction do
#          fattura.check_progressivo!
          fattura.save!
          righe_scarico.each do |scarico|
            if scarico.valid_record?
              riga_fattura = fattura.righe_fattura_cliente.create(
                :descrizione => scarico.prodotto.descrizione,
                :qta => scarico.qta,
                :importo => scarico.imponibile * scarico.qta,
                :aliquota => scarico.prodotto.aliquota
              )
              scarico.riga_fattura = riga_fattura
              scarico.save_with_validation(false)
            end
          end
          ProgressivoFatturaCliente.aggiorna_progressivo(fattura)
        end
        return fattura
      else
        righe_scarico.each do |scarico|
          if scarico.valid_record?
            scarico.save_with_validation(false)
          end
        end
      end

      return true

    end

    # gestione report

    def report_ordini()
      data_matrix = []

      Ordine.search(:all, build_ordini_report_conditions()).each do |ordine|
        dati_ordine = IdentModel.new(ordine.id, Ordine)
        dati_ordine << ordine.fornitore.denominazione
        dati_ordine << ordine.num
        dati_ordine << ordine.data_emissione

        data_matrix << dati_ordine

      end

      data_matrix
    end

    def build_ordini_report_conditions()
      query_str = []
      parametri = []

      data_dal = get_date(:from)
      data_al = get_date(:to)

      query_str << "ordini.data_emissione >= ?"
      parametri << data_dal
      query_str << "ordini.data_emissione <= ?"
      parametri << data_al

      if (filtro.fornitore)
        query_str << "ordini.fornitore_id = ?"
        parametri << filtro.fornitore
      end

      if (filtro.prodotto)
        query_str << "righe_ordini.prodotto_id = ?"
        parametri << filtro.prodotto
      end

      {:conditions => [query_str.join(' AND '), *parametri],
        :include => [:fornitore, :righe_ordine],
        :order => "ordini.data_emissione desc"}
    end

    def report_movimenti()

      Movimento.search(:all,
        :include => :prodotto,
        :conditions => build_movimenti_report_conditions(),
        :order => 'prodotti.descrizione, movimenti.data'
      )

    end

    def build_movimenti_report_conditions()
      query_str = []
      parametri = []

      data_dal = get_date(:from)
      data_al = get_date(:to)

      query_str << "prodotti.azienda_id = ?"
      parametri << Azienda.current

      if (filtro.magazzino)
        query_str << "movimenti.magazzino_id = ?"
        parametri << filtro.magazzino
      end

      if (filtro.prodotto)
        query_str << "prodotti.id = ?"
        parametri << filtro.prodotto
      end

      if filtro.movimento == Movimento::CARICO
        query_str << "movimenti.type = ?"
        parametri << Movimento::CARICO
      elsif filtro.movimento == Movimento::SCARICO
        query_str << "movimenti.type = ?"
        parametri << Movimento::SCARICO
      end

      query_str << "movimenti.data >= ?"
      parametri << data_dal
      query_str << "movimenti.data <= ?"
      parametri << data_al

      [query_str.join(' AND '), *parametri]

    end

    def report_giacenze()

      Prodotto.find(:all,
        :select => "p.id as id, p.codice as codice, p.descrizione as descrizione, sum(c.qta) as qta, p.prezzo_acquisto as prezzo_acquisto",
        :from => "prodotti p, (SELECT data, prodotto_id, magazzino_id, (CASE WHEN type = 'Carico' THEN qta ELSE -qta END) AS qta FROM movimenti) c",
        #:joins => "left join movimenti c on p.id = c.prodotto_id left join movimenti s on p.id = s.prodotto_id",
        :conditions => build_giacenze_report_conditions(),
        :group => "p.id, p.codice, p.descrizione, p.prezzo_acquisto",
        :order => "p.descrizione"
      ).map do |prodotto|
        if prodotto.qta.to_i > 0
          self.totale_magazzino +=  (prodotto.qta.to_i * prodotto.prezzo_acquisto.to_f)
        end
        prodotto
      end

    end

    def build_giacenze_report_conditions()
      query_str = []
      parametri = []

      if (filtro.magazzino)
        query_str << "c.magazzino_id = ?"
        parametri << filtro.magazzino
      end

      if (filtro.prodotto)
        query_str << "p.id = ?"
        parametri << filtro.prodotto
      end

      query_str << "c.data <= ?"
      parametri << (filtro.al || Date.today)

      query_str << "p.azienda_id = ?"
      parametri << Azienda.current

      query_str << "p.id = c.prodotto_id"

      [query_str.join(' AND '), *parametri]

    end

  end
end
