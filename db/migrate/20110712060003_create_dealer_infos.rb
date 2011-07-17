class CreateDealerInfos < ActiveRecord::Migration
  def self.up
    create_table :dealer_infos do |t|
      t.integer :dealer_id
      t.string :name
      t.text :description
      t.text :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :phone
      t.string :email
      t.string :display_website
      t.string :time_zone
      t.string :craigslist_location
      t.string :craigslist_sublocation
      t.string :location_string
      t.time :start_time
      t.time :end_time
      t.boolean :hide_price
      t.boolean :hide_mileage
      t.boolean :metric
      t.boolean :use_landing_pages
      t.text :destination_website
      t.string :crm_email

      t.timestamps
    end
  end

  def self.down
    drop_table :dealer_infos
  end
end
