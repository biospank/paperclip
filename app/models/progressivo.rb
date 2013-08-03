# encoding: utf-8

module Models
  class Progressivo < ActiveRecord::Base
    include Base::Model
    
    def self.aggiorna_progressivo(documento)
      counter = search(:first, :conditions => ["anno_rif = ?", documento.data_emissione.year])
      if counter.nil?
        counter = self.new(:azienda_id => Azienda.current.id,
          :progressivo => documento.num.to_i,
          :anno_rif => documento.data_emissione.year)
                          
      else
        if documento.num.to_i > counter.progressivo
          counter.progressivo = documento.num.to_i
        end
      end
      counter.save!
    end

    def self.next_sequence(anno)
      pgr = self.search(:first, :conditions => ["anno_rif = ?", anno.to_i])
      pgr.nil? ? 1 : (pgr.progressivo + 1)
    end

    def self.remove_sequence(anno)
      self.search(:first, :conditions => ["anno_rif = ?", anno.to_i]).destroy
    end

    validates_presence_of :anno_rif,
      :message => "Selezionare l'anno del progressivo da modificare."
    
  end
end