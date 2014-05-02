# encoding: utf-8

require 'app/views/prima_nota/bilancio_di_verifica_notebook_mgr'

module Views
  module PrimaNota
    module BilancioDiVerificaFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      def ui
        model :filtro => {:attrs => []}
        controller :scadenzario

        logger.debug('initializing Bilancio BilancioDiVerificaFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()

        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_scrittura_changed) do |data|
          chce_anno.load_data(data, :select => :last)
        end

        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)

        subscribe(:evt_azienda_changed) do
          init_folder()
        end

        xrc.find('btn_calcola', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        xrc.find('BILANCIO_DI_VERIFICA_NOTEBOOK_MGR', self, :extends => Views::PrimaNota::BilancioDiVerificaNotebookMgr)
        bilancio_di_verifica_notebook_mgr.ui()

        map_events(self)

      # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F5, btn_calcola.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F9, btn_stampa.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_pulisci.get_id ]
        ]
        self.accelerator_table = acc_table
      end

      def init_folder()
        bilancio_di_verifica_notebook_mgr.init_folder
      end

      def reset_folder()
        bilancio_di_verifica_notebook_mgr.reset_folder
      end

      # Gestione eventi

      def chce_anno_select(evt)
        begin
          Wx::BusyCursor.busy() do
            reset_folder()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_calcola_click(evt)
        begin
          Wx::BusyCursor.busy() do
            transfer_filtro_from_view()
            bilancio_di_verifica_notebook_mgr.ricerca(filtro)
            transfer_filtro_to_view()
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      def btn_pulisci_click(evt)
        logger.debug("Cliccato sul bottone pulisci!")
        begin
#          reset_folder()
#          bilancio_di_verifica_notebook_mgr.reset_folder
          Wx::BusyCursor.busy() do
            transfer_filtro_from_view()
            bilancio_di_verifica_notebook_mgr.ricerca_aggregata(filtro)
            transfer_filtro_to_view()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_stampa_click(evt)
        Wx::BusyCursor.busy() do
          logger.debug("bilancio_di_verifica_folder.btn_stampa_click")
          bilancio_di_verifica_notebook_mgr.stampa(filtro)
        end

      end

    end
  end
end

