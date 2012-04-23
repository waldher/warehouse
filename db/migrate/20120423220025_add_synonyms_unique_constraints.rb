class AddSynonymsUniqueConstraints < ActiveRecord::Migration
  def self.up
    remove_index :synonyms, [:wordnet_number, :category]

    add_index :synonyms, [:wordnet_number, :category]
  end

  def self.down
  end
end
