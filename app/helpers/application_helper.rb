# encoding: utf-8

require 'app/helpers/running'
require 'app/helpers/number_helper'
require 'app/helpers/zip_helper'
require 'app/helpers/http_helper'

module Helpers
  module ApplicationHelper
    extend NumberHelper

    RESTART_EXIT_CODE = 8

    WXBRA_APP_NAME = 'Paperclip'
    WXBRA_CONF_PATH = 'conf/paperclip.yml'
    PAPERCLIP_CONF_PATH = 'conf/paperclip.rb'
    WXBRA_IMAGES_PATH = 'resources/images'

    # Costanti delle viste
    WXBRA_ANAGRAFICA_VIEW = 0
    WXBRA_FATTURAZIONE_VIEW = 1
    WXBRA_SCADENZARIO_VIEW = 2
    WXBRA_PRIMA_NOTA_VIEW = 3
    WXBRA_MAGAZZINO_VIEW = 4
    WXBRA_CONFIGURAZIONE_VIEW = 5

    module Modulo
      ANAGRAFICA = 10
      FATTURAZIONE = 20
      SCADENZARIO = 30
      PRIMA_NOTA = 40
      MAGAZZINO = 50
      CONFIGURAZIONE = 60
    end

    MODULI = {
      WXBRA_ANAGRAFICA_VIEW => Modulo::ANAGRAFICA,
      WXBRA_FATTURAZIONE_VIEW => Modulo::FATTURAZIONE,
      WXBRA_SCADENZARIO_VIEW => Modulo::SCADENZARIO,
      WXBRA_PRIMA_NOTA_VIEW => Modulo::PRIMA_NOTA,
      WXBRA_MAGAZZINO_VIEW => Modulo::MAGAZZINO,
      WXBRA_CONFIGURAZIONE_VIEW => Modulo::CONFIGURAZIONE
    }

    # colore dei report
    WXBRA_EVEN_ROW_COLOR = Wx::Colour.new(215, 235, 245)

    # colore dei campi con focus
    WXBRA_FOCUS_FIELD_COLOR = Wx::Colour.new(255, 255, 210)

    # colore dei campi con focus
    WXBRA_LOOKUP_FOCUS_FIELD_COLOR = Wx::Colour.new(220, 255, 220)

    # colore dei campi senza focus
    WXBRA_FIELD_COLOR = Wx::WHITE

    # logo di default
    WXBRA_DEFAULT_LOGO = "./resources/images/blank_logo.png"

    MESI = [
      {:id => '01', :descrizione => 'Gennaio'},
      {:id => '02', :descrizione => 'Febbraio'},
      {:id => '03', :descrizione => 'Marzo'},
      {:id => '04', :descrizione => 'Aprile'},
      {:id => '05', :descrizione => 'Maggio'},
      {:id => '06', :descrizione => 'Giugno'},
      {:id => '07', :descrizione => 'Luglio'},
      {:id => '08', :descrizione => 'Agosto'},
      {:id => '09', :descrizione => 'Settembre'},
      {:id => '10', :descrizione => 'Ottobre'},
      {:id => '11', :descrizione => 'Novembre'},
      {:id => '12', :descrizione => 'Dicembre'}
    ]

    module Aliquote
      TIPI_ESENZIONE = [
        {:id => nil, :descrizione => ''},
        {:id => 'N1', :descrizione => 'N1 - escluse ex art. 15'},
        {:id => 'N2', :descrizione => 'N2 - non soggette'},
        {:id => 'N2.1', :descrizione => 'N2.1 - non soggette ad IVA ai sensi degli Art. da 7 a 7-septies del DPR 633/72'},
        {:id => 'N2.2', :descrizione => 'N2.2 - non soggette - altri casi'},
        {:id => 'N3', :descrizione => 'N3 - non imponibili'},
        {:id => 'N3.1', :descrizione => 'N3.1 - non imponibili - esportazioni'},
        {:id => 'N3.2', :descrizione => 'N3.2 - non imponibili - cessioni intracomunitarie'},
        {:id => 'N3.3', :descrizione => 'N3.3 - non imponibili - cessioni verso San Marino'},
        {:id => 'N3.4', :descrizione => "N3.4 - non imponibili - operazioni assimilate alle cessioni all' esportazione"},
        {:id => 'N3.5', :descrizione => 'N3.5 - non imponibili - a seguito di dichiarazioni di intento'},
        {:id => 'N3.6', :descrizione => 'N3.6 - non imponibili - altre operazioni che non concorrono alla formazione del plafond'},
        {:id => 'N4', :descrizione => 'N4 - esenti'},
        {:id => 'N5', :descrizione => 'N5 - regime del margine/IVA non esposta in fattura'},
        {:id => 'N6', :descrizione => 'N6 - inversione contabile'},
        {:id => 'N6.1', :descrizione => 'N6.1 - inversione contabile - cessione di rottame e altri materiali di recupero'},
        {:id => 'N6.2', :descrizione => 'N6.2 - inversione contabile - cessione di oro e argento puro'},
        {:id => 'N6.3', :descrizione => 'N6.3 - inversione contabile - subappalto nel settore edile'},
        {:id => 'N6.4', :descrizione => 'N6.4 - inversione contabile - cessione di fabbricati'},
        {:id => 'N6.5', :descrizione => 'N6.5 - inversione contabile - cessione di telefoni cellulari'},
        {:id => 'N6.6', :descrizione => 'N6.6 - inversione contabile - cessione di prodotti elettronici'},
        {:id => 'N6.7', :descrizione => 'N6.7 - inversione contabile - prestazioni comparto edile e settori connessi'},
        {:id => 'N6.8', :descrizione => 'N6.8 - inversione contabile - operazioni settore energetico'},
        {:id => 'N6.9', :descrizione => 'N6.9 - inversione contabile - altri casi'},
        {:id => 'N7', :descrizione => 'N7 - IVA assolta in altro stato UE'}
      ]

      ESENZIONE_CON_BOLLO = [
        'N1',
        'N2.2',
        'N3.4',
        'N3.5',
        'N4'
      ]
    end

    module Fatturazione
      REGIMI_FISCALI = [
        {:id => 'RF01', :descrizione => 'RF01 - Ordinario'},
        {:id => 'RF02', :descrizione => 'RF02 - Contribuenti minimi (art. 1, c.96-117, L. 244/2007)'},
        {:id => 'RF04', :descrizione => 'RF04 - Agricoltura e attivita connesse e pesca (artt. 34 e 34-bis, D.P.R. 633/1972)'},
        {:id => 'RF05', :descrizione => 'RF05 - Vendita sali e tabacchi (art. 74, c.1, D.P.R. 633/1972)'},
        {:id => 'RF06', :descrizione => 'RF06 - Commercio dei fiammiferi (art. 74, c.1, D.P.R. 633/1972)'},
        {:id => 'RF07', :descrizione => 'RF07 - Editoria (art. 74, c.1, D.P.R. 633/1972)'},
        {:id => 'RF08', :descrizione => 'RF08 - Gestione di servizi di telefonia pubblica (art. 74, c.1, D.P.R. 633/1972)'},
        {:id => 'RF09', :descrizione => 'RF09 - Rivendita di documenti di trasporto pubblico e di sosta (art. 74, c.1, D.P.R. 633/1972)'},
        {:id => 'RF10', :descrizione => 'RF10 - Intrattenimenti, giochi e altre attivita di cui alla tariffa allegata al D.P.R. n. 640/72 (art. 74, c.6, D.P.R. 633/1972)'},
        {:id => 'RF11', :descrizione => 'RF11 - Agenzie di viaggi e turismo (art. 74-ter, D.P.R. 633/1972)'},
        {:id => 'RF12', :descrizione => 'RF12 - Agriturismo (art. 5, c.2, L. 413/1991)'},
        {:id => 'RF13', :descrizione => 'RF13 - Vendite a domicilio (art. 25-bis, c.6, D.P.R. 600/1973)'},
        {:id => 'RF14', :descrizione => "RF14 - Rivendita di beni usati, di oggetti d'arte, d'antiquariato o da collezione (art. 36, D.L. 41/1995)"},
        {:id => 'RF15', :descrizione => "RF15 - Agenzie di vendite all'asta di oggetti d'arte, antiquariato o da collezione (art. 40-bis, D.L. 41/1995)"},
        {:id => 'RF16', :descrizione => 'RF16 - IVA per cassa P.A. (art. 6, c.5, D.P.R. 633/1972)'},
        {:id => 'RF18', :descrizione => 'RF18 - Altro'},
        {:id => 'RF19', :descrizione => 'RF19 - Forfettario (art.1, c. 54-89, L. 190/2014)'}
      ]

      TIPI_DOCUMENTO = [
        {:id => 'TD01', :descrizione => 'TD01 - Fattura'},
        {:id => 'TD02', :descrizione => 'TD02 - Accounto/Anticipo su fattura'},
        {:id => 'TD03', :descrizione => 'TD03 - Acconto/Anticipo su parcella'},
        {:id => 'TD04', :descrizione => 'TD04 - Nota di Credito'},
        {:id => 'TD05', :descrizione => 'TD05 - Nota di Debito'},
        {:id => 'TD06', :descrizione => 'TD06 - Parcella'},
        {:id => 'TD16', :descrizione => 'TD16 - Integrazione fattura reverse charge interno'},
        {:id => 'TD17', :descrizione => "TD17 - Integrazione/Autofattura per acquisto servizio all' estero"},
        {:id => 'TD18', :descrizione => 'TD18 - Integrazione per acquisto di beni intracomunitari'},
        {:id => 'TD19', :descrizione => 'TD19 - Integrazione/Autofattura per acquisto beni ex art. 17 c.2 DPR 633/72'},
        {:id => 'TD20', :descrizione => 'TD20 - Autofattura per regolarizzazione e integrazione delle fatture (art.6 c.8 d.lgs. 471/97 o art. 46 c.5 D.L. 331/93)'},
        {:id => 'TD21', :descrizione => 'TD21 - Autofattura per splafonamento'},
        {:id => 'TD22', :descrizione => 'TD22 - Estrazione beni da Deposito IVA'},
        {:id => 'TD23', :descrizione => "TD23 - Estrazione beni da Deposito IVA con versamento dell'IVA"},
        {:id => 'TD24', :descrizione => "TD24 - Fattura differita di cui l'art. 21, comma 4, lettera a"},
        {:id => 'TD25', :descrizione => "TD25 - Fattura differita di cui l'art. 21, comma 4, terzo periodo lett. b"},
        {:id => 'TD26', :descrizione => 'TD26 - Cessione di beni ammortizzabili e per passaggi interni (ex art. 36 DPR 663/)'},
        {:id => 'TD27', :descrizione => 'TD27 - Fattura per autoconsume e per cessioni gratuite senza rivalsa'}
      ]

      TIPI_RITENUTA = [
        {:id => 'RT01', :descrizione => 'RT01 - Ritenuta persone fisiche'},
        {:id => 'RT02', :descrizione => 'RT02 - Ritenuta persone giuridiche'},
        {:id => 'RT03', :descrizione => 'RT03 - Contributo INPS'},
        {:id => 'RT04', :descrizione => 'RT04 - Contributo ENASARCO'},
        {:id => 'RT05', :descrizione => 'RT05 - Contributo ENPAM'},
        {:id => 'RT06', :descrizione => 'RT06 - Altro contributo previdenziale'}
      ]

      CAUSALI_PAGAMENTO = [
        {:id => 'A', :descrizione => "A - Lavoro autonomo abituale"},
        {:id => 'B', :descrizione => "B - Diritti d'autore opere e ingegno"},
        {:id => 'H', :descrizione => "H - Cessazione dei rapporti di agenzia"},
        {:id => 'L', :descrizione => "L - Diritti d'autore da parte di soggetto diverso dall'autore"},
        {:id => 'M', :descrizione => "M - Lavoro autonomo non esercitato abitualmente"},
        {:id => 'Q', :descrizione => "Q - Provvigioni agente o rappresentante di commercio monomandatario"},
        {:id => 'R', :descrizione => "R - Provvigioni agente o rappresentante di commercio plurimandatario"},
        {:id => 'U', :descrizione => "U - Provvigioni corrispote a procacciatori di affari"},
        {:id => 'W', :descrizione => "W - Corrispettivi erogati nel 2013 per prestazioni contratti d'appalto"},
        {:id => 'Z', :descrizione => "Z - Titolo diverso dai precedenti"}
      ]
    end

    module Liquidazione
      MENSILE = 1
      TRIMESTRALE = 2

      PERIODO = [
        {:id => MENSILE, :descrizione => 'Mensile'},
        {:id => TRIMESTRALE, :descrizione => 'Trimestrale'}
      ]

      RANGE_TO_TRIMESTRE = {
        1..3 => 1,
        4..6 => 2,
        7..9 => 3,
        10..12 => 4
      }

      RANGE_TO_POSITION = {
        1..3 => 0,
        4..6 => 1,
        7..9 => 2,
        10..12 => 3
      }

      TRIMESTRE_TO_RANGE = {
        1 => 1..3,
        2 => 4..6,
        3 => 7..9,
        4 => 10..12
      }

      PERIODO_TRIMESTRE = [
        {:id => 1, :descrizione => '1° trimestre (Gennaio - Marzo)'},
        {:id => 2, :descrizione => '2° trimestre (Aprile - Giugno)'},
        {:id => 3, :descrizione => '3° trimestre (Luglio - Settembre)'},
        {:id => 4, :descrizione => '4° trimestre (Ottobre - Dicembre)'}
      ]

      NUMERO_TRIMESTRE = {
        1 => '1° trimestre (Gennaio - Marzo)',
        2 => '2° trimestre (Aprile - Giugno)',
        3 => '3° trimestre (Luglio - Settembre)',
        4 => '4° trimestre (Ottobre - Dicembre)'
      }

    end

    # formattazione dei campi

    module_function

    def currency(x)
      if x.nil?
        ''
      else
        number_to_currency(x, :unit => '€', :separator => ',', :delimiter => '.')
      end
    end

    def percentage(x, precision=2)
      if x.nil?
        ''
      else
        number_to_percentage(x, {:precision => precision, :separator => ',', :delimiter => '.'})
      end
    end

    def number(x, precision = 2)
      if x.nil? or x.zero?
        ''
      else
        number_with_delimiter(number_with_precision(x, precision), '.', ',')
      end
    end

    def number_text(x)
      if x.nil?
        ''
      else
        number_with_precision(x, 2) # ritorna una stringa
        #number_with_precision(x, {:precision => 2, :separator => '.', :delimiter => ','}) # ritorna un numero
      end
    end

    def real(x)
      if x.nil? or x.zero?
        0.0
      else
        number_with_precision(x, 2).to_f
      end
    end

    def truncate(text, *args)
      options = args.extract_options!
      unless args.empty?
        ActiveSupport::Deprecation.warn('truncate takes an option hash instead of separate ' +
            'length and omission arguments', caller)

        options[:length] = args[0] || 30
        options[:omission] = args[1] || "..."
      end
      options.reverse_merge!(:length => 30, :omission => "...")

      if text
        l = options[:length] - options[:omission].mb_chars.length
        chars = text.mb_chars
        (chars.length > options[:length] ? chars[0...l] + options[:omission] : text).to_s
      end
    end

#    def real(x)
#      if x.nil? or x.zero?
#        '0,0'
#      else
#        number_with_delimiter(number_with_precision(x, 2), '.', ',')
#      end
#    end

  end
end
