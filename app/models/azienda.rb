# encoding: utf-8

module Models
  class Azienda < ActiveRecord::Base
    include Base::Model

    set_table_name :azienda
    has_one :dati_azienda
    has_many :magazzini,
      :class_name => 'Models::Magazzino',
      :conditions => {:attivo => 1}
    has_many :moduli,
      :class_name => 'Models::ModuloAzienda',
      :conditions => {:attivo => 1}

    ATTIVITA = {
      :commercio => 1,
      :servizi   => 2
    } unless const_defined? 'ATTIVITA'

    # LE VARIABILI DI CLASSE DEVONO ESSERE INIZIALIZZATE
    @@all = nil
    @@current = nil

#    def Azienda.all=(all)
#      @@all = all
#    end

    def Azienda.all
      @@all ||= find(:all)
    end

    def Azienda.current=(azienda)
      @@current = azienda
    end

    def Azienda.current
      @@current
    end

    def include?(modulo)
      moduli.map(&:modulo_id).include?(modulo)
    end
  end
end
