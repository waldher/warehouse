class AddFieldsToCustomerInfo < ActiveRecord::Migration
  def self.up
    add_column :customer_infos, :disable_new_titles, :boolean
    add_column :customer_infos, :active_new, :boolean
    add_column :customer_infos, :deactivate_old, :boolean
    # Data will recieve a JSON text.
    add_column :customer_infos, :data, :string
  end

  def self.down
    remove_column :customer_infos, :disable_new_titles
    remove_column :customer_infos, :active_new
    remove_column :customer_infos, :deactivate_old
    remove_column :customer_infos, :data
  end
end
