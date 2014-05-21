# encoding: utf-8

require 'app/views/scadenzario/incasso_bilancio_panel'
require 'app/views/scadenzario/pagamento_bilancio_panel'

module Views
  module Scadenzario
    module IncassiPagamentiBilancioFolder
      include Views::Base::Folder

      def ui
        logger.debug('initializing Scadenzario IncassiPagamentiBilancioFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('INCASSO_BILANCIO_PANEL', self, :extends => Views::Scadenzario::IncassoBilancioPanel)
        incasso_bilancio_panel.ui()
        xrc.find('PAGAMENTO_BILANCIO_PANEL', self, :extends => Views::Scadenzario::PagamentoBilancioPanel)
        pagamento_bilancio_panel.ui()

      end

      def init_folder()
        incasso_bilancio_panel.init_panel()
        pagamento_bilancio_panel.init_panel()
      end

      def reset_folder()
        incasso_bilancio_panel.reset_panel()
        pagamento_bilancio_panel.reset_panel()
      end

    end
  end
end
