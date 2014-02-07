# encoding: utf-8

module Helpers
  module ScadenzarioHelper
    WXBRA_SCADENZARIO_CLIENTI_FOLDER = 0
    WXBRA_SCADENZARIO_FORNITORI_FOLDER = 1
    WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER = 2
    WXBRA_REPORT_SCADENZARIO_FOLDER = 3

    WXBRA_INCASSI_PAGAMENTI_FOLDER = 0
    WXBRA_NORMA_LIQUIDAZIONI_FOLDER = 1

    WXBRA_REPORT_SCADENZARIO_CLIENTI_FOLDER = 0
    WXBRA_REPORT_SCADENZARIO_FORNITORI_FOLDER = 1
    WXBRA_REPORT_LIQUIDAZIONE_IVA_FOLDER = 2

    WXBRA_ESTRATTO_REPORT_CLIENTI_FOLDER = 0
    WXBRA_PARTITARIO_REPORT_CLIENTI_FOLDER = 1
    WXBRA_SALDI_REPORT_CLIENTI_FOLDER = 2
    WXBRA_SCADENZE_REPORT_CLIENTI_FOLDER = 3

    WXBRA_ESTRATTO_REPORT_FORNITORI_FOLDER = 0
    WXBRA_PARTITARIO_REPORT_FORNITORI_FOLDER = 1
    WXBRA_SALDI_REPORT_FORNITORI_FOLDER = 2
    WXBRA_SCADENZE_REPORT_FORNITORI_FOLDER = 3

    WXBRA_IVA_REPORT_FOLDER = 0
    WXBRA_ACQUITI_REPORT_FOLDER = 1
    WXBRA_VENDITE_REPORT_FOLDER = 2
    WXBRA_CORRISPETTIVI_REPORT_FOLDER = 3

    # Modelli Report
    EstrattoClientiTemplatePath = "resources/models/report/scadenzario/estratto_clienti.odt"
    EstrattoFornitoriTemplatePath = "resources/models/report/scadenzario/estratto_fornitori.odt"
    PartitarioClientiTemplatePath = "resources/models/report/scadenzario/partitario_clienti.odt"
    PartitarioFornitoriTemplatePath = "resources/models/report/scadenzario/partitario_fornitori.odt"
    SaldiClientiTemplatePath = "resources/models/report/scadenzario/saldi_clienti.odt"
    SaldiFornitoriTemplatePath = "resources/models/report/scadenzario/saldi_fornitori.odt"
    ScadenzeClientiTemplatePath = "resources/models/report/scadenzario/scadenze_clienti.odt"
    ScadenzeFornitoriTemplatePath = "resources/models/report/scadenzario/scadenze_fornitori.odt"

    # Bootstrap
    # stampe
    EstrattoHeaderTemplatePath = 'resources/templates/report/scadenzario/estratto_header.html.erb'
    EstrattoFooterTemplatePath = 'resources/templates/report/scadenzario/estratto_footer.html.erb'
    EstrattoBodyTemplatePath = 'resources/templates/report/scadenzario/estratto_body.html.erb'

    PartitarioHeaderTemplatePath = 'resources/templates/report/scadenzario/partitario_header.html.erb'
    PartitarioFooterTemplatePath = 'resources/templates/report/scadenzario/partitario_footer.html.erb'
    PartitarioBodyTemplatePath = 'resources/templates/report/scadenzario/partitario_body.html.erb'

    SaldiHeaderTemplatePath = 'resources/templates/report/scadenzario/saldi_header.html.erb'
    SaldiFooterTemplatePath = 'resources/templates/report/scadenzario/saldi_footer.html.erb'
    SaldiBodyTemplatePath = 'resources/templates/report/scadenzario/saldi_body.html.erb'

    ScadenzeHeaderTemplatePath = 'resources/templates/report/scadenzario/scadenze_header.html.erb'
    ScadenzeFooterTemplatePath = 'resources/templates/report/scadenzario/scadenze_footer.html.erb'
    ScadenzeBodyTemplatePath = 'resources/templates/report/scadenzario/scadenze_body.html.erb'

    IvaHeaderTemplatePath = 'resources/templates/report/scadenzario/iva_header.html.erb'
    IvaBodyTemplatePath = 'resources/templates/report/scadenzario/iva_body.html.erb'

    AcquistiHeaderTemplatePath = 'resources/templates/report/scadenzario/acquisti_header.html.erb'
    AcquistiFooterTemplatePath = 'resources/templates/report/scadenzario/acquisti_footer.html.erb'
    AcquistiBodyTemplatePath = 'resources/templates/report/scadenzario/acquisti_body.html.erb'

    VenditeHeaderTemplatePath = 'resources/templates/report/scadenzario/vendite_header.html.erb'
    VenditeFooterTemplatePath = 'resources/templates/report/scadenzario/vendite_footer.html.erb'
    VenditeBodyTemplatePath = 'resources/templates/report/scadenzario/vendite_body.html.erb'

    CorrispettiviHeaderTemplatePath = 'resources/templates/report/scadenzario/corrispettivi_header.html.erb'
    CorrispettiviFooterTemplatePath = 'resources/templates/report/scadenzario/corrispettivi_footer.html.erb'
    CorrispettiviBodyTemplatePath = 'resources/templates/report/scadenzario/corrispettivi_body.html.erb'

    module Report
      include Models

      # gestione report acquisti
      def report_acquisti(filtro)
        data_matrix = []
        riepilogo_iva_data_matrix = []

        acquisti = RigaFatturaPdc.search(:all, build_acquisti_report_conditions(filtro))

        acquisti.group_by(&:fattura_fornitore_id).each do |fattura_id, dati_acquisti|
          dati_fattura_acquisti = IdentModel.new(fattura_id, FatturaFornitore)
          fattura = dati_acquisti.first.fattura_fornitore
          dati_fattura_acquisti << fattura.fornitore.denominazione
          dati_fattura_acquisti << fattura.num
          dati_fattura_acquisti << fattura.data_emissione.to_s(:italian_short_date)
          dati_fattura_acquisti << fattura.importo
          dati_fattura_acquisti.concat ['', '', '', '', '']

          data_matrix << dati_fattura_acquisti

          dati_acquisti.each do |acquisto|
            dati_iva_acquisti = ['', '', '', '']
            dati_iva_acquisti << acquisto.aliquota.descrizione
            dati_iva_acquisti << acquisto.imponibile
            dati_iva_acquisti << acquisto.iva
            if norma = acquisto.norma
              dati_iva_acquisti << (acquisto.iva - acquisto.detrazione)
              dati_iva_acquisti << norma.descrizione
            else
              dati_iva_acquisti << ''
              dati_iva_acquisti << ''
            end
            
            data_matrix << dati_iva_acquisti
          end

        end

        acquisti.group_by(&:aliquota_id).each do |aliquota_id, riepilogo_iva|

          aliquota = riepilogo_iva.first.aliquota

          arr_riepilogo_norma = []

          riepilogo_iva.group_by(&:norma_id).each do |norma_id, riepilogo_norma|
            if norma = riepilogo_norma.first.norma
              riepilogo_iva_acquisti = []
              riepilogo_iva_acquisti << aliquota.descrizione
              riepilogo_iva_acquisti << norma.descrizione
              riepilogo_iva_acquisti << riepilogo_norma.sum(&:imponibile)
              riepilogo_iva_acquisti << riepilogo_norma.sum(&:iva)
              riepilogo_iva_acquisti << (riepilogo_norma.sum(&:iva) - riepilogo_norma.sum(&:detrazione)) # iva detraibile
              riepilogo_iva_acquisti << riepilogo_norma.sum(&:detrazione) # iva indetraibile

              riepilogo_iva_data_matrix << riepilogo_iva_acquisti

              arr_riepilogo_norma.concat riepilogo_norma
            end
          end

          residuo_riepilogo_iva = (riepilogo_iva - arr_riepilogo_norma)

          unless residuo_riepilogo_iva.empty?
            riepilogo_iva_acquisti = []
            riepilogo_iva_acquisti << aliquota.descrizione
            riepilogo_iva_acquisti << '' # descrizione norma
            riepilogo_iva_acquisti << residuo_riepilogo_iva.sum(&:imponibile)
            riepilogo_iva_acquisti << residuo_riepilogo_iva.sum(&:iva)
            riepilogo_iva_acquisti << residuo_riepilogo_iva.sum(&:iva) # iva detraibile
            riepilogo_iva_acquisti << '' # iva indetraibile

            riepilogo_iva_data_matrix << riepilogo_iva_acquisti
          end
        end

        self.totale_imponibile = acquisti.sum(&:imponibile)
        self.totale_iva = acquisti.sum(&:iva)
        detrazioni = acquisti.sum {|acquisto| acquisto.detrazione || 0.0}
        self.totale_iva_detraibile = (acquisti.sum(&:iva) - detrazioni)
        self.totale_iva_indetraibile = detrazioni

        [data_matrix, riepilogo_iva_data_matrix]

      end

      def build_acquisti_report_conditions(filtro)
        query_str = []
        parametri = []

        query_str << "#{to_sql_year('fatture_fornitori.data_registrazione')} = ? "
        parametri << filtro.anno

        if Azienda.current.dati_azienda.liquidazione_iva == Helpers::ApplicationHelper::Liquidazione::MENSILE
          query_str << "#{to_sql_month('fatture_fornitori.data_registrazione')} = ? "
          parametri << filtro.periodo

        else
          range = Helpers::ApplicationHelper::Liquidazione::TRIMESTRE_TO_RANGE[filtro.periodo]

          query_str << "#{to_sql_month('(fatture_fornitori.data_registrazione')} >= ? "
          parametri << ("%02d" % range.first)

          query_str << "#{to_sql_month('fatture_fornitori.data_registrazione')} <= ?) "
          parametri << ("%02d" % range.last)
        end

        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:conditions => [query_str.join(' AND '), *parametri],
          :include => [{:fattura_fornitore => [:fornitore]}, :aliquota, :norma]
        }
      end

      # gestione report vendite
      def report_vendite(filtro)
        data_matrix = []
        riepilogo_iva_data_matrix = []

        vendite = RigaFatturaPdc.search(:all, build_vendite_report_conditions(filtro))

        vendite.group_by(&:fattura_cliente_id).each do |fattura_id, dati_vendite|
          dati_fattura_vendite = IdentModel.new(fattura_id, FatturaClienteScadenzario)
          fattura = dati_vendite.first.fattura_cliente
          dati_fattura_vendite << fattura.cliente.denominazione
          dati_fattura_vendite << fattura.num
          dati_fattura_vendite << fattura.data_emissione.to_s(:italian_date)
          dati_fattura_vendite << fattura.importo
          dati_fattura_vendite.concat ['', '', '', '', '']

          data_matrix << dati_fattura_vendite

          dati_vendite.each do |vendita|
            dati_iva_vendite = ['', '', '', '']
            dati_iva_vendite << vendita.aliquota.descrizione
            dati_iva_vendite << (vendita.norma ? vendita.norma.descrizione : '')
            dati_iva_vendite << vendita.imponibile
            dati_iva_vendite << vendita.iva

            data_matrix << dati_iva_vendite
          end

        end

        vendite.group_by(&:aliquota_id).each do |aliquota_id, riepilogo_iva|

          aliquota = riepilogo_iva.first.aliquota

          arr_riepilogo_norma = []

          riepilogo_iva.group_by(&:norma_id).each do |norma_id, riepilogo_norma|
            if norma = riepilogo_norma.first.norma
              riepilogo_iva_vendite = []
              riepilogo_iva_vendite << aliquota.descrizione
              riepilogo_iva_vendite << norma.descrizione
              riepilogo_iva_vendite << riepilogo_norma.sum(&:imponibile)
              riepilogo_iva_vendite << riepilogo_norma.sum(&:iva)

              riepilogo_iva_data_matrix << riepilogo_iva_vendite

              arr_riepilogo_norma.concat riepilogo_norma
            end
          end

          residuo_riepilogo_iva = (riepilogo_iva - arr_riepilogo_norma)

          unless residuo_riepilogo_iva.empty?
            riepilogo_iva_vendite = []
            riepilogo_iva_vendite << aliquota.descrizione
            riepilogo_iva_vendite << '' # descrizione norma
            riepilogo_iva_vendite << residuo_riepilogo_iva.sum(&:imponibile)
            riepilogo_iva_vendite << residuo_riepilogo_iva.sum(&:iva)

            riepilogo_iva_data_matrix << riepilogo_iva_vendite
          end
        end

        self.totale_imponibile = vendite.sum(&:imponibile)
        self.totale_iva = vendite.sum(&:iva)

        [data_matrix, riepilogo_iva_data_matrix]

      end

      def build_vendite_report_conditions(filtro)
        query_str = []
        parametri = []

        query_str << "#{to_sql_year('fatture_clienti.data_emissione')} = ? "
        parametri << filtro.anno

        if Azienda.current.dati_azienda.liquidazione_iva == Helpers::ApplicationHelper::Liquidazione::MENSILE
          query_str << "#{to_sql_month('fatture_clienti.data_emissione')} = ? "
          parametri << filtro.periodo

        else
          range = Helpers::ApplicationHelper::Liquidazione::TRIMESTRE_TO_RANGE[filtro.periodo]

          query_str << "#{to_sql_month('(fatture_clienti.data_emissione')} >= ? "
          parametri << ("%02d" % range.first)

          query_str << "#{to_sql_month('fatture_clienti.data_emissione')} <= ?) "
          parametri << ("%02d" % range.last)
        end

        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:conditions => [query_str.join(' AND '), *parametri],
          :include => [{:fattura_cliente => [:cliente]}, :aliquota, :norma]
        }
      end

      # gestione report corrispettivi
      def load_corrispettivo(id)
        Corrispettivo.find(id)
      end

      def report_corrispettivi(filtro)
        data_matrix = []
        riepilogo_iva_data_matrix = []

        corrispettivi = Corrispettivo.search(:all, build_corrispettivi_report_conditions(filtro))


        corrispettivi.each do |corrispettivo|
          dati_iva_corrispettivi = IdentModel.new(corrispettivo.id, Corrispettivo)
          dati_iva_corrispettivi << corrispettivo.data.to_s(:italian_date)
          dati_iva_corrispettivi << corrispettivo.importo
          dati_iva_corrispettivi << corrispettivo.aliquota.descrizione
          dati_iva_corrispettivi << corrispettivo.imponibile
          dati_iva_corrispettivi << corrispettivo.iva

          data_matrix << dati_iva_corrispettivi
        end

        corrispettivi.group_by(&:aliquota_id).each do |aliquota_id, riepilogo_iva|
          riepilogo_iva_corrispettivi = []

          aliquota = riepilogo_iva.first.aliquota

          riepilogo_iva_corrispettivi << aliquota.descrizione
          riepilogo_iva_corrispettivi << riepilogo_iva.sum(&:imponibile)
          riepilogo_iva_corrispettivi << riepilogo_iva.sum(&:iva)

          riepilogo_iva_data_matrix << riepilogo_iva_corrispettivi
        end

        self.totale_imponibile = corrispettivi.sum(&:imponibile)
        self.totale_iva = corrispettivi.sum(&:iva)

        [data_matrix, riepilogo_iva_data_matrix]

      end

      def build_corrispettivi_report_conditions(filtro)
        query_str = []
        parametri = []

        query_str << "#{to_sql_year('corrispettivi.data')} = ? "
        parametri << filtro.anno

        if Azienda.current.dati_azienda.liquidazione_iva == Helpers::ApplicationHelper::Liquidazione::MENSILE
          query_str << "#{to_sql_month('corrispettivi.data')} = ? "
          parametri << filtro.periodo

        else
          range = Helpers::ApplicationHelper::Liquidazione::TRIMESTRE_TO_RANGE[filtro.periodo]

          query_str << "#{to_sql_month('(corrispettivi.data')} >= ? "
          parametri << ("%02d" % range.first)

          query_str << "#{to_sql_month('corrispettivi.data')} <= ?) "
          parametri << ("%02d" % range.last)
        end

        {:conditions => [query_str.join(' AND '), *parametri],
          :include => [:aliquota],
          :order => "corrispettivi.data"
        }
      end

      # GESTIONE REPORT CLIENTI
      #
      # gestione report estratto
      def report_estratto_clienti
        data_matrix = []

        opt_conditions = optional_conditions_enabled?

        unless opt_conditions
          filtro.residuo = true
          tot_fatt = FatturaCliente.sum(:importo,
            build_totole_fatture_estratto_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"]))
          tot_pag = PagamentoFatturaCliente.sum(:importo,
            build_totole_pagamenti_estratto_clienti_report_conditions(["pagamenti_fatture_clienti.registrato_in_prima_nota = 1", "fatture_clienti.nota_di_credito = 0"]))
          ripresa_saldo_fatture = tot_fatt - tot_pag
          tot_nc = FatturaCliente.sum(:importo,
            build_totole_fatture_estratto_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"]))
          tot_pag_nc = PagamentoFatturaCliente.sum(:importo,
            build_totole_pagamenti_estratto_clienti_report_conditions(["pagamenti_fatture_clienti.registrato_in_prima_nota = 1", "fatture_clienti.nota_di_credito = 1"]))
          riperesa_saldo_nc = tot_nc - tot_pag_nc

          self.ripresa_saldo = ripresa_saldo_fatture - riperesa_saldo_nc

          data_matrix << riga_dati_ripresa_saldo(self.ripresa_saldo)
        end

        filtro.residuo = false

        FatturaClienteScadenzario.search(:all, build_estratto_clienti_report_conditions()).each do |fattura|

          if fattura.nota_di_credito?
            self.totale_nc +=  fattura.importo
          else
            self.totale_fatture +=  fattura.importo
          end

          data_matrix << riga_dati_fattura_cliente(fattura)

          if fattura.da_scadenzario?
            pagamenti = fattura.pagamento_fattura_cliente

            unless pagamenti.blank?
              totale_incassi_fattura = 0.0
              pagamenti.each do | pagamento |
                if pagamento.registrato_in_prima_nota?
                  if fattura.nota_di_credito?
                    self.totale_incassi -= pagamento.importo
                  else
                    self.totale_incassi += pagamento.importo
                  end

                  totale_incassi_fattura += pagamento.importo

                  if multiplo = pagamento.parziale?
                    data_matrix << riga_dati_pagamento(multiplo) do |importo|
                      "#{importo}*"
                    end
                  else
                    data_matrix << riga_dati_pagamento(pagamento)
                  end
                else
                  data_matrix << riga_dati_pagamento_a_saldo(pagamento) if opt_conditions
                end
              end

              unless opt_conditions
                if (saldo_fattura = Helpers::ApplicationHelper.real(fattura.importo - totale_incassi_fattura)) > 0
                  data_matrix << riga_dati_saldo(saldo_fattura)
                end
              end
            end
          end
        end # each

        data_matrix

      end

      # gestione report partitario
      def report_partitario_clienti
        data_matrix = []

        data_dal = get_date(:from)
        data_al = get_date(:to)

        opt_conditions = optional_conditions_enabled?

        unless opt_conditions
          filtro.residuo = true
          tot_fatt = FatturaCliente.sum(:importo,
            build_totole_fatture_partitario_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"]))
          tot_pag = PagamentoFatturaCliente.sum(:importo,
            build_totole_pagamenti_partitario_clienti_report_conditions(["pagamenti_fatture_clienti.registrato_in_prima_nota = 1", "fatture_clienti.nota_di_credito = 0"]))
          ripresa_saldo_fatture = tot_fatt - tot_pag
          tot_nc = FatturaCliente.sum(:importo,
            build_totole_fatture_partitario_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"]))
          tot_pag_nc = PagamentoFatturaCliente.sum(:importo,
            build_totole_pagamenti_partitario_clienti_report_conditions(["pagamenti_fatture_clienti.registrato_in_prima_nota = 1", "fatture_clienti.nota_di_credito = 1"]))
          riperesa_saldo_nc = tot_nc - tot_pag_nc

          self.ripresa_saldo = ripresa_saldo_fatture - riperesa_saldo_nc

          data_matrix << riga_dati_ripresa_saldo(self.ripresa_saldo)
        end

        filtro.residuo = false

        FatturaClienteScadenzario.search(:all, build_partitario_clienti_report_conditions()).each do |fattura|
          ha_pagamenti_nel_range = true # solo per le fatture fuori range di date
          if((fattura.data_emissione < data_dal) or (fattura.data_emissione > data_al))
            if ha_pagamenti_nel_range = fattura.pagamento_fattura_cliente.any? {|p| (p.data_pagamento >= data_dal) and (p.data_pagamento <= data_al) and (p.registrato_in_prima_nota?)}
              data_matrix << riga_dati_fattura_cliente(fattura) do |importo|
                "(#{importo})"
              end
            end
          else
            if fattura.nota_di_credito?
              self.totale_nc +=  fattura.importo
            else
              self.totale_fatture +=  fattura.importo
            end

            data_matrix << riga_dati_fattura_cliente(fattura)
          end

          if fattura.da_scadenzario?
            pagamenti = fattura.pagamento_fattura_cliente

            unless pagamenti.blank?
              totale_incassi_fattura = 0.0
              pagamenti.each do | pagamento |
                if pagamento.registrato_in_prima_nota?
                  if((pagamento.data_pagamento >= data_dal) and (pagamento.data_pagamento <= data_al)) # prendo solo i pagamenti alla data impostata dall'utente
                    if fattura.nota_di_credito?
                      self.totale_incassi -= pagamento.importo
                    else
                      self.totale_incassi += pagamento.importo
                    end

                    totale_incassi_fattura += pagamento.importo

                    if multiplo = pagamento.parziale?
                      data_matrix << riga_dati_pagamento(multiplo) do |importo|
                        "#{importo}*"
                      end
                    else
                      data_matrix << riga_dati_pagamento(pagamento)
                    end

                    # nel caso di pagagamenti anticipati su fatture post datate
                  elsif(pagamento.data_pagamento < data_dal)
                    totale_incassi_fattura += pagamento.importo
                  end
                else
                  data_matrix << riga_dati_pagamento_a_saldo(pagamento) if opt_conditions
                end
              end

              unless opt_conditions
                if ha_pagamenti_nel_range
                  if (saldo_fattura = Helpers::ApplicationHelper.real(fattura.importo - totale_incassi_fattura)) > 0
                    data_matrix << riga_dati_saldo(saldo_fattura)
                  end
                end
              end
            end
          end
        end # each

        data_matrix

      end

      # gestione report saldi
      def report_saldi_clienti
        data_matrix = []

        tot_fatt = {}
        tot_pag = {}
        tot_maxi_pag = {}
        ripresa_tot_fatt = {}
        ripresa_tot_pag = {}
        ripresa_tot_maxi_pag = {}

        tot_nc = {}
        tot_pag_nc = {}
        tot_maxi_pag_nc = {}
        ripresa_tot_nc = {}
        ripresa_tot_pag_nc = {}
        ripresa_tot_maxi_pag_nc = {}

        clienti = Cliente.search(:all, build_saldi_clienti_report_conditions())

        FatturaCliente.search(:all,
          build_totole_fatture_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"])).
            each {|item| tot_fatt[item.id] = item}

        PagamentoFatturaCliente.search(:all,
          build_totole_pagamenti_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"])).
            each {|item| tot_pag[item.id] = item}

        MaxiPagamentoCliente.search(:all,
          build_totole_maxi_pagamenti_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"])).
            each {|item| (tot_maxi_pag[item.id] ||= []) << item}

        FatturaCliente.search(:all,
          build_totole_fatture_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"])).
            each {|item| ripresa_tot_fatt[item.id] = item}

        PagamentoFatturaCliente.search(:all,
          build_totole_pagamenti_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"])).
            each {|item| ripresa_tot_pag[item.id] = item}

        MaxiPagamentoCliente.search(:all,
          build_totole_maxi_pagamenti_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"])).
            each {|item| (ripresa_tot_maxi_pag[item.id] ||= []) << item}

        FatturaCliente.search(:all,
          build_totole_fatture_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| tot_nc[item.id] = item}

        PagamentoFatturaCliente.search(:all,
          build_totole_pagamenti_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| tot_pag_nc[item.id] = item}

        MaxiPagamentoCliente.search(:all,
          build_totole_maxi_pagamenti_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| (tot_maxi_pag_nc[item.id] ||= []) << item}

        FatturaCliente.search(:all,
          build_totole_fatture_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| ripresa_tot_nc[item.id] = item}

        PagamentoFatturaCliente.search(:all,
          build_totole_pagamenti_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| ripresa_tot_pag_nc[item.id] = item}

        MaxiPagamentoCliente.search(:all,
          build_totole_maxi_pagamenti_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| (ripresa_tot_maxi_pag_nc[item.id] ||= []) << item}


        clienti.each do |cliente|
          dati_saldo = []
          dati_saldo << cliente.denominazione

          saldo_fattura = 0
          if dati_fattura = tot_fatt[cliente.id]
            saldo_fattura = dati_fattura.importo
          end
          if dati_pagamento = tot_pag[cliente.id]
            saldo_fattura -= dati_pagamento.importo
          end
          if dati_maxi_pagamento = tot_maxi_pag[cliente.id]
            dati_maxi_pagamento.each do |dmp|
              saldo_fattura -= dmp.importo
            end
          end

          ripresa_saldo = 0
          if ripresa_dati_fattura = ripresa_tot_fatt[cliente.id]
            ripresa_saldo = ripresa_dati_fattura.importo
          end
          if ripresa_dati_pagamento = ripresa_tot_pag[cliente.id]
            ripresa_saldo -= ripresa_dati_pagamento.importo
          end
          if ripresa_dati_maxi_pagamento = ripresa_tot_maxi_pag[cliente.id]
            ripresa_dati_maxi_pagamento.each do |dmp|
              ripresa_saldo -= dmp.importo
            end
          end

          saldo_nc = 0
          if dati_nc = tot_nc[cliente.id]
            saldo_nc = dati_nc.importo
          end
          if dati_pagamento_nc = tot_pag_nc[cliente.id]
            saldo_nc -= dati_pagamento_nc.importo
          end
          if dati_maxi_pagamento_nc = tot_maxi_pag_nc[cliente.id]
            dati_maxi_pagamento_nc.each do |dmp|
              saldo_nc -= dmp.importo
            end
          end

          ripresa_saldo_nc = 0
          if ripresa_dati_nc = ripresa_tot_nc[cliente.id]
            ripresa_saldo_nc = ripresa_dati_nc.importo
          end
          if ripresa_dati_pagamento_nc = ripresa_tot_pag_nc[cliente.id]
            ripresa_saldo_nc -= ripresa_dati_pagamento_nc.importo
          end
          if ripresa_dati_maxi_pagamento_nc = ripresa_tot_maxi_pag_nc[cliente.id]
            ripresa_dati_maxi_pagamento_nc.each do |dmp|
              ripresa_saldo_nc -= dmp.importo
            end
          end

          if((saldo = (saldo_fattura + ripresa_saldo) - (saldo_nc + ripresa_saldo_nc)) != 0)
            dati_saldo << saldo

            data_matrix << dati_saldo

            self.totale_saldi += saldo
          end
        end

        data_matrix

      end

      # gestione report scadenze
      def report_scadenze_clienti
        data_matrix = []

        FatturaClienteScadenzario.search(:all, build_scadenze_clienti_report_conditions()).each do |fattura|

          if fattura.nota_di_credito?
            self.totale_nc +=  fattura.importo
          else
            self.totale_fatture +=  fattura.importo
          end

          data_matrix << riga_dati_fattura_cliente(fattura)

          pagamenti = fattura.pagamento_fattura_cliente

          unless pagamenti.blank?
            pagamenti.each do | pagamento |
              if fattura.nota_di_credito?
                self.totale_saldo -= pagamento.importo
              else
                self.totale_saldo += pagamento.importo
              end

              if multiplo = pagamento.parziale?
                data_matrix << riga_dati_scadenza(multiplo) do |importo|
                  "#{importo}*"
                end
              else
                data_matrix << riga_dati_scadenza(pagamento)
              end

            end

          end
        end

        data_matrix

      end

      # GESTIONE REPORT FORNITORI
      #
      # gestione report estratto
      def report_estratto_fornitori
        data_matrix = []

        opt_conditions = optional_conditions_enabled?

        unless opt_conditions
          filtro.residuo = true
          tot_fatt = FatturaFornitore.sum(:importo,
            build_totale_fatture_estratto_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 0"]))
          tot_pag = PagamentoFatturaFornitore.sum(:importo,
            build_totale_pagamenti_estratto_fornitori_report_conditions(["pagamenti_fatture_fornitori.registrato_in_prima_nota = 1", "fatture_fornitori.nota_di_credito = 0"]))
          ripresa_saldo_fatture = tot_fatt - tot_pag
          tot_nc = FatturaFornitore.sum(:importo,
            build_totale_fatture_estratto_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 1"]))
          tot_pag_nc = PagamentoFatturaFornitore.sum(:importo,
            build_totale_pagamenti_estratto_fornitori_report_conditions(["pagamenti_fatture_fornitori.registrato_in_prima_nota = 1", "fatture_fornitori.nota_di_credito = 1"]))
          riperesa_saldo_nc = tot_nc - tot_pag_nc

          self.ripresa_saldo = ripresa_saldo_fatture - riperesa_saldo_nc

          data_matrix << riga_dati_ripresa_saldo(self.ripresa_saldo)
        end

        filtro.residuo = false

        FatturaFornitore.search(:all, build_estratto_fornitori_report_conditions()).each do |fattura|

          if fattura.nota_di_credito?
            self.totale_nc +=  fattura.importo
          else
            self.totale_fatture +=  fattura.importo
          end

          data_matrix << riga_dati_fattura_fornitore(fattura)

          pagamenti = fattura.pagamento_fattura_fornitore

          unless pagamenti.blank?
            totale_pagamenti_fattura = 0.0
            pagamenti.each do | pagamento |
              if pagamento.registrato_in_prima_nota?

                if fattura.nota_di_credito?
                  self.totale_pagamenti -= pagamento.importo
                else
                  self.totale_pagamenti += pagamento.importo
                end

                totale_pagamenti_fattura += pagamento.importo

                if multiplo = pagamento.parziale?
                  data_matrix << riga_dati_pagamento(multiplo) do |importo|
                    "#{importo}*"
                  end
                else
                  data_matrix << riga_dati_pagamento(pagamento)
                end

              else
                data_matrix << riga_dati_pagamento_a_saldo(pagamento) if opt_conditions
              end
            end

            unless opt_conditions
              if (saldo_fattura = Helpers::ApplicationHelper.real(fattura.importo - totale_pagamenti_fattura)) > 0
                data_matrix << riga_dati_saldo(saldo_fattura)
              end
            end
          end
        end

        data_matrix

      end

      # gestione report partitario
      def report_partitario_fornitori
        data_matrix = []

        data_dal = get_date(:from)
        data_al = get_date(:to)

        opt_conditions = optional_conditions_enabled?

        unless opt_conditions
          filtro.residuo = true
          tot_fatt = FatturaFornitore.sum(:importo,
            build_totale_fatture_partitario_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 0"]))
          tot_pag = PagamentoFatturaFornitore.sum(:importo,
            build_totale_pagamenti_partitario_fornitori_report_conditions(["pagamenti_fatture_fornitori.registrato_in_prima_nota = 1", "fatture_fornitori.nota_di_credito = 0"]))
          ripresa_saldo_fatture = tot_fatt - tot_pag
          tot_nc = FatturaFornitore.sum(:importo,
            build_totale_fatture_partitario_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 1"]))
          tot_pag_nc = PagamentoFatturaFornitore.sum(:importo,
            build_totale_pagamenti_partitario_fornitori_report_conditions(["pagamenti_fatture_fornitori.registrato_in_prima_nota = 1", "fatture_fornitori.nota_di_credito = 1"]))
          riperesa_saldo_nc = tot_nc - tot_pag_nc

          self.ripresa_saldo = ripresa_saldo_fatture - riperesa_saldo_nc

          data_matrix << riga_dati_ripresa_saldo(self.ripresa_saldo)
        end

        filtro.residuo = false

        FatturaFornitore.search(:all, build_partitario_fornitori_report_conditions()).each do |fattura|
          ha_pagamenti_nel_range = true # solo per le fatture fuori range di date
          if((fattura.data_emissione < data_dal) or (fattura.data_emissione > data_al))
            if ha_pagamenti_nel_range = fattura.pagamento_fattura_fornitore.any? {|p| (p.data_pagamento >= data_dal) and (p.data_pagamento <= data_al) and (p.registrato_in_prima_nota?)}
              data_matrix << riga_dati_fattura_fornitore(fattura) do |importo|
                "(#{importo})"
              end
            end
          else
            if fattura.nota_di_credito?
              self.totale_nc +=  fattura.importo
            else
              self.totale_fatture +=  fattura.importo
            end

            data_matrix << riga_dati_fattura_fornitore(fattura)

          end

          pagamenti = fattura.pagamento_fattura_fornitore

          unless pagamenti.blank?
            totale_pagamenti_fattura = 0.0
            pagamenti.each do | pagamento |
              if pagamento.registrato_in_prima_nota?
                if((pagamento.data_pagamento >= data_dal) and (pagamento.data_pagamento <= data_al)) # prendo solo i pagamenti alla data impostata dall'utente

                  if fattura.nota_di_credito?
                    self.totale_pagamenti -= pagamento.importo
                  else
                    self.totale_pagamenti += pagamento.importo
                  end

                  totale_pagamenti_fattura += pagamento.importo

                  if multiplo = pagamento.parziale?
                    data_matrix << riga_dati_pagamento(multiplo) do |importo|
                      "#{importo}*"
                    end
                  else
                    data_matrix << riga_dati_pagamento(pagamento)
                  end

                  # nel caso di pagagamenti anticipati su fatture post datate
                elsif(pagamento.data_pagamento < data_dal)
                  totale_pagamenti_fattura += pagamento.importo
                end
              else
                data_matrix << riga_dati_pagamento_a_saldo(pagamento) if opt_conditions
              end
            end

            unless opt_conditions
              if ha_pagamenti_nel_range
                if (saldo_fattura = Helpers::ApplicationHelper.real(fattura.importo - totale_pagamenti_fattura)) > 0
                  data_matrix << riga_dati_saldo(saldo_fattura)
                end
              end
            end
          end
        end

        data_matrix

      end

      # gestione report saldi
      def report_saldi_fornitori
        data_matrix = []

        tot_fatt = {}
        tot_pag = {}
        tot_maxi_pag = {}
        ripresa_tot_fatt = {}
        ripresa_tot_pag = {}
        ripresa_tot_maxi_pag = {}

        tot_nc = {}
        tot_pag_nc = {}
        tot_maxi_pag_nc = {}
        ripresa_tot_nc = {}
        ripresa_tot_pag_nc = {}
        ripresa_tot_maxi_pag_nc = {}

        fornitori = Fornitore.search(:all, build_saldi_fornitori_report_conditions())

        FatturaFornitore.search(:all,
          build_totole_fatture_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 0"])).
            each {|item| tot_fatt[item.id] = item}

        PagamentoFatturaFornitore.search(:all,
          build_totole_pagamenti_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 0"])).
            each {|item| tot_pag[item.id] = item}

        MaxiPagamentoFornitore.search(:all,
          build_totole_maxi_pagamenti_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 0"])).
            each {|item| (tot_maxi_pag[item.id] ||= []) << item}

        FatturaFornitore.search(:all,
          build_totole_fatture_ripresa_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 0"])).
            each {|item| ripresa_tot_fatt[item.id] = item}

        PagamentoFatturaFornitore.search(:all,
          build_totole_pagamenti_ripresa_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 0"])).
            each {|item| ripresa_tot_pag[item.id] = item}

        MaxiPagamentoFornitore.search(:all,
          build_totole_maxi_pagamenti_ripresa_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 0"])).
            each {|item| (ripresa_tot_maxi_pag[item.id] ||= []) << item}

        FatturaFornitore.search(:all,
          build_totole_fatture_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 1"])).
            each {|item| tot_nc[item.id] = item}

        PagamentoFatturaFornitore.search(:all,
          build_totole_pagamenti_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 1"])).
            each {|item| tot_pag_nc[item.id] = item}

        MaxiPagamentoFornitore.search(:all,
          build_totole_maxi_pagamenti_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 1"])).
            each {|item| (tot_maxi_pag_nc[item.id] ||= []) << item}

        FatturaFornitore.search(:all,
          build_totole_fatture_ripresa_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 1"])).
            each {|item| ripresa_tot_nc[item.id] = item}

        PagamentoFatturaFornitore.search(:all,
          build_totole_pagamenti_ripresa_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 1"])).
            each {|item| ripresa_tot_pag_nc[item.id] = item}

        MaxiPagamentoFornitore.search(:all,
          build_totole_maxi_pagamenti_ripresa_saldi_fornitori_report_conditions(["fatture_fornitori.nota_di_credito = 1"])).
            each {|item| (ripresa_tot_maxi_pag_nc[item.id] ||= []) << item}


        fornitori.each do |fornitore|
          dati_saldo = []
          dati_saldo << fornitore.denominazione

          saldo_fattura = 0
          if dati_fattura = tot_fatt[fornitore.id]
            saldo_fattura = dati_fattura.importo
          end
          if dati_pagamento = tot_pag[fornitore.id]
            saldo_fattura -= dati_pagamento.importo
          end
          if dati_maxi_pagamento = tot_maxi_pag[fornitore.id]
            dati_maxi_pagamento.each do |dmp|
              saldo_fattura -= dmp.importo
            end
          end

          ripresa_saldo = 0
          if ripresa_dati_fattura = ripresa_tot_fatt[fornitore.id]
            ripresa_saldo = ripresa_dati_fattura.importo
          end
          if ripresa_dati_pagamento = ripresa_tot_pag[fornitore.id]
            ripresa_saldo -= ripresa_dati_pagamento.importo
          end
          if ripresa_dati_maxi_pagamento = ripresa_tot_maxi_pag[fornitore.id]
            ripresa_dati_maxi_pagamento.each do |dmp|
              ripresa_saldo -= dmp.importo
            end
          end

          saldo_nc = 0
          if dati_nc = tot_nc[fornitore.id]
            saldo_nc = dati_nc.importo
          end
          if dati_pagamento_nc = tot_pag_nc[fornitore.id]
            saldo_nc -= dati_pagamento_nc.importo
          end
          if dati_maxi_pagamento_nc = tot_maxi_pag_nc[fornitore.id]
            dati_maxi_pagamento_nc.each do |dmp|
              saldo_nc -= dmp.importo
            end
          end

          ripresa_saldo_nc = 0
          if ripresa_dati_nc = ripresa_tot_nc[fornitore.id]
            ripresa_saldo_nc = ripresa_dati_nc.importo
          end
          if ripresa_dati_pagamento_nc = ripresa_tot_pag_nc[fornitore.id]
            ripresa_saldo_nc -= ripresa_dati_pagamento_nc.importo
          end
          if ripresa_dati_maxi_pagamento_nc = ripresa_tot_maxi_pag_nc[fornitore.id]
            ripresa_dati_maxi_pagamento_nc.each do |dmp|
              ripresa_saldo_nc -= dmp.importo
            end
          end

          if((saldo = (saldo_fattura + ripresa_saldo) - (saldo_nc + ripresa_saldo_nc)) != 0)
            dati_saldo << saldo

            data_matrix << dati_saldo

            self.totale_saldi += saldo
          end
        end

        data_matrix

      end

      # gestione report scadenze
      def report_scadenze_fornitori
        data_matrix = []

        FatturaFornitore.search(:all, build_scadenze_fornitori_report_conditions()).each do |fattura|

          if fattura.nota_di_credito?
            self.totale_nc +=  fattura.importo
          else
            self.totale_fatture +=  fattura.importo
          end

          data_matrix << riga_dati_fattura_fornitore(fattura)

          pagamenti = fattura.pagamento_fattura_fornitore

          unless pagamenti.blank?
            pagamenti.each do | pagamento |
              if fattura.nota_di_credito?
                self.totale_saldo -= pagamento.importo
              else
                self.totale_saldo += pagamento.importo
              end

              if multiplo = pagamento.parziale?
                data_matrix << riga_dati_scadenza(multiplo) do |importo|
                  "#{importo}*"
                end
              else
                data_matrix << riga_dati_scadenza(pagamento)
              end
            end

          end
        end

        data_matrix

      end

      private

      def riga_dati_fattura_cliente(fattura)
        dati_fattura = IdentModel.new(fattura.id, FatturaClienteScadenzario)

        dati_fattura << fattura.cliente.denominazione
        if fattura.nota_di_credito?
          dati_fattura << ''
          dati_fattura << fattura.num
        else
          dati_fattura << fattura.num
          dati_fattura << ''
        end
        dati_fattura << fattura.data_emissione
        if block_given?
          dati_fattura << (yield fattura.importo)
        else
          dati_fattura << fattura.importo
        end

        dati_fattura

      end

      def riga_dati_fattura_fornitore(fattura)
        dati_fattura = IdentModel.new(fattura.id, FatturaClienteScadenzario)

        dati_fattura << fattura.fornitore.denominazione
        if fattura.nota_di_credito?
          dati_fattura << ''
          dati_fattura << fattura.num
        else
          dati_fattura << fattura.num
          dati_fattura << ''
        end
        dati_fattura << fattura.data_emissione
        if block_given?
          dati_fattura << (yield fattura.importo)
        else
          dati_fattura << fattura.importo
        end

        dati_fattura

      end

      def riga_dati_pagamento(pagamento)
        dati_pagamento = []

        dati_pagamento << ''
        dati_pagamento << ''
        dati_pagamento << ''
        dati_pagamento << pagamento.data_pagamento
        dati_pagamento << ''
        if block_given?
          dati_pagamento << (yield pagamento.importo)
        else
          dati_pagamento << pagamento.importo
        end
        dati_pagamento << ''
        dati_pagamento << pagamento.tipo_pagamento
        dati_pagamento << pagamento.banca
        dati_pagamento << pagamento.note
        dati_pagamento << '@' if pagamento.registrato_in_prima_nota?

        dati_pagamento
      end

      def riga_dati_pagamento_a_saldo(pagamento)
        dati_pagamento = []

        dati_pagamento << ''
        dati_pagamento << ''
        dati_pagamento << ''
        dati_pagamento << pagamento.data_pagamento
        dati_pagamento << ''
        dati_pagamento << ''
        dati_pagamento << pagamento.importo
        dati_pagamento << pagamento.tipo_pagamento
        dati_pagamento << pagamento.banca
        dati_pagamento << pagamento.note

        dati_pagamento
      end

      def riga_dati_scadenza(pagamento)
        dati_scadenza = []

        dati_scadenza << ''
        dati_scadenza << ''
        dati_scadenza << ''
        dati_scadenza << pagamento.data_pagamento
        dati_scadenza << ''
        if block_given?
          dati_scadenza << (yield pagamento.importo)
        else
          dati_scadenza << pagamento.importo
        end
        dati_scadenza << pagamento.tipo_pagamento
        dati_scadenza << pagamento.banca
        dati_scadenza << pagamento.note

        dati_scadenza
      end

      def riga_dati_saldo(saldo_fattura)
        dati_saldo = []
        dati_saldo << ''
        dati_saldo << ''
        dati_saldo << ''
        dati_saldo << ''
        dati_saldo << ''
        dati_saldo << ''
        dati_saldo << saldo_fattura
        dati_saldo << 'SALDO'
        dati_saldo << ''
        dati_saldo << ''
        dati_saldo << ''

        dati_saldo
      end

      def riga_dati_ripresa_saldo(ripresa_saldo)
        dati_saldo = []
        dati_saldo << 'RIPRESA SALDO'
        dati_saldo << ''
        dati_saldo << ''
        dati_saldo << ''
        dati_saldo << ''
        dati_saldo << ''
        dati_saldo << ripresa_saldo
        #        dati_saldo << 'SALDO'
        #        dati_saldo << ''
        #        dati_saldo << ''
        #        dati_saldo << ''

        dati_saldo
      end

      def build_estratto_clienti_report_conditions()
        query_str = []
        parametri = []

        date_estratto_fatture_clienti_conditions(query_str, parametri)
        fatture_clienti_common_conditions(query_str, parametri)

        query_str << "fatture_clienti.da_scadenzario = 1"

        #        {:select => "clienti.denominazione, fatture_clienti.num, fatture_clienti.data_emissione,
        #            fatture_clienti.importo, pagamenti_fatture_clienti.importo,
        #            pagamenti_fatture_clienti.registrato_in_prima_nota, pagamenti_fatture_clienti.note,
        #            tipi_pagamento.descrizione, banche.descrizione",
        {:conditions => [query_str.join(' AND '), *parametri],
          :include => [:cliente, {:pagamento_fattura_cliente => [:tipo_pagamento, :banca, {:maxi_pagamento_cliente => [:tipo_pagamento, :banca]}]}],
          :order => "clienti.denominazione, fatture_clienti.data_emissione, pagamenti_fatture_clienti.data_pagamento"
        }
      end

      def build_partitario_clienti_report_conditions()
        query_str = []
        parametri = []

        date_partitario_fatture_clienti_conditions(query_str, parametri)
        fatture_clienti_common_conditions(query_str, parametri)

        query_str << "fatture_clienti.da_scadenzario = 1"

        {:conditions => [query_str.join(' AND '), *parametri],
          :include => [:cliente, {:pagamento_fattura_cliente => [:tipo_pagamento, :banca, {:maxi_pagamento_cliente => [:tipo_pagamento, :banca]}]}],
          :order => "clienti.denominazione, fatture_clienti.data_emissione, pagamenti_fatture_clienti.data_pagamento"
        }
      end

      def build_saldi_clienti_report_conditions()
        query_str = []
        parametri = []

        if (filtro.cliente)
          query_str << "clienti.id = ?"
          parametri << filtro.cliente
        end


        {:conditions => [query_str.join(' AND '), *parametri],
            :order => "clienti.denominazione"}


      end

      def build_scadenze_clienti_report_conditions()
        query_str = []
        parametri = []

        date_scadenze_fatture_clienti_conditions(query_str, parametri)
        fatture_clienti_common_conditions(query_str, parametri)

        {:conditions => [query_str.join(' AND '), *parametri],
          :include => [:cliente, {:pagamento_fattura_cliente => [:tipo_pagamento, :banca, {:maxi_pagamento_cliente => [:tipo_pagamento, :banca]}]}],
          :order => "pagamenti_fatture_clienti.data_pagamento, clienti.denominazione, fatture_clienti.data_emissione"
        }
      end

      def build_totole_fatture_estratto_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "fatture_clienti.data_emissione < ?"
        parametri << get_date(:from)
        query_str << "fatture_clienti.da_scadenzario = 1"

        fatture_clienti_common_conditions(query_str, parametri)

        query_str << additional_criteria

        # aggiunto per la chiamata alla funzione sum
        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:conditions => [query_str.join(' AND '), *parametri], :include => [:cliente]}

      end

      def build_totole_pagamenti_estratto_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "fatture_clienti.data_emissione < ?"
        parametri << get_date(:from)

        fatture_clienti_common_conditions(query_str, parametri)

        query_str << additional_criteria

        # aggiunto per la chiamata alla funzione sum
        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:conditions => [query_str.join(' AND '), *parametri], :include => [:fattura_cliente => [:cliente]]}

      end

      def build_totole_fatture_partitario_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "fatture_clienti.data_emissione < ?"
        parametri << get_date(:from)
        query_str << "fatture_clienti.da_scadenzario = 1"

        fatture_clienti_common_conditions(query_str, parametri)

        query_str << additional_criteria

        # aggiunto per la chiamata alla funzione sum
        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:conditions => [query_str.join(' AND '), *parametri], :include => [:cliente]}

      end

      def build_totole_pagamenti_partitario_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "pagamenti_fatture_clienti.data_pagamento < ?"
        parametri << get_date(:from)

        fatture_clienti_common_conditions(query_str, parametri)

        query_str << additional_criteria

        # aggiunto per la chiamata alla funzione sum
        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:conditions => [query_str.join(' AND '), *parametri], :include => [:fattura_cliente => [:cliente]]}

      end

      def date_estratto_fatture_clienti_conditions(query_str, parametri)

        data_dal = get_date(:from)
        data_al = get_date(:to)

        query_str << "fatture_clienti.data_emissione >= ?"
        parametri << data_dal
        query_str << "fatture_clienti.data_emissione <= ?"
        parametri << data_al

      end

      def date_partitario_fatture_clienti_conditions(query_str, parametri)

        data_dal = get_date(:from)
        data_al = get_date(:to)

        or1_str = []
        or1_str << "fatture_clienti.data_emissione >= ?"
        parametri << data_dal
        or1_str << "fatture_clienti.data_emissione <= ?"
        parametri << data_al
        or2_str = []
        or2_str << "pagamenti_fatture_clienti.data_pagamento >= ?"
        parametri << data_dal
        or2_str << "pagamenti_fatture_clienti.data_pagamento <= ?"
        parametri << data_al
        or3_str = []
        or3_str << "pagamenti_fatture_clienti.data_pagamento < ?"
        parametri << data_dal

        query_str << ('(%s)' % ([('(%s)' % or1_str.join(' and ')), ('(%s)' % or2_str.join(' and ')), ('(%s)' % or3_str.join(' and '))].join(' or ')))

      end

      def date_saldi_fatture_clienti_conditions(query_str, parametri)

        data_al = get_date(:to)

        or1_str = []
        or1_str << "fatture_clienti.data_emissione <= ?"
        parametri << data_al
        or1_str << "pagamenti_fatture_clienti.registrato_in_prima_nota = 0"
        or2_str = []
        or2_str << "pagamenti_fatture_clienti.data_pagamento > ?"
        parametri << data_al
        or2_str << "pagamenti_fatture_clienti.registrato_in_prima_nota = 1"
        or2_str << "fatture_clienti.data_emissione <= ?"
        parametri << data_al

        query_str << ('(%s)' % ([('(%s)' % or1_str.join(' and ')), ('(%s)' % or2_str.join(' and '))].join(' or ')))

      end

      def build_totole_fatture_saldi_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "fatture_clienti.data_emissione >= ?"
        parametri << get_date(:from)
        query_str << "fatture_clienti.data_emissione <= ?"
        parametri << get_date(:to)
        query_str << "fatture_clienti.da_scadenzario = 1"

        query_str << additional_criteria

        if (filtro.cliente)
          query_str << "fatture_clienti.cliente_id = ?"
          parametri << filtro.cliente
        end

        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:select => "clienti.id as id, clienti.denominazione as denominazione, sum(fatture_clienti.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => :cliente,
            :group => "clienti.id, clienti.denominazione",
            :order => "clienti.denominazione"}
          )

      end

      def build_totole_fatture_ripresa_saldi_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "fatture_clienti.data_emissione < ?"
        parametri << get_date(:from)
        query_str << "fatture_clienti.da_scadenzario = 1"

        query_str << additional_criteria

        if (filtro.cliente)
          query_str << "fatture_clienti.cliente_id = ?"
          parametri << filtro.cliente
        end

        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:select => "clienti.id as id, clienti.denominazione as denominazione, sum(fatture_clienti.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => :cliente,
            :group => "clienti.id, clienti.denominazione",
            :order => "clienti.denominazione"}
          )

      end

      def build_totole_pagamenti_saldi_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "pagamenti_fatture_clienti.registrato_in_prima_nota = 1"
        query_str << "pagamenti_fatture_clienti.maxi_pagamento_cliente_id is null"
        query_str << "pagamenti_fatture_clienti.data_pagamento >=  ?"
        parametri << get_date(:from)
        query_str << "pagamenti_fatture_clienti.data_pagamento <=  ?"
        parametri << get_date(:to)

        query_str << "fatture_clienti.da_scadenzario = 1"

        query_str << additional_criteria

        if (filtro.cliente)
          query_str << "fatture_clienti.cliente_id = ?"
          parametri << filtro.cliente
        end

        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:select => "clienti.id as id, clienti.denominazione as denominazione, sum(pagamenti_fatture_clienti.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:fattura_cliente_scadenzario => :cliente},
            :group => "clienti.id, clienti.denominazione",
            :order => "clienti.denominazione"}
          )

      end

      def build_totole_pagamenti_ripresa_saldi_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "pagamenti_fatture_clienti.registrato_in_prima_nota = 1"
        query_str << "pagamenti_fatture_clienti.maxi_pagamento_cliente_id is null"
        query_str << "pagamenti_fatture_clienti.data_pagamento < ?"
        parametri << get_date(:from)

        query_str << "fatture_clienti.da_scadenzario = 1"

        query_str << additional_criteria

        if (filtro.cliente)
          query_str << "fatture_clienti.cliente_id = ?"
          parametri << filtro.cliente
        end

        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:select => "clienti.id as id, clienti.denominazione as denominazione, sum(pagamenti_fatture_clienti.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:fattura_cliente_scadenzario => :cliente},
            :group => "clienti.id, clienti.denominazione",
            :order => "clienti.denominazione"}
          )

      end

      def build_totole_maxi_pagamenti_saldi_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "maxi_pagamenti_clienti.chiuso = 1"

        query_str << "maxi_pagamenti_clienti.data_pagamento >= ?"
        parametri << get_date(:from)
        query_str << "maxi_pagamenti_clienti.data_pagamento <= ?"
        parametri << get_date(:to)

        query_str << additional_criteria

        if (filtro.cliente)
          query_str << "fatture_clienti.cliente_id = ?"
          parametri << filtro.cliente
        end

        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:select => "clienti.id as id, clienti.denominazione as denominazione, maxi_pagamenti_clienti.importo as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:pagamenti_fattura_cliente => {:fattura_cliente => :cliente}},
            :group => "clienti.id, clienti.denominazione, maxi_pagamenti_clienti.id, maxi_pagamenti_clienti.importo",
            :order => "clienti.denominazione"}
          )

      end

      def build_totole_maxi_pagamenti_ripresa_saldi_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "maxi_pagamenti_clienti.chiuso = 1"

        query_str << "maxi_pagamenti_clienti.data_pagamento < ?"
        parametri << get_date(:from)

        query_str << additional_criteria

        if (filtro.cliente)
          query_str << "fatture_clienti.cliente_id = ?"
          parametri << filtro.cliente
        end

        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:select => "clienti.id as id, clienti.denominazione as denominazione, maxi_pagamenti_clienti.importo as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:pagamenti_fattura_cliente => {:fattura_cliente => :cliente}},
            :group => "clienti.id, clienti.denominazione, maxi_pagamenti_clienti.id, maxi_pagamenti_clienti.importo",
            :order => "clienti.denominazione"}
          )

      end

      def build_totole_fatture_saldi_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "fatture_fornitori.data_emissione >= ?"
        parametri << get_date(:from)
        query_str << "fatture_fornitori.data_emissione <= ?"
        parametri << get_date(:to)

        query_str << additional_criteria

        if (filtro.fornitore)
          query_str << "fatture_fornitori.fornitore_id = ?"
          parametri << filtro.fornitore
        end

        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:select => "fornitori.id as id, fornitori.denominazione as denominazione, sum(fatture_fornitori.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => :fornitore,
            :group => "fornitori.id, fornitori.denominazione",
            :order => "fornitori.denominazione"}
          )

      end

      def build_totole_fatture_ripresa_saldi_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "fatture_fornitori.data_emissione < ?"
        parametri << get_date(:from)

        query_str << additional_criteria

        if (filtro.fornitore)
          query_str << "fatture_fornitori.fornitore_id = ?"
          parametri << filtro.fornitore
        end

        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:select => "fornitori.id as id, fornitori.denominazione as denominazione, sum(fatture_fornitori.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => :fornitore,
            :group => "fornitori.id, fornitori.denominazione",
            :order => "fornitori.denominazione"}
          )

      end

      def build_totole_pagamenti_saldi_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "pagamenti_fatture_fornitori.registrato_in_prima_nota = 1"
        query_str << "pagamenti_fatture_fornitori.maxi_pagamento_fornitore_id is null"
        query_str << "pagamenti_fatture_fornitori.data_pagamento >=  ?"
        parametri << get_date(:from)
        query_str << "pagamenti_fatture_fornitori.data_pagamento <=  ?"
        parametri << get_date(:to)

        query_str << additional_criteria

        if (filtro.fornitore)
          query_str << "fatture_fornitori.fornitore_id = ?"
          parametri << filtro.fornitore
        end

        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:select => "fornitori.id as id, fornitori.denominazione as denominazione, sum(pagamenti_fatture_fornitori.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:fattura_fornitore => :fornitore},
            :group => "fornitori.id, fornitori.denominazione",
            :order => "fornitori.denominazione"}
          )

      end

      def build_totole_pagamenti_ripresa_saldi_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "pagamenti_fatture_fornitori.registrato_in_prima_nota = 1"
        query_str << "pagamenti_fatture_fornitori.maxi_pagamento_fornitore_id is null"
        query_str << "pagamenti_fatture_fornitori.data_pagamento < ?"
        parametri << get_date(:from)

        query_str << additional_criteria

        if (filtro.fornitore)
          query_str << "fatture_fornitori.fornitore_id = ?"
          parametri << filtro.fornitore
        end

        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:select => "fornitori.id as id, fornitori.denominazione as denominazione, sum(pagamenti_fatture_fornitori.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:fattura_fornitore => :fornitore},
            :group => "fornitori.id, fornitori.denominazione",
            :order => "fornitori.denominazione"}
          )

      end

      def build_totole_maxi_pagamenti_saldi_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "maxi_pagamenti_fornitori.chiuso = 1"

        query_str << "maxi_pagamenti_fornitori.data_pagamento >= ?"
        parametri << get_date(:from)
        query_str << "maxi_pagamenti_fornitori.data_pagamento <= ?"
        parametri << get_date(:to)

        query_str << additional_criteria

        if (filtro.fornitore)
          query_str << "fatture_fornitori.fornitore_id = ?"
          parametri << filtro.fornitore
        end

        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:select => "fornitori.id as id, fornitori.denominazione as denominazione, maxi_pagamenti_fornitori.importo as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:pagamenti_fattura_fornitore => {:fattura_fornitore => :fornitore}},
            :group => "fornitori.id, fornitori.denominazione, maxi_pagamenti_fornitori.id, maxi_pagamenti_fornitori.importo",
            :order => "fornitori.denominazione"}
          )

      end

      def build_totole_maxi_pagamenti_ripresa_saldi_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "maxi_pagamenti_fornitori.chiuso = 1"

        query_str << "maxi_pagamenti_fornitori.data_pagamento < ?"
        parametri << get_date(:from)

        query_str << additional_criteria

        if (filtro.fornitore)
          query_str << "fatture_fornitori.fornitore_id = ?"
          parametri << filtro.fornitore
        end

        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:select => "fornitori.id as id, fornitori.denominazione as denominazione, maxi_pagamenti_fornitori.importo as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:pagamenti_fattura_fornitore => {:fattura_fornitore => :fornitore}},
            :group => "fornitori.id, fornitori.denominazione, maxi_pagamenti_fornitori.id, maxi_pagamenti_fornitori.importo",
            :order => "fornitori.denominazione"}
          )

      end

      def date_scadenze_fatture_clienti_conditions(query_str, parametri)

        data_dal = get_date(:from)
        data_al = get_date(:to)

        query_str << "pagamenti_fatture_clienti.data_pagamento >= ?"
        parametri << data_dal
        query_str << "pagamenti_fatture_clienti.data_pagamento <= ?"
        parametri << data_al

        query_str << "pagamenti_fatture_clienti.registrato_in_prima_nota = 0"

      end

      def fatture_clienti_common_conditions(query_str, parametri)
        unless filtro.residuo
          if filtro.modalita
            if(filtro.tipo_pagamento)
              query_str << "pagamenti_fatture_clienti.tipo_pagamento_id = ?"
              parametri << filtro.tipo_pagamento
            else
              query_str << "pagamenti_fatture_clienti.tipo_pagamento_id is null"
            end
          end

          if(filtro.banca)
            query_str << "pagamenti_fatture_clienti.banca_id = ?"
            parametri << filtro.banca
          end

          unless filtro.fattura_num.blank?
            query_str << "fatture_clienti.num = ?"
            parametri << filtro.fattura_num
          end

          if filtro.saldi_aperti
            query_str << "pagamenti_fatture_clienti.registrato_in_prima_nota = 0"
          end
        end

        if (filtro.cliente)
          query_str << "fatture_clienti.cliente_id = ?"
          parametri << filtro.cliente
        end

      end

      def build_estratto_fornitori_report_conditions()
        query_str = []
        parametri = []

        date_estratto_fatture_fornitori_conditions(query_str, parametri)
        fatture_fornitori_common_conditions(query_str, parametri)

        {:conditions => [query_str.join(' AND '), *parametri],
          :include => [:fornitore, {:pagamento_fattura_fornitore => [:tipo_pagamento, :banca, {:maxi_pagamento_fornitore => [:tipo_pagamento, :banca]}]}],
          :order => "fornitori.denominazione, fatture_fornitori.data_emissione, pagamenti_fatture_fornitori.data_pagamento"
        }
      end

      def build_partitario_fornitori_report_conditions()
        query_str = []
        parametri = []

        date_partitario_fatture_fornitori_conditions(query_str, parametri)
        fatture_fornitori_common_conditions(query_str, parametri)

        {:conditions => [query_str.join(' AND '), *parametri],
          :include => [:fornitore, {:pagamento_fattura_fornitore => [:tipo_pagamento, :banca, {:maxi_pagamento_fornitore => [:tipo_pagamento, :banca]}]}],
          :order => "fornitori.denominazione, fatture_fornitori.data_emissione, pagamenti_fatture_fornitori.data_pagamento"
        }
      end

      def build_saldi_fornitori_report_conditions()
        query_str = []
        parametri = []

        if (filtro.fornitore)
          query_str << "fornitori.id = ?"
          parametri << filtro.fornitore
        end


        {:conditions => [query_str.join(' AND '), *parametri],
            :order => "fornitori.denominazione"}

      end

      def build_scadenze_fornitori_report_conditions()
        query_str = []
        parametri = []

        date_scadenze_fatture_fornitori_conditions(query_str, parametri)
        fatture_fornitori_common_conditions(query_str, parametri)

        {:conditions => [query_str.join(' AND '), *parametri],
          :include => [:fornitore, {:pagamento_fattura_fornitore => [:tipo_pagamento, :banca, {:maxi_pagamento_fornitore => [:tipo_pagamento, :banca]}]}],
          :order => "pagamenti_fatture_fornitori.data_pagamento, fornitori.denominazione, fatture_fornitori.data_emissione"
        }
      end

      def build_totale_fatture_estratto_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "fatture_fornitori.data_emissione < ?"
        parametri << get_date(:from)

        fatture_fornitori_common_conditions(query_str, parametri)

        query_str << additional_criteria

        # aggiunto per la chiamata alla funzione sum
        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:conditions => [query_str.join(' AND '), *parametri], :include => [:fornitore]}

      end

      def build_totale_pagamenti_estratto_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "fatture_fornitori.data_emissione < ?"
        parametri << get_date(:from)

        fatture_fornitori_common_conditions(query_str, parametri)

        query_str << additional_criteria

        # aggiunto per la chiamata alla funzione sum
        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:conditions => [query_str.join(' AND '), *parametri], :include => [:fattura_fornitore => [:fornitore]]}

      end

      def build_totale_fatture_partitario_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "fatture_fornitori.data_emissione < ?"
        parametri << get_date(:from)

        fatture_fornitori_common_conditions(query_str, parametri)

        query_str << additional_criteria

        # aggiunto per la chiamata alla funzione sum
        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:conditions => [query_str.join(' AND '), *parametri], :include => [:fornitore]}

      end

      def build_totale_pagamenti_partitario_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "pagamenti_fatture_fornitori.data_pagamento < ?"
        parametri << get_date(:from)

        fatture_fornitori_common_conditions(query_str, parametri)

        query_str << additional_criteria

        # aggiunto per la chiamata alla funzione sum
        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        {:conditions => [query_str.join(' AND '), *parametri], :include => [:fattura_fornitore => [:fornitore]]}

      end

      def date_estratto_fatture_fornitori_conditions(query_str, parametri)
        data_dal = get_date(:from)
        data_al = get_date(:to)

        query_str << "fatture_fornitori.data_emissione >= ?"
        parametri << data_dal
        query_str << "fatture_fornitori.data_emissione <= ?"
        parametri << data_al

      end

      def date_partitario_fatture_fornitori_conditions(query_str, parametri)
        data_dal = get_date(:from)
        data_al = get_date(:to)

        or1_str = []
        or1_str << "fatture_fornitori.data_emissione >= ?"
        parametri << data_dal
        or1_str << "fatture_fornitori.data_emissione <= ?"
        parametri << data_al
        or2_str = []
        or2_str << "pagamenti_fatture_fornitori.data_pagamento >= ?"
        parametri << data_dal
        or2_str << "pagamenti_fatture_fornitori.data_pagamento <= ?"
        parametri << data_al
        or3_str = []
        or3_str << "pagamenti_fatture_fornitori.data_pagamento < ?"
        parametri << data_dal

        query_str << ('(%s)' % ([('(%s)' % or1_str.join(' and ')), ('(%s)' % or2_str.join(' and ')), ('(%s)' % or3_str.join(' and '))].join(' or ')))

      end

      def date_saldi_fatture_fornitori_conditions(query_str, parametri)
        data_al = get_date(:to)

        or1_str = []
        or1_str << "fatture_fornitori.data_emissione <= ?"
        parametri << data_al
        or1_str << "pagamenti_fatture_fornitori.registrato_in_prima_nota = 0"
        or2_str = []
        or2_str << "pagamenti_fatture_fornitori.data_pagamento > ?"
        parametri << data_al
        or2_str << "pagamenti_fatture_fornitori.registrato_in_prima_nota = 1"
        or2_str << "fatture_fornitori.data_emissione <= ?"
        parametri << data_al

        query_str << ('(%s)' % ([('(%s)' % or1_str.join(' and ')), ('(%s)' % or2_str.join(' and '))].join(' or ')))

      end

      def date_scadenze_fatture_fornitori_conditions(query_str, parametri)

        data_dal = get_date(:from)
        data_al = get_date(:to)

        query_str << "pagamenti_fatture_fornitori.data_pagamento >= ?"
        parametri << data_dal
        query_str << "pagamenti_fatture_fornitori.data_pagamento <= ?"
        parametri << data_al
        query_str << "pagamenti_fatture_fornitori.registrato_in_prima_nota = 0"

      end

      def fatture_fornitori_common_conditions(query_str, parametri)
        unless filtro.residuo
          if filtro.modalita
            if(filtro.tipo_pagamento)
              query_str << "pagamenti_fatture_fornitori.tipo_pagamento_id = ?"
              parametri << filtro.tipo_pagamento
            else
              query_str << "pagamenti_fatture_fornitori.tipo_pagamento_id is null"
            end
          end

          if(filtro.banca)
            query_str << "pagamenti_fatture_fornitori.banca_id = ?"
            parametri << filtro.banca
          end

          if filtro.saldi_aperti
            query_str << "pagamenti_fatture_fornitori.registrato_in_prima_nota = 0"
          end

          unless filtro.fattura_num.blank?
            query_str << "fatture_fornitori.num = ?"
            parametri << filtro.fattura_num
          end

        end

        if (filtro.fornitore)
          query_str << "fatture_fornitori.fornitore_id = ?"
          parametri << filtro.fornitore
        end

      end

      def optional_conditions_enabled?()
        if(filtro.modalita or
              filtro.banca or
              (!filtro.fattura_num.blank?) or
              filtro.saldi_aperti)
          return true
        else
          return false
        end
      end

      def show_saldi(really=true)
        self.cpt_ripresa_saldo.show(really)
        self.cpt_totale_saldo.show(really)
        self.lbl_ripresa_saldo.show(really)
        self.lbl_ripresa_saldo.show(really)
      end

    end

  end
end
