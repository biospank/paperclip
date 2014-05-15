# encoding: utf-8

require 'app/helpers/running'
require 'app/helpers/number_helper'
require 'app/helpers/zip_helper'
require 'app/helpers/http_helper'

module Helpers
  module ApplicationHelper
    extend NumberHelper

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
