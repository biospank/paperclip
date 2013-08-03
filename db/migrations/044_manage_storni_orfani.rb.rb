class ManageStorniOrfani < ActiveRecord::Migration
  def self.up
    
    change_column :prima_nota, :descrizione, :string, :null => false, :limit => 500

    storni = Models::Scrittura.all(:conditions => ["descrizione like ? and parent_id is null", '** STORNO SCRITTURA%'])
    
    storni.each do |storno|
      m = storno.descrizione.match(/\s\*\*\s/)
      desc = m.post_match
      if scrittura = Models::Scrittura.first(:conditions => ["descrizione = ?", desc])
        storno.parent = scrittura
        storno.save_with_validation(false)
      else
        storno.destroy
      end
    end

  end

  def self.down

  end
end
