# encoding: utf-8

module Controllers
  module ConfigurazioneController
    include Controllers::BaseController
    include Helpers::ConfigurazioneHelper

    def load_dati_azienda()
      Azienda.current.dati_azienda.reload
    end

    def save_dati_azienda()
      dati_azienda.save!
      Azienda.current.dati_azienda.reload
    end

    # gestione banche

# implementato nel base
#    def load_banca(id)
#      Banca.find(id)
#    end

    def load_banca_by_codice(codice)
      Banca.search(:first, :conditions => {:codice => codice})
    end

    def save_banca()
      banca.save
    end

    def delete_banca()
      banca.destroy
    end

    def search_for_banche()
      Banca.search_for(filtro.ricerca,
        [:codice, :descrizione],
        build_banche_dialog_conditions())
    end

    def build_banche_dialog_conditions()
      query_str = []
      parametri = []

      filtro.build_conditions(query_str, parametri) if filtro

      {:conditions => [query_str.join(' AND '), *parametri],
       :order => 'codice'}
    end

    # gestione utenti

    def save_utente()
      utente.save!
      permessi.each_pair do |key, p|
        p.utente = utente
        p.save
      end
    end

    def load_utente(id)
      Utente.find(id, :include => :permessi)
    end

    def search_for_utenti()
      conditions = Utente.system? ? nil : "utenti.id != '#{Utente::SYSTEM}'"
      Utente.search_for(filtro.ricerca, [:login], :conditions => conditions)
    end

    # gestione progressivi

    def save_progressivo()
      begin
        progressivo.save!
      rescue Exception => ex
        logger.error("Errore in save_progressivo: #{ex.message}")
        raise ex
      end
    end

    def save_aliquota_prodotti(from, to)
      Models::Prodotto.update_all("aliquota_id = #{to}", "aliquota_id = #{from}")
    end

    # gestione base dati

    def save_db_server()
      db_server.save
    end

    def load_db_server()
      DbServer.first() || PaperclipConfig::UDPClient.query_db_server()
    end

    # Dump schema and data to db/schema.rb and db/data.yml
    def dump()
      Db::Schema.dump()
      Db::Data.dump()
    end

    # Load schema and data from db/schema.rb and db/data.yml
    def restore()
      Db::Schema.restore()
      Db::Data.restore()
    end

  end
end
