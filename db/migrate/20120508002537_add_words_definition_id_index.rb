class AddWordsDefinitionIdIndex < ActiveRecord::Migration
  def self.up
    add_index :words, :definition_id
  end

  def self.down
  end
end
