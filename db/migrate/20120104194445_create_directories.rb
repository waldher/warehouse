class CreateDirectories < ActiveRecord::Migration
  def self.up
    create_table :directories do |t|
      t.string :name

      t.timestamps
    end
    add_index(:directories, :name, :unique => true)
  end

  def self.down
    drop_table :directories
  end
end
