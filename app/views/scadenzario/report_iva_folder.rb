# encoding: utf-8

module Views
  module Scadenzario
    module ReportIvaFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      SALDO_LIMITE_PERIODO_PRECEDENTE = 50.0
      
      attr_accessor :iva_debito,
        :iva_credito,
        :diff_iva_debito,
        :diff_iva_credito,
        :iva_debito_periodo_precedente,
        :iva_credito_periodo_precedente,
        :interessi_trimestrali,
        :totale_iva_debito,
        :totale_iva_credito

      def ui
        logger.debug('initializing Scadenzario ReportIvaFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()

        xrc.find('lbl_iva_debito', self)
        xrc.find('lbl_iva_credito', self)
        xrc.find('lbl_diff_iva_debito', self)
        xrc.find('lbl_diff_iva_credito', self)
        xrc.find('lbl_iva_debito_periodo_precedente', self)
        xrc.find('lbl_iva_credito_periodo_precedente', self)
        xrc.find('lbl_interessi_trimestrali', self)
        xrc.find('lbl_totale_iva_debito', self)
        xrc.find('lbl_totale_iva_credito', self)

      end

      def init_folder()
        # noop
        
      end
      
      def reset_folder()
        reset_totali()
      end

      def riepilogo(filtro)
        reset_totali()
        self.iva_credito = owner.report_acquisti_folder.totale_iva_detraibile
        iva_vendite = owner.report_vendite_folder.totale_iva
        iva_corrispettivi = owner.report_corrispettivi_folder.totale_iva
        self.iva_debito = iva_vendite + iva_corrispettivi

        self.lbl_iva_debito.label = Helpers::ApplicationHelper.currency(self.iva_debito)
        self.lbl_iva_credito.label = Helpers::ApplicationHelper.currency(self.iva_credito)

        self.diff_iva_debito = 0.0
        self.diff_iva_credito = 0.0
        
        if(Helpers::ApplicationHelper.real(self.iva_debito) >= Helpers::ApplicationHelper.real(self.iva_credito))
          self.diff_iva_debito = (self.iva_debito - self.iva_credito)
          self.lbl_diff_iva_debito.label = Helpers::ApplicationHelper.currency(self.diff_iva_debito) unless self.diff_iva_debito.zero?
        else
          self.diff_iva_credito = (self.iva_credito - self.iva_debito)
          self.lbl_diff_iva_credito.label = Helpers::ApplicationHelper.currency(self.diff_iva_credito) unless self.diff_iva_credito.zero?
        end

        if Models::Azienda.current.dati_azienda.liquidazione_iva == Helpers::ApplicationHelper::Liquidazione::MENSILE
          
          if (filtro.periodo.to_i == 1)
            anno = (filtro.anno.to_i - 1)
            mese = 12
          else
            anno = filtro.anno.to_i
            mese = (filtro.periodo.to_i - 1)
          end

          if saldo_periodo_precedente = Models::SaldoIvaMensile.search(:first, :conditions => ["anno = ? and mese = ?", anno, mese])
            self.iva_debito_periodo_precedente = saldo_periodo_precedente.debito || 0.0
            self.lbl_iva_debito_periodo_precedente.label = Helpers::ApplicationHelper.currency(self.iva_debito_periodo_precedente) if((!self.iva_debito_periodo_precedente.zero?) && (self.iva_debito_periodo_precedente < SALDO_LIMITE_PERIODO_PRECEDENTE))
            self.iva_credito_periodo_precedente = saldo_periodo_precedente.credito || 0.0
            self.lbl_iva_credito_periodo_precedente.label = Helpers::ApplicationHelper.currency(self.iva_credito_periodo_precedente) unless self.iva_credito_periodo_precedente.zero?
          else
            self.iva_debito_periodo_precedente = 0.0
            self.iva_credito_periodo_precedente = 0.0
          end
          
          self.totale_iva_debito = (self.diff_iva_debito + self.iva_debito_periodo_precedente) if self.iva_debito_periodo_precedente < SALDO_LIMITE_PERIODO_PRECEDENTE
          self.totale_iva_credito = (self.diff_iva_credito + self.iva_credito_periodo_precedente)

          if(Helpers::ApplicationHelper.real(self.totale_iva_debito) >= Helpers::ApplicationHelper.real(self.totale_iva_credito))
            self.lbl_totale_iva_debito.label = Helpers::ApplicationHelper.currency(self.totale_iva_debito - self.totale_iva_credito)
          else
            self.lbl_totale_iva_credito.label = Helpers::ApplicationHelper.currency(self.totale_iva_credito - self.totale_iva_debito)
          end

          if saldo = Models::SaldoIvaMensile.search(:first, :conditions => ["anno = ? and mese = ?", filtro.anno.to_i, filtro.periodo.to_i])
            saldo.update_attributes(:debito => self.totale_iva_debito, :credito => self.totale_iva_credito)
          else
            Models::SaldoIvaMensile.create(
              :azienda => Models::Azienda.current,
              :anno => filtro.anno.to_i,
              :mese => filtro.periodo.to_i,
              :debito => self.totale_iva_debito,
              :credito => self.totale_iva_credito
            )
          end
        else
          if (filtro.periodo.to_i == 1)
            anno = (filtro.anno.to_i - 1)
            trimestre = 4
          else
            anno = filtro.anno.to_i
            trimestre = (filtro.periodo.to_i - 1)
          end

          if saldo_periodo_precedente = Models::SaldoIvaTrimestrale.search(:first, :conditions => ["anno = ? and trimestre = ?", anno, trimestre])
            self.iva_debito_periodo_precedente = saldo_periodo_precedente.debito || 0.0
            self.lbl_iva_debito_periodo_precedente.label = Helpers::ApplicationHelper.currency(self.iva_debito_periodo_precedente) if((!self.iva_debito_periodo_precedente.zero?) && (self.iva_debito_periodo_precedente < SALDO_LIMITE_PERIODO_PRECEDENTE))
            self.iva_credito_periodo_precedente = saldo_periodo_precedente.credito || 0.0
            self.lbl_iva_credito_periodo_precedente.label = Helpers::ApplicationHelper.currency(self.iva_credito_periodo_precedente) unless self.iva_credito_periodo_precedente.zero?
          else
            self.iva_debito_periodo_precedente = 0.0
            self.iva_credito_periodo_precedente = 0.0
          end

          unless self.diff_iva_debito.zero?
            percentuale_interessi_trimestrali = Models::InteressiLiquidazioneTrimestrale.first
            self.interessi_trimestrali = ((self.diff_iva_debito * percentuale_interessi_trimestrali.percentuale) / 100)
            self.lbl_interessi_trimestrali.label = Helpers::ApplicationHelper.currency(self.interessi_trimestrali)
            self.totale_iva_debito = self.diff_iva_debito + self.interessi_trimestrali
          end
          
          self.totale_iva_debito = (self.totale_iva_debito + self.iva_debito_periodo_precedente) if self.iva_debito_periodo_precedente < SALDO_LIMITE_PERIODO_PRECEDENTE
          self.totale_iva_credito = (self.diff_iva_credito + self.iva_credito_periodo_precedente)

          if(Helpers::ApplicationHelper.real(self.totale_iva_debito) >= Helpers::ApplicationHelper.real(self.totale_iva_credito))
            self.lbl_totale_iva_debito.label = Helpers::ApplicationHelper.currency(self.totale_iva_debito - self.totale_iva_credito)
          else
            self.lbl_totale_iva_credito.label = Helpers::ApplicationHelper.currency(self.totale_iva_credito - self.totale_iva_debito)
          end

          if saldo = Models::SaldoIvaTrimestrale.search(:first, :conditions => ["anno = ? and trimestre = ?", filtro.anno.to_i, filtro.periodo.to_i])
            saldo.update_attributes(:debito => self.totale_iva_debito, :credito => self.totale_iva_credito)
          else
            Models::SaldoIvaTrimestrale.create(
              :azienda => Models::Azienda.current,
              :anno => filtro.anno.to_i,
              :trimestre => filtro.periodo.to_i,
              :debito => self.totale_iva_debito,
              :credito => self.totale_iva_credito
            )
          end

        end

      end

      def stampa(filtro)
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda

          generate(:report_iva,
            :margin_top => 40,
            :margin_bottom => 25,
            :dati_azienda => dati_azienda,
            :filtro => filtro,
            :preview => false
          )

        end

      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]
        filtro = opts[:filtro]

        begin
          header.write(
            ERB.new(
              IO.read(Helpers::ScadenzarioHelper::IvaHeaderTemplatePath)
            ).result(binding)
          )
        rescue Exception => e
          log_error(self, e)
        end

      end

      def render_body(opts={})
        begin
          body.write(
            ERB.new(
              IO.read(Helpers::ScadenzarioHelper::IvaBodyTemplatePath)
            ).result(binding)
          )
        rescue Exception => e
          log_error(self, e)
        end
      end

      private

      def reset_totali()
        self.iva_debito = 0.0
        self.iva_credito = 0.0
        self.diff_iva_debito = 0.0
        self.diff_iva_credito = 0.0
        self.iva_debito_periodo_precedente = 0.0
        self.iva_credito_periodo_precedente = 0.0
        self.interessi_trimestrali = 0.0
        self.totale_iva_debito = 0.0
        self.totale_iva_credito = 0.0
        self.lbl_iva_debito.label = ''
        self.lbl_iva_credito.label = ''
        self.lbl_diff_iva_debito.label = ''
        self.lbl_diff_iva_credito.label = ''
        self.lbl_iva_debito_periodo_precedente.label = ''
        self.lbl_iva_credito_periodo_precedente.label = ''
        self.lbl_interessi_trimestrali.label = ''
        self.lbl_totale_iva_debito.label = ''
        self.lbl_totale_iva_credito.label = ''
      end
    end
  end
end
