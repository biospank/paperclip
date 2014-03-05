# encoding: utf-8

module Helpers
  module PrimaNotaHelper
    WXBRA_SCRITTURE_FOLDER = 0
    WXBRA_CAUSALI_FOLDER = 1
    WXBRA_PDC_FOLDER = 2
    WXBRA_REPORT_FOLDER = 3
    
    # subfolder report
    WXBRA_REPORT_PRIMA_NOTA_FOLDER = 0
    WXBRA_REPORT_BILANCIO_FOLDER = 1

    # subfolder report prima nota
    WXBRA_REPORT_STAMPE_FOLDER = 0
    WXBRA_REPORT_PARTITARIO_FOLDER = 1

    # subfolder report bilancio
    WXBRA_BILANCIO_DI_VERIFICA_FOLDER = 0
    WXBRA_REPORT_BILANCIO_PARTITARIO_FOLDER = 1

    # subfolder bilancio di verifica
    WXBRA_STATO_PATRIMONIALE_FOLDER = 0
    WXBRA_CONTO_ECONOMICO_FOLDER = 1

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
