# encoding: utf-8

module Helpers
  module PrimaNotaHelper
    WXBRA_SCRITTURE_FOLDER = 0
    WXBRA_CAUSALI_FOLDER = 1
    WXBRA_PDC_FOLDER = 2
    WXBRA_REPORT_FOLDER = 3
    
    # subfolder
    WXBRA_REPORT_STAMPE_FOLDER = 0
    WXBRA_REPORT_PARTITARIO_FOLDER = 1

    CASSA = 'CASSA'
    BANCA = 'BANCA'
    FUORI_PARTITA = 'FUORI PARTITA'
    PARTITE = [CASSA, BANCA, FUORI_PARTITA]


    # Modelli Anagrafica
    ScrittureStampeTemplatePath = 'resources/models/report/scritture/scritture_stampe.odt'
    ScritturePartitarioTemplatePath = 'resources/models/report/scritture/scritture_partitario.odt'

    # Bootstrap
    # stampe
    StampeHeaderTemplatePath = 'resources/templates/report/scritture/stampe_header.html.erb'
    StampeBodyTemplatePath = 'resources/templates/report/scritture/stampe_body.html.erb'
    PartitarioHeaderTemplatePath = 'resources/templates/report/scritture/partitario_header.html.erb'
    PartitarioBodyTemplatePath = 'resources/templates/report/scritture/partitario_body.html.erb'

  end
end
