# encoding: utf-8

module Helpers
  module AnagraficaHelper
    WXBRA_ANAGRAFICA_FOLDER = 0
    WXBRA_REPORT_ANAGRAFICA_FOLDER = 1

    CLIENTI = 1
    FORNITORI = 2
    Categoria = {CLIENTI => 'CLIENTI',
                 FORNITORI => 'FORNITORI'}
    
    # Modelli Anagrafica
    AnagraficaTemplatePath = 'resources/models/report/anagrafica/anagrafica.odt'
    AnagraficaDettTemplatePath = 'resources/models/report/anagrafica/anagrafica_dett.odt'

    # Bootstrap
    # stampe
    AnagraficaHeaderTemplatePath = 'resources/templates/report/anagrafica/anagrafica_header.html.erb'
    AnagraficaBodyTemplatePath = 'resources/templates/report/anagrafica/anagrafica_body.html.erb'
  end
end
