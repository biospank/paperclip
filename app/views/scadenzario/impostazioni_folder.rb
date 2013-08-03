# encoding: utf-8

require 'app/views/scadenzario/incasso_panel'
require 'app/views/scadenzario/pagamento_panel'

module Views
  module Scadenzario
    module ImpostazioniFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing Scadenzario ImopstazioniPanel...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('INCASSO_PANEL', self, :extends => Views::Scadenzario::IncassoPanel)
        incasso_panel.ui()
        xrc.find('PAGAMENTO_PANEL', self, :extends => Views::Scadenzario::PagamentoPanel)
        pagamento_panel.ui()

      end

      def init_folder()
        incasso_panel.init_panel()
        pagamento_panel.init_panel()
      end
      
    end
  end
end
