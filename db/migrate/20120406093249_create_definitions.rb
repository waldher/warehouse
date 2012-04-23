class CreateDefinitions < ActiveRecord::Migration
  def self.up
    create_table :definitions do |t|
      t.integer :wordnet_number, :null => false
      t.string :category, :null => false
      t.text :text_definition

      t.timestamps
    end

    add_index :definitions, :wordnet_number, :unique => true

    create_table :synonyms do |t|
      t.integer :definition_id, :null => false, :references => :definitions
      t.integer :wordnet_number, :null => false
      t.string :symbol, :null => false
    end

    add_index :synonyms, :definition_id
    add_index :synonyms, [:definition_id, :wordnet_number], :unique => true
  end

  def self.down
    drop_table :synonyms
    drop_table :definitions
  end
end
