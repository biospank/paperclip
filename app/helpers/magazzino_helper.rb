# encoding: utf-8

module Helpers
  module MagazzinoHelper
    WXBRA_ORDINE_FOLDER = 0
    WXBRA_IMPOSTAZIONI_FOLDER = 1
    WXBRA_CARICO_FOLDER = 2
    WXBRA_SCARICO_FOLDER = 3
    WXBRA_REPORT_FOLDER = 4

    # subfolder
    WXBRA_REPORT_ORDINI_FOLDER = 0
    WXBRA_REPORT_MOVIMENTI_FOLDER = 1
    WXBRA_REPORT_GIACENZE_FOLDER = 2

    # Bootstrap
    # stampe
    OrdineHeaderTemplatePath = "resources/templates/magazzino/ordine_header.html.erb"
    OrdineBodyTemplatePath = "resources/templates/magazzino/ordine_body.html.erb"
    OrdineFooterTemplatePath = "resources/templates/magazzino/ordine_footer.html.erb"

    #report
    OrdiniHeaderTemplatePath = "resources/templates/report/magazzino/ordini_header.html.erb"
    OrdiniBodyTemplatePath = "resources/templates/report/magazzino/ordini_body.html.erb"
    #OrdiniFooterTemplatePath = "resources/templates/report/magazzino/ordini_footer.html.erb"
    GiacenzeHeaderTemplatePath = "resources/templates/report/magazzino/giacenze_header.html.erb"
    GiacenzeBodyTemplatePath = "resources/templates/report/magazzino/giacenze_body.html.erb"
    GiacenzeFooterTemplatePath = "resources/templates/report/magazzino/giacenze_footer.html.erb"
    MovimentiHeaderTemplatePath = "resources/templates/report/magazzino/movimenti_header.html.erb"
    MovimentiBodyTemplatePath = "resources/templates/report/magazzino/movimenti_body.html.erb"
    #MovimentiFooterTemplatePath = "resources/templates/report/magazzino/movimenti_footer.html.erb"

  end
end