# encoding: utf-8

require 'app/views/scadenzario/report_clienti_notebook_mgr'

module Views
  module Anagrafica
    module ReportFornitoriFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      def ui

        model :filtro => {:attrs => []}
        controller :anagrafica

        logger.debug('initializing ReportFornitoriFolder...')
        xrc = Xrc.instance()
        # Anagrafica fornitore
        
        xrc.find('chk_attivi', self, :extends => CheckField)
        xrc.find('chk_dettagliata', self, :extends => CheckField)
        xrc.find('lstrep_anagrafica', self, :extends => ReportField)
        
        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        # lista fornitori
        
        lstrep_anagrafica.column_info([{:caption => 'Denominazione', :width => 180},
                                        {:caption => 'Codice fiscale', :width => 150},
                                        {:caption => 'Partita iva', :width => 80},
                                        {:caption => 'Indirizzo', :width => 180},
                                        {:caption => 'Citta', :width => 100},
                                        {:caption => 'Telefono', :width => 80},
                                        {:caption => 'Cellulare', :width => 80},
                                        {:caption => 'Attivo', :width => 60},
                                        {:caption => 'Note', :width => 200}])
                                      
        lstrep_anagrafica.data_info([{:attr => :denominazione},
                                     {:attr => :cod_fisc},
                                     {:attr => :p_iva},
                                     {:attr => :indirizzo},
                                     {:attr => :citta},
                                     {:attr => :telefono},
                                     {:attr => :cellulare},
                                     {:attr => :attivo},
                                     {:attr => :note}])

        map_events(self)
        
        subscribe(:evt_azienda_changed) do
          reset_folder()
        end

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F5, btn_ricerca.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F9, btn_stampa.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end
      
      def reset_folder()
        lstrep_anagrafica.reset()
        result_set_lstrep_anagrafica.clear()
      end
      
      # Gestione eventi
      
      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          transfer_filtro_from_view()
          self.result_set_lstrep_anagrafica = ctrl.report_fornitori()
          lstrep_anagrafica.display_matrix(result_set_lstrep_anagrafica)
        rescue Exception => e
          log_error(self, e)
        end
      end

      def btn_pulisci_click(evt)
        logger.debug("Cliccato sul bottone pulisci!")
        begin
          lstrep_anagrafica.reset()
          result_set_lstrep_anagrafica.clear()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_stampa_click(evt)
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda

          generate(:report_anagrafica,
            :footer => false,
            :margin_top => 40,
            :dati_azienda => dati_azienda
          )

        end

      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]
        categoria = 'Fornitori'

        header.write(
          ERB.new(
            IO.read(Helpers::AnagraficaHelper::AnagraficaHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::AnagraficaHelper::AnagraficaBodyTemplatePath)
          ).result(binding)
        )

      end

#      def btn_stampa_click(evt)
#        Wx::BusyCursor.busy() do
#          if chk_dettagliata.checked?
#            template = Helpers::AnagraficaHelper::AnagraficaDettTemplatePath
#          else
#            template = Helpers::AnagraficaHelper::AnagraficaTemplatePath
#          end
#
#          generate(template)
#        end
#      end
#
#      def render_header(report, whatever=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        report.add_field :denominazione, dati_azienda.denominazione
#        report.add_field :intestazione, ['Anagrafica Fornitori', dati_azienda.denominazione].join(' ')
#
#      end
#
#      def render_body(report, whatever=nil)
#        if chk_dettagliata.checked?
#          report.add_table("Report", self.result_set_lstrep_anagrafica, :header=>true) do |t|
#            t.add_column(:nominativo) {|row| row[0]}
#            t.add_column(:codice_fiscale) {|row| row[1]}
#            t.add_column(:partita_iva) {|row| row[2]}
#            t.add_column(:indirizzo) {|row| row[3]}
#            t.add_column(:citta) {|row| row[4]}
#            t.add_column(:telefono) {|row| row[5]}
#            t.add_column(:cellulare) {|row| row[6]}
#          end
#        else
#          report.add_table("Report", self.result_set_lstrep_anagrafica, :header=>true) do |t|
#            t.add_column(:nominativo) {|row| row[0]}
#            t.add_column(:codice_fiscale) {|row| row[1]}
#            t.add_column(:partita_iva) {|row| row[2]}
#            t.add_column(:telefono) {|row| row[5]}
#            t.add_column(:cellulare) {|row| row[6]}
#          end
#        end
#      end
      
    end
  end
end
