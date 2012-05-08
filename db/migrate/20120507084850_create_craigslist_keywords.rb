class CreateCraigslistKeywords < ActiveRecord::Migration
  def self.up
    create_table :craigslist_keywords do |t|
      t.string :spelling, :null => false
      t.integer :frequency, :null => false

      t.timestamps
    end

    add_index :craigslist_keywords, :spelling, :unique => true
  end

  def self.down
    drop_table :craigslist_keywords
  end
end
