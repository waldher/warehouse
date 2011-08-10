class AddDealersDealerKey < ActiveRecord::Migration
  def self.up
    add_column :dealers, :dealer_key, :string

    add_index :dealers, :dealer_key, :unique => true
  end

  def self.down

    remove_column :dealers, :dealer_key
  end
end
