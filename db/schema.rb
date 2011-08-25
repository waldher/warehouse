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

ActiveRecord::Schema.define(:version => 20110825151738) do

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

  create_table "dealer_infos", :force => true do |t|
    t.integer  "dealer_id",              :default => 1,                     :null => false
    t.string   "name"
    t.text     "description"
    t.text     "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone"
    t.string   "email"
    t.string   "display_website"
    t.string   "time_zone"
    t.string   "craigslist_location"
    t.string   "craigslist_sublocation"
    t.string   "location_string"
    t.time     "start_time",             :default => '2000-01-01 09:00:00', :null => false
    t.time     "end_time",               :default => '2000-01-01 09:00:00', :null => false
    t.boolean  "hide_price"
    t.boolean  "hide_mileage"
    t.boolean  "metric"
    t.boolean  "use_landing_pages"
    t.text     "destination_website"
    t.string   "crm_email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dealers", :force => true do |t|
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
    t.string   "dealer_key"
  end

  add_index "dealers", ["dealer_key"], :name => "index_dealers_on_dealer_key", :unique => true
  add_index "dealers", ["email"], :name => "index_dealers_on_email", :unique => true
  add_index "dealers", ["reset_password_token"], :name => "index_dealers_on_reset_password_token", :unique => true

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

  create_table "realtors", :force => true do |t|
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
    t.string   "name",                                                  :null => false
    t.string   "realtor_key",                                           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "realtors", ["email"], :name => "index_realtors_on_email", :unique => true
  add_index "realtors", ["realtor_key"], :name => "index_realtors_on_realtor_key", :unique => true
  add_index "realtors", ["reset_password_token"], :name => "index_realtors_on_reset_password_token", :unique => true

end
