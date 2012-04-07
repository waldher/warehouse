class CreateWords < ActiveRecord::Migration
  def self.up
    create_table :words do |t|
      t.integer :definition_id, :null => false, :references => :definitions
      t.string :spelling, :null => false
      t.boolean :ignore, :null => false, :default => false
      t.integer :sense, :null => false

      t.timestamps
    end

    add_index :words, :spelling
  end

  def self.down
    drop_table :words
  end
end
