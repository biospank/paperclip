# encoding: utf-8

require 'app/helpers/mvc_helper'
require 'app/helpers/authorization_helper'
require 'app/views/base/widget'
require 'app/views/base/custom_event'

module Views
  module Base
    module EventDispatcher
      def setup_listeners
        @@event_dispatcher_listeners = {}
      end

      def subscribe(event, &callback)
        (@@event_dispatcher_listeners[event] ||= []) << callback
      end

      protected
      # notifica tutti quelli registrati per un certo evento
      # eseguendo la callback (oggetti Proc) registrata.
      # Viene utilizzata per l'aggiornamento dell'interfaccia ed
      # evitare di avere riferimenti all'interno del codice
      def notify(event, *args)
        if @@event_dispatcher_listeners[event]
          @@event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
        return nil
      end
    end

    module View
      include Helpers::Logger
      include Helpers::WxHelper
      include Helpers::AuthorizationHelper
      include EventDispatcher

      attr_accessor :source # mantiene i dati del chiamante

      def log_error(parent, error)
        logger.error("Error type: " + error.class.inspect)
        logger.error("Error message: " + error.message)
        logger.error("Fault objec: " + parent.class.name)
        logger.error("Backtrace: " + error.backtrace.join("\n")) unless error.backtrace.nil?

        Wx::log_error("Error type: " + error.class.inspect)
        Wx::log_message("Fault object: " + parent.class.name)
        Wx::log_message("Error message: " + error.message)
        Wx::log_error("Backtrace: " + error.backtrace.join("\n")) unless error.backtrace.nil?
        #log_warning("And then something went wrong!")

        # and if ~BusyCursor doesn't do it, then call it manually
        #Wx::yield()

        Wx::log_error("Errore:\n\n#{error.message}\n\nSe il problema persiste contattare il fornitore.\n" )

#          Wx::log_error("Si e' verificato un errore, se il problema persiste contattare il fornitore.\n" \
#                              "Se il problema persiste contattare il fornitore.")

        Wx::Log::flush_active()
        
      end
      
      def enable_widgets(wds)
        wds.each do |widget|
          widget.enable()
        end
      end
      
      def disable_widgets(wds)
        wds.each do |widget|
          widget.enable(false)
        end
      end
      
      
    end
    
    module Folder
      include View
      include Views::Base::Widget
      
      def init_folder()
        # noop method
        # need override
      end

    end
    
    module Panel
      include View
      include Views::Base::Widget
      
      def init_panel()
        # noop method
        # need override
      end
      
    end
    
    module Dialog
      include View
      include Views::Base::Widget

      attr_accessor :selected

    end

    module MultipleSelectionReport
      attr_accessor :all_selections

      def all_valid_selections
        @all_selections.keys.compact
      end
    end

  end
end