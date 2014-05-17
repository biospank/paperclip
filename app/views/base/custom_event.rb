# encoding: utf-8

# creare i custom events solo per centralizzare procedure complesse in frame di base
# altrimenti utilizzare il sistema di subscribe/notify
module Views
  module Base
    module CustomEvent
      class NewEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_NEW = Wx::EvtHandler.register_class(self, nil, 'evt_new', 0)

        def initialize(subject, caller)
          # The constant id is the arg to super
          super(EVT_NEW)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :subject => subject, :caller => caller  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def data
          client_data
        end

      end

      class BackEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_BACK = Wx::EvtHandler.register_class(self, nil, 'evt_back', 0)

        def initialize()
          # The constant id is the arg to super
          super(EVT_BACK)
        end

      end

      class ClienteChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_CLIENTE_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_cliente_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_CLIENTE_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class FornitoreChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_FORNITORE_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_fornitore_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_FORNITORE_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class AliquotaChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_ALIQUOTA_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_aliquota_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_ALIQUOTA_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class NormaChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_NORMA_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_norma_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_NORMA_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class RitenutaChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_RITENUTA_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_ritenuta_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_RITENUTA_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class IncassoRicorrenteChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_INCASSO_RICORRENTE_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_incasso_ricorrente_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_INCASSO_RICORRENTE_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class CausaleChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_CAUSALE_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_causale_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_CAUSALE_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class BancaChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_BANCA_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_banca_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_BANCA_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class PdcChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_PDC_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_pdc_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_PDC_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class CategoriaPdcChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_CATEGORIA_PDC_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_categoria_pdc_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_CATEGORIA_PDC_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class TipoPagamentoClienteChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_TIPO_PAGAMENTO_CLIENTE_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_tipo_pagamento_cliente_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_TIPO_PAGAMENTO_CLIENTE_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class TipoPagamentoFornitoreChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_TIPO_PAGAMENTO_FORNITORE_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_tipo_pagamento_fornitore_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_TIPO_PAGAMENTO_FORNITORE_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class ProdottoChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_PRODOTTO_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_prodotto_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_PRODOTTO_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class AnniContabiliNsChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_ANNI_CONTABILI_NS_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_anni_contabili_ns_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_ANNI_CONTABILI_NS_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class AnniContabiliFatturaChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_ANNI_CONTABILI_FATTURA_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_anni_contabili_fattura_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_ANNI_CONTABILI_FATTURA_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class AnniContabiliScritturaChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_ANNI_CONTABILI_SCRITTURA_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_anni_contabili_scrittura_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_ANNI_CONTABILI_SCRITTURA_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class AnniContabiliCorrispettiviChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_ANNI_CONTABILI_CORRISPETTIVI_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_anni_contabili_corrispettivi_changed', 0)

        def initialize(result_set)
          # The constant id is the arg to super
          super(EVT_ANNI_CONTABILI_CORRISPETTIVI_CHANGED)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :result_set => result_set  }
        end

        # Returns set associated with this event
        def result_set
          client_data[:result_set]
        end

      end

      class ScadenzaInSospesoEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_SCADENZA_IN_SOSPESO = Wx::EvtHandler.register_class(self, nil, 'evt_scadenza_in_sospeso', 0)

        # reload indica se i pagamenti/incassi devono essere ricaricati
        def initialize(reload=true)
          # The constant id is the arg to super
          super(EVT_SCADENZA_IN_SOSPESO)
          # client_data should be used to store any information associated
          # with the event.
          self.client_data = { :reload => reload }
#          self.id = target.get_id
        end

        # Returns set associated with this event
        def reload?
          client_data[:reload]
        end

      end

      class DettaglioIncassoEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_DETTAGLIO_INCASSO = Wx::EvtHandler.register_class(self, nil, 'evt_dettaglio_incasso', 0)

        def initialize(incasso)
          # The constant id is the arg to super
          super(EVT_DETTAGLIO_INCASSO)
          self.client_data = { :incasso => incasso }

        end

        # Returns data associated with this event
        def incasso
          client_data[:incasso]
        end
      end

      class DettaglioPagamentoEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_DETTAGLIO_PAGAMENTO = Wx::EvtHandler.register_class(self, nil, 'evt_dettaglio_pagamento', 0)

        def initialize(pagamento)
          # The constant id is the arg to super
          super(EVT_DETTAGLIO_PAGAMENTO)
          self.client_data = { :pagamento => pagamento }

        end

        # Returns data associated with this event
        def pagamento
          client_data[:pagamento]
        end
      end

      class DettaglioScritturaEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_DETTAGLIO_SCRITTURA = Wx::EvtHandler.register_class(self, nil, 'evt_dettaglio_scrittura', 0)

        def initialize(scrittura)
          # The constant id is the arg to super
          super(EVT_DETTAGLIO_SCRITTURA)
          self.client_data = { :scrittura => scrittura }

        end

        # Returns data associated with this event
        def scrittura
          client_data[:scrittura]
        end
      end

      class DettaglioFatturaPrimaNotaEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_DETTAGLIO_FATTURA_PRIMA_NOTA = Wx::EvtHandler.register_class(self, nil, 'evt_dettaglio_fattura_prima_nota', 0)

        def initialize(fattura)
          # The constant id is the arg to super
          super(EVT_DETTAGLIO_FATTURA_PRIMA_NOTA)
          self.client_data = { :fattura => fattura }

        end

        # Returns data associated with this event
        def fattura
          client_data[:fattura]
        end
      end

      class DettaglioCorrispettivoEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_DETTAGLIO_CORRISPETTIVO = Wx::EvtHandler.register_class(self, nil, 'evt_dettaglio_corrispettivo', 0)

        def initialize(corrispettivo)
          # The constant id is the arg to super
          super(EVT_DETTAGLIO_CORRISPETTIVO)
          self.client_data = { :corrispettivo => corrispettivo }

        end

        # Returns data associated with this event
        def corrispettivo
          client_data[:corrispettivo]
        end
      end

      class DettaglioFatturaScadenzarioEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_DETTAGLIO_FATTURA_SCADENZARIO = Wx::EvtHandler.register_class(self, nil, 'evt_dettaglio_fattura_scadenzario', 0)

        def initialize(fattura)
          # The constant id is the arg to super
          super(EVT_DETTAGLIO_FATTURA_SCADENZARIO)
          self.client_data = { :fattura => fattura }

        end

        # Returns data associated with this event
        def fattura
          client_data[:fattura]
        end
      end

      class DettaglioFatturaFatturazioneEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_DETTAGLIO_FATTURA_FATTURAZIONE = Wx::EvtHandler.register_class(self, nil, 'evt_dettaglio_fattura_fatturazione', 0)

        def initialize(fattura)
          # The constant id is the arg to super
          super(EVT_DETTAGLIO_FATTURA_FATTURAZIONE)
          self.client_data = { :fattura => fattura }

        end

        # Returns data associated with this event
        def fattura
          client_data[:fattura]
        end
      end

      class DettaglioNotaSpeseEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_DETTAGLIO_NOTA_SPESE = Wx::EvtHandler.register_class(self, nil, 'evt_dettaglio_nota_spese', 0)

        def initialize(nota_spese)
          # The constant id is the arg to super
          super(EVT_DETTAGLIO_NOTA_SPESE)
          self.client_data = { :nota_spese => nota_spese }

        end

        # Returns data associated with this event
        def nota_spese
          client_data[:nota_spese]
        end
      end

      class DettaglioOrdineEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_DETTAGLIO_ORDINE = Wx::EvtHandler.register_class(self, nil, 'evt_dettaglio_ordine', 0)

        def initialize(ordine)
          # The constant id is the arg to super
          super(EVT_DETTAGLIO_ORDINE)
          self.client_data = { :ordine => ordine }

        end

        # Returns data associated with this event
        def ordine
          client_data[:ordine]
        end
      end

      class DettagliorReportPartitarioBilancioEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_DETTAGLIO_REPORT_PARTITARIO_BILANCIO = Wx::EvtHandler.register_class(self, nil, 'evt_dettaglio_report_partitario_bilancio', 0)

        def initialize(pdc, filtro)
          # The constant id is the arg to super
          super(EVT_DETTAGLIO_REPORT_PARTITARIO_BILANCIO)
          self.client_data = { :pdc => pdc, :filtro => filtro }

        end

        # Returns data associated with this event
        def pdc
          client_data[:pdc]
        end

        def filtro
          client_data[:filtro]
        end
      end

      class AziendaChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_AZIENDA_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_azienda_changed', 0)

        def initialize(old)
          # The constant id is the arg to super
          super(EVT_AZIENDA_CHANGED)
          self.client_data = { :old => old }
        end

        # Returns data associated with this event
        def old
          client_data[:old]
        end
      end

      class AziendaUpdatedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_AZIENDA_UPDATED = Wx::EvtHandler.register_class(self, nil, 'evt_azienda_updated', 0)

        def initialize()
          # The constant id is the arg to super
          super(EVT_AZIENDA_UPDATED)
        end

      end

      class ConfigChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_CONFIG_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_config_changed', 0)

        def initialize(host)
          # The constant id is the arg to super
          super(EVT_CONFIG_CHANGED)
          self.client_data = { :host => host }

        end

        # Returns data associated with this event
        def host
          client_data[:host]
        end

      end

      class MagazzinoChangedEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_MAGAZZINO_CHANGED = Wx::EvtHandler.register_class(self, nil, 'evt_magazzino_changed', 0)

        def initialize()
          # The constant id is the arg to super
          super(EVT_MAGAZZINO_CHANGED)
        end

      end

      class ForceExitEvent < Wx::NotifyEvent
        # Create a new unique constant identifier, associate this class
        # with events of that identifier, and create a shortcut 'evt_target'
        # method for setting up this handler.
        EVT_FORCE_EXIT = Wx::EvtHandler.register_class(self, nil, 'evt_force_exit', 0)

        def initialize(restart = false)
          # The constant id is the arg to super
          super(EVT_FORCE_EXIT)
          self.client_data = { :restart => restart }
        end

        # Returns data associated with this event
        def restart?
          client_data[:restart]
        end
      end

    end
  end
end
