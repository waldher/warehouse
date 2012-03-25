# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120325212311) do

  create_table "admins", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admins", ["email"], :name => "index_admins_on_email", :unique => true
  add_index "admins", ["reset_password_token"], :name => "index_admins_on_reset_password_token", :unique => true

  create_table "capabilities", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "capabilities", ["name"], :name => "index_capabilities_on_name", :unique => true

  create_table "capabilities_customers", :id => false, :force => true do |t|
    t.integer "capability_id"
    t.integer "customer_id"
  end

  create_table "customer_infos", :force => true do |t|
    t.integer "customer_id"
    t.integer "version",     :default => 0, :null => false
    t.string  "key"
    t.string  "value"
  end

  add_index "customer_infos", ["customer_id"], :name => "index_customer_infos_on_customer_id"

  create_table "customers", :force => true do |t|
    t.string   "email_address"
    t.string   "hashed_password"
    t.string   "salt"
    t.string   "key"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "craigslist_type", :default => "apa", :null => false
    t.string   "setup_nonce"
    t.integer  "location_id"
    t.integer  "sublocation_id"
    t.string   "import_type"
  end

  add_index "customers", ["key"], :name => "index_customers_on_key"
  add_index "customers", ["role_id"], :name => "index_customers_on_role_id"
  add_index "customers", ["setup_nonce"], :name => "index_customers_on_setup_nonce", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "directories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "directories", ["name"], :name => "index_directories_on_name", :unique => true

  create_table "directory_files", :force => true do |t|
    t.string   "ip_address"
    t.integer  "directory_id"
    t.string   "filename"
    t.boolean  "click"
    t.text     "raw"
    t.datetime "requested_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "directory_files", ["click"], :name => "index_directory_files_on_click"
  add_index "directory_files", ["directory_id"], :name => "index_directory_files_on_directory_id"
  add_index "directory_files", ["requested_at"], :name => "index_directory_files_on_requested_at"

  create_table "keywords", :force => true do |t|
    t.string   "keyword"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "ignore",     :default => false
  end

  create_table "listing_images", :force => true do |t|
    t.integer  "listing_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "threading",          :default => 0, :null => false
    t.string   "complete_image_url"
  end

  create_table "listing_infos", :force => true do |t|
    t.integer  "listing_id",                :null => false
    t.string   "key",                       :null => false
    t.text     "value",      :limit => 255, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "listing_infos", ["listing_id", "key"], :name => "index_listing_infos_on_listing_id_and_key", :unique => true

  create_table "listings", :force => true do |t|
    t.integer  "customer_id",                        :null => false
    t.boolean  "manual_enabled",  :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "foreign_active",  :default => false, :null => false
    t.string   "foreign_id"
    t.integer  "location_id"
    t.integer  "sublocation_id"
    t.integer  "neighborhood_id"
  end

  create_table "locations", :force => true do |t|
    t.string  "name",    :default => "",    :null => false
    t.boolean "enabled", :default => false, :null => false
    t.string  "url",                        :null => false
  end

  add_index "locations", ["name"], :name => "index_locations_on_name", :unique => true
  add_index "locations", ["url"], :name => "index_locations_on_url", :unique => true

  create_table "log_files", :force => true do |t|
    t.string   "filename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "log_files", ["filename"], :name => "index_log_files_on_filename", :unique => true

  create_table "neighborhoods", :force => true do |t|
    t.integer  "sublocation_id", :null => false
    t.string   "name",           :null => false
    t.integer  "craigslist_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "real_estate_images", :force => true do |t|
    t.integer  "real_estate_id",     :null => false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "real_estates", :force => true do |t|
    t.integer  "realtor_id",                        :null => false
    t.text     "ad_title",                          :null => false
    t.text     "ad_description",                    :null => false
    t.integer  "bedrooms"
    t.integer  "price"
    t.boolean  "cats",           :default => false, :null => false
    t.boolean  "dogs",           :default => false, :null => false
    t.boolean  "active",         :default => true,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ad_location"
    t.string   "ad_keywords",    :default => "",    :null => false
  end

  create_table "scraped_links", :force => true do |t|
    t.string  "url"
    t.boolean "done"
  end

  add_index "scraped_links", ["url", "done"], :name => "index_scraped_links_on_url_and_done", :unique => true

  create_table "sublocations", :force => true do |t|
    t.string  "name",        :null => false
    t.integer "location_id"
    t.string  "url",         :null => false
  end

  add_index "sublocations", ["location_id", "name"], :name => "index_sublocations_on_location_id_and_name", :unique => true
  add_index "sublocations", ["location_id", "url"], :name => "index_sublocations_on_location_id_and_url", :unique => true
  add_index "sublocations", ["location_id"], :name => "index_sublocations_on_location_id"

end
