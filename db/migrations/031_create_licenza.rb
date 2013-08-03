class CreateLicenza < ActiveRecord::Migration
  def self.up
    create_table :licenza do |t|
      t.string  :numero_seriale, :limit => 100
      t.date    :data_scadenza
      t.string  :versione, :limit => 20
    end

    execute "INSERT INTO LICENZA VALUES(1, '', '2008-12-25', '2.0')"

  end

  def self.down
    drop_table :licenza
  end
end
