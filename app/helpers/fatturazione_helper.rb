# encoding: utf-8

module Helpers
  module FatturazioneHelper
    WXBRA_NOTA_SPESE_FOLDER = 0
    WXBRA_FATTURA_FOLDER = 1
    WXBRA_CORRISPETTIVI_FOLDER = 2
    WXBRA_DDT_FOLDER = 3
    WXBRA_IMPOSTAZIONI_FOLDER = 4
    WXBRA_REPORT_FOLDER = 5
    
    # subfolder
    WXBRA_REPORT_ESTRATTO_FOLDER = 0
    WXBRA_REPORT_FATTURE_FOLDER = 1
    WXBRA_REPORT_DA_FATTURARE_FOLDER = 2
    WXBRA_REPORT_CORRISPETTIVI_FOLDER = 3
    WXBRA_REPORT_FLUSSI_FOLDER = 4

    # Modelli Fattura
    FatturaCommercioTemplatePath = "resources/models/fattura/commercio.odt"
    FatturaServiziTemplatePath = "resources/models/fattura/servizi.odt"
    FatturaCommercioLogoTemplatePath = "resources/models/fattura/commercio_logo.odt"
    FatturaServiziLogoTemplatePath = "resources/models/fattura/servizi_logo.odt"

    # Modelli Nota spese
    NotaSpeseCommercioTemplatePath = "resources/models/nota_spese/commercio.odt"
    NotaSpeseServiziTemplatePath = "resources/models/nota_spese/servizi.odt"
    NotaSpeseCommercioLogoTemplatePath = "resources/models/nota_spese/commercio_logo.odt"
    NotaSpeseServiziLogoTemplatePath = "resources/models/nota_spese/servizi_logo.odt"
    
    # Modelli Ddt
    DdtTemplatePath = "resources/models/ddt/ddt.odt"
    DdtTemplateLogoPath = "resources/models/ddt/ddt_logo.odt"
    
    # Modelli Report
    EstrattoTemplatePath = "resources/models/report/fatturazione/estratto.odt"
    FattureTemplatePath = "resources/models/report/fatturazione/fatture.odt"
    DaFatturareTemplatePath = "resources/models/report/fatturazione/da_fatturare.odt"
    FlussiTemplatePath = "resources/models/report/fatturazione/flussi.odt"


    # template bootstrap
    # fattura
    FatturaHeaderTemplatePath = 'resources/templates/fattura/fattura_header.html.erb'
    FatturaBodyTemplatePath = 'resources/templates/fattura/fattura_body.html.erb'
    FatturaFooterTemplatePath = 'resources/templates/fattura/fattura_footer.html.erb'

    # nota spese
    NotaSpeseHeaderTemplatePath = 'resources/templates/nota_spese/nota_spese_header.html.erb'
    NotaSpeseBodyTemplatePath = 'resources/templates/nota_spese/nota_spese_body.html.erb'
    NotaSpeseFooterTemplatePath = 'resources/templates/nota_spese/nota_spese_footer.html.erb'

    # ddt
    DdtHeaderTemplatePath = 'resources/templates/ddt/ddt_header.html.erb'
    DdtBodyTemplatePath = 'resources/templates/ddt/ddt_body.html.erb'
    DdtFooterTemplatePath = 'resources/templates/ddt/ddt_footer.html.erb'

    # report
    DaFatturareHeaderTemplatePath = "resources/templates/report/fatturazione/da_fatturare_header.html.erb"
    DaFatturareBodyTemplatePath = "resources/templates/report/fatturazione/da_fatturare_body.html.erb"
    DaFatturareFooterTemplatePath = "resources/templates/report/fatturazione/da_fatturare_footer.html.erb"

    EstrattoHeaderTemplatePath = "resources/templates/report/fatturazione/estratto_header.html.erb"
    EstrattoBodyTemplatePath = "resources/templates/report/fatturazione/estratto_body.html.erb"
    EstrattoFooterTemplatePath = "resources/templates/report/fatturazione/estratto_footer.html.erb"

    FattureHeaderTemplatePath = "resources/templates/report/fatturazione/fatture_header.html.erb"
    FattureBodyTemplatePath = "resources/templates/report/fatturazione/fatture_body.html.erb"
    FattureFooterTemplatePath = "resources/templates/report/fatturazione/fatture_footer.html.erb"

    CorrispettiviHeaderTemplatePath = "resources/templates/report/fatturazione/corrispettivi_header.html.erb"
    CorrispettiviBodyTemplatePath = "resources/templates/report/fatturazione/corrispettivi_body.html.erb"
    CorrispettiviFooterTemplatePath = "resources/templates/report/fatturazione/corrispettivi_footer.html.erb"

    FlussiHeaderTemplatePath = "resources/templates/report/fatturazione/flussi_header.html.erb"
    FlussiBodyTemplatePath = "resources/templates/report/fatturazione/flussi_body.html.erb"
  end
end
