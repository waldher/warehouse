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

ActiveRecord::Schema.define(:version => 20111009171730) do

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
  end

  add_index "customers", ["key"], :name => "index_customers_on_key"
  add_index "customers", ["role_id"], :name => "index_customers_on_role_id"
  add_index "customers", ["setup_nonce"], :name => "index_customers_on_setup_nonce", :unique => true

  create_table "listing_images", :force => true do |t|
    t.integer  "listing_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "threading",          :default => 0, :null => false
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
    t.integer  "customer_id",                   :null => false
    t.boolean  "active",      :default => true, :null => false
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

end
