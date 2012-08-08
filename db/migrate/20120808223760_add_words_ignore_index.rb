class AddWordsIgnoreIndex < ActiveRecord::Migration
  def self.up
    add_index :words, :ignore
  end
end
