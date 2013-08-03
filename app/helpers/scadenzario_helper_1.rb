# encoding: utf-8

module Helpers
  module ScadenzarioHelper
    WXBRA_SCADENZARIO_CLIENTI_FOLDER = 0
    WXBRA_SCADENZARIO_FORNITORI_FOLDER = 1
    WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER = 2
    WXBRA_REPORT_SCADENZARIO_FOLDER = 3

    WXBRA_REPORT_SCADENZARIO_CLIENTI_FOLDER = 0
    WXBRA_REPORT_SCADENZARIO_FORNITORI_FOLDER = 1

    WXBRA_ESTRATTO_REPORT_CLIENTI_FOLDER = 0
    WXBRA_PARTITARIO_REPORT_CLIENTI_FOLDER = 1
    WXBRA_SALDI_REPORT_CLIENTI_FOLDER = 2
    WXBRA_SCADENZE_REPORT_CLIENTI_FOLDER = 3

    WXBRA_ESTRATTO_REPORT_FORNITORI_FOLDER = 0
    WXBRA_PARTITARIO_REPORT_FORNITORI_FOLDER = 1
    WXBRA_SALDI_REPORT_FORNITORI_FOLDER = 2
    WXBRA_SCADENZE_REPORT_FORNITORI_FOLDER = 3

    # stampe
    ReportEstrattoHeaderTemplatePath = 'resources/templates/report/scadenzario/report_estratto_header.html.erb'.freeze
    ReportEstrattoFooterTemplatePath = 'resources/templates/report/scadenzario/report_estratto_footer.html.erb'.freeze
    ReportEstrattoBodyTemplatePath = 'resources/templates/report/scadenzario/report_estratto_body.html.erb'.freeze

    ReportPartitarioHeaderTemplatePath = 'resources/templates/report/scadenzario/report_partitario_header.html.erb'.freeze
    ReportPartitarioFooterTemplatePath = 'resources/templates/report/scadenzario/report_partitario_footer.html.erb'.freeze
    ReportPartitarioBodyTemplatePath = 'resources/templates/report/scadenzario/report_partitario_body.html.erb'.freeze

    ReportScadenzeHeaderTemplatePath = 'resources/templates/report/scadenzario/report_scadenze_header.html.erb'.freeze
    ReportScadenzeFooterTemplatePath = 'resources/templates/report/scadenzario/report_scadenze_footer.html.erb'.freeze
    ReportScadenzeBodyTemplatePath = 'resources/templates/report/scadenzario/report_scadenze_body.html.erb'.freeze

    GRID_ROW_LIMIT = 17
    REPORT_GRID_ROW_LIMIT = 33

    # Modelli Report
    EstrattoClientiTemplatePath = "resources/models/report/scadenzario/estratto_clienti.odt"
    EstrattoFornitoriTemplatePath = "resources/models/report/scadenzario/estratto_fornitori.odt"
    PartitarioClientiTemplatePath = "resources/models/report/scadenzario/partitario_clienti.odt"
    PartitarioFornitoriTemplatePath = "resources/models/report/scadenzario/partitario_fornitori.odt"
    SaldiClientiTemplatePath = "resources/models/report/scadenzario/saldi_clienti.odt"
    SaldiFornitoriTemplatePath = "resources/models/report/scadenzario/saldi_fornitori.odt"
    ScadenzeClientiTemplatePath = "resources/models/report/scadenzario/scadenze_clienti.odt"
    ScadenzeFornitoriTemplatePath = "resources/models/report/scadenzario/scadenze_fornitori.odt"

    module Report
      include Models
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

        temp_fatture_max_ids = {}
        MaxiPagamentoCliente.search(:all,
          build_totole_maxi_pagamenti_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"])).
            each {|item| (temp_fatture_max_ids[item.max_id] = item)}

        temp_fatture_max_ids.each {|item| (tot_maxi_pag[item.id] ||= []) << item}

        FatturaCliente.search(:all,
          build_totole_fatture_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"])).
            each {|item| ripresa_tot_fatt[item.id] = item}

        PagamentoFatturaCliente.search(:all,
          build_totole_pagamenti_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"])).
            each {|item| ripresa_tot_pag[item.id] = item}

        temp_ripresa_saldi_fatture_max_ids = {}
        MaxiPagamentoCliente.search(:all,
          build_totole_maxi_pagamenti_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 0"])).
            each {|item| (temp_ripresa_saldi_fatture_max_ids[item.max_id] = item)}

        temp_ripresa_saldi_fatture_max_ids.each {|item| (ripresa_tot_maxi_pag[item.id] ||= []) << item}

        FatturaCliente.search(:all,
          build_totole_fatture_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| tot_nc[item.id] = item}

        PagamentoFatturaCliente.search(:all,
          build_totole_pagamenti_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| tot_pag_nc[item.id] = item}

        temp_nc_max_ids = {}
        MaxiPagamentoCliente.search(:all,
          build_totole_maxi_pagamenti_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| (temp_nc_max_ids[item.max_id] = item)}

        temp_nc_max_ids.each {|item| (tot_maxi_pag_nc[item.id] ||= []) << item}

        FatturaCliente.search(:all,
          build_totole_fatture_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| ripresa_tot_nc[item.id] = item}

        PagamentoFatturaCliente.search(:all,
          build_totole_pagamenti_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| ripresa_tot_pag_nc[item.id] = item}

        temp_ripresa_saldi_nc_max_ids = {}
        MaxiPagamentoCliente.search(:all,
          build_totole_maxi_pagamenti_ripresa_saldi_clienti_report_conditions(["fatture_clienti.nota_di_credito = 1"])).
            each {|item| (temp_ripresa_saldi_nc_max_ids[item.max_id] = item)}

        temp_ripresa_saldi_nc_max_ids.each {|item| (ripresa_tot_maxi_pag_nc[item.id] ||= []) << item}

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
            logger.info "Dati maxi pagamento: #{dati_maxi_pagamento.inspect}"
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
            logger.info "Ripresa Dati maxi pagamento: #{ripresa_dati_maxi_pagamento.inspect}"
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
        query_str << "pagamenti_fatture_clienti.registrato_in_prima_nota = 1"

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

        {:select => "maxi_pagamenti_clienti.id as max_id, clienti.id as id, clienti.denominazione as denominazione, maxi_pagamenti_clienti.importo as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:pagamenti_fattura_cliente => {:fattura_cliente => :cliente}},
            :group => "maxi_pagamenti_clienti.id, clienti.id, clienti.denominazione, maxi_pagamenti_clienti.importo",
            :order => "clienti.denominazione"}
          )

      end

      def build_totole_maxi_pagamenti_ripresa_saldi_clienti_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "maxi_pagamenti_clienti.chiuso = 1"
        query_str << "pagamenti_fatture_clienti.registrato_in_prima_nota = 1"

        query_str << "maxi_pagamenti_clienti.data_pagamento < ?"
        parametri << get_date(:from)

        query_str << additional_criteria

        if (filtro.cliente)
          query_str << "fatture_clienti.cliente_id = ?"
          parametri << filtro.cliente
        end

        query_str << "fatture_clienti.azienda_id = ?"
        parametri << Azienda.current

        {:select => "maxi_pagamenti_clienti.id as max_id, clienti.id as id, clienti.denominazione as denominazione, maxi_pagamenti_clienti.importo as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:pagamenti_fattura_cliente => {:fattura_cliente => :cliente}},
            :group => "maxi_pagamenti_clienti.id, clienti.id, clienti.denominazione, maxi_pagamenti_clienti.importo",
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
        query_str << "pagamenti_fatture_fornitori.registrato_in_prima_nota = 1"

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

        # la funzione di aggregazione max, in questa query, viene utilizzata per evitare di mettere la colonna nella group by ottenendo un risultato diverso da quello atteso
        # vincolo richiesto da Postgresql (giustamente)
        {:select => "fornitori.id as id, fornitori.denominazione as denominazione, max(maxi_pagamenti_fornitori.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:pagamenti_fattura_fornitore => {:fattura_fornitore => :fornitore}},
            :group => "maxi_pagamenti_fornitori.id, fornitori.id, fornitori.denominazione",
            :order => "fornitori.denominazione"}
          )

      end

      def build_totole_maxi_pagamenti_ripresa_saldi_fornitori_report_conditions(additional_criteria)
        query_str = []
        parametri = []

        query_str << "maxi_pagamenti_fornitori.chiuso = 1"
        query_str << "pagamenti_fatture_fornitori.registrato_in_prima_nota = 1"

        query_str << "maxi_pagamenti_fornitori.data_pagamento < ?"
        parametri << get_date(:from)

        query_str << additional_criteria

        if (filtro.fornitore)
          query_str << "fatture_fornitori.fornitore_id = ?"
          parametri << filtro.fornitore
        end

        query_str << "fatture_fornitori.azienda_id = ?"
        parametri << Azienda.current

        # la funzione di aggregazione max, in questa query, viene utilizzata per evitare di mettere la colonna nella group by ottenendo un risultato diverso da quello atteso
        # vincolo richiesto da Postgresql (giustamente)
        {:select => "fornitori.id as id, fornitori.denominazione as denominazione, max(maxi_pagamenti_fornitori.importo) as importo",
          :conditions => [query_str.join(' AND '), *parametri]}.merge(
          {:joins => {:pagamenti_fattura_fornitore => {:fattura_fornitore => :fornitore}},
            :group => "maxi_pagamenti_fornitori.id, fornitori.id, fornitori.denominazione",
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
