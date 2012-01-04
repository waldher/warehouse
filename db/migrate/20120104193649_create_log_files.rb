class CreateLogFiles < ActiveRecord::Migration
  def self.up
    create_table :log_files do |t|
      t.string :filename

      t.timestamps
    end
    add_index(:log_files, :filename, :unique => true)
  end

  def self.down
    drop_table :log_files
  end
end
