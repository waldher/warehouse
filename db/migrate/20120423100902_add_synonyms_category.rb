class AddSynonymsCategory < ActiveRecord::Migration
  def self.up
    remove_index :definitions, :wordnet_number
    add_index :definitions, [:wordnet_number, :category], :unique => true

    add_column :synonyms, :category, :string
    add_index :synonyms, [:wordnet_number, :category], :unique => true
  end

  def self.down
    remove_index :definitions, [:wordnet_number, :category]
    add_index :definitions, :wordnet_number, :unique => true

    remove_column :synonyms, :category
  end
end
