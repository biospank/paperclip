# encoding: utf-8

require 'digest/sha1'

module Models
  class Utente < ActiveRecord::Base
    include Base::Model

    set_table_name :utenti
    belongs_to :profilo, :foreign_key => 'profilo_id'
    belongs_to :azienda, :foreign_key => 'azienda_id'
    has_many :permessi, :class_name => 'Models::Permesso'
    
    validates_presence_of :login, :message => "Inserire il nome utente nel campo 'Login'"
    validates_presence_of :password, :message => "Inserire la password"
    validates_uniqueness_of :login, :message => "Login già utilizzata"

    ADMIN = 1
    SYSTEM = 2

    # Please change the salt to something else, 
    # Every application should use a different one 
    @@salt = 'bra'
    cattr_accessor :salt
    attr_accessor :ricerca

    @@current = nil

    # utente loggato
    def Utente.current=(utente)
      @@current = utente
    end
  
    def Utente.current
      @@current
    end

    def Utente.system?
      Utente.current.id == SYSTEM
    end

    def Utente.admin?
      Utente.current.id == ADMIN
    end

    # utente generico
    def admin?
      self.id == ADMIN
    end

    def permessi_for(modulo_azienda)
      permessi.detect {|p| p.modulo_azienda_id == modulo_azienda.id}
    end

    def permessi_by(modulo)
      permessi.detect {|p| p.modulo_azienda.modulo_id == modulo}
    end

    # Authenticate a user. 
    #
    # Example:
    #   @user = User.authenticate('bob', 'bobpass')
    #
    def self.authenticate(login, pass, azienda)
      find(:first, :conditions => ["login = ? AND password = ? and ((azienda_id = ?) or (id in (#{SYSTEM},#{ADMIN})))", login, sha1(pass), azienda])
    end  
  
    # Apply SHA1 encryption to the supplied password. 
    # We will additionally surround the password with a salt 
    # for additional security. 
    def self.sha1(pass)
      Digest::SHA1.hexdigest("#{salt}--#{pass}--")
    end
  
    before_create do |utente|
      utente.password = utente.class.sha1(utente.password)
      utente.profilo_id = Profilo::USER
      utente.azienda = Azienda.current
    end

    before_update do |utente|
      utente.password = utente.class.sha1(utente.password) if utente.password_changed?
    end
  
  end
end