class AddTimestamping < ActiveRecord::Migration
  def self.up
    change_table :carichi do |t|
      t.timestamps
    end

    change_table :scarichi do |t|
      t.timestamps
    end
  end

  def self.down

  end
end

