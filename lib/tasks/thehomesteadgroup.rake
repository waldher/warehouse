require 'csv'
require 'open-uri'
require 'scrape_utils'

namespace :thehomesteadgroup do
  desc "Import listing"
  task :import => :environment do
    lens = []
    customers = []
    for customer in Customer.all
      lens << customer.key.length
      customers << {:id => customer.id.to_s, :key => customer.key}
    end
    lens << "Customer".length
    max_len = lens.max
    seperators = "+----+#{(1..max_len+2).map{"-"}.join}+"
    puts seperators
    puts "| ID | #{"Customer".ljust(max_len, ' ')} |"
    puts seperators
    for customer in customers
      puts "| #{customer[:id].ljust(2, ' ')} | #{customer[:key].ljust(max_len, ' ')} |"
    end
    puts seperators
    print "Enter customer id :"
    customer_id = STDIN.gets.strip.to_i

    lens = []
    sublocations = []
    for sublocation in Sublocation.all
      lens << sublocation.name.length
      sublocations << {:id => sublocation.id.to_s, :name => sublocation.name}
    end
    lens << "Sublocation".length
    max_len = lens.max
    seperators = "+----+#{(1..max_len+2).map{"-"}.join}+"
    puts seperators
    puts "| ID | #{"Sublocation".ljust(max_len, ' ')} |"
    puts seperators
    for sublocation in sublocations
      puts "| #{sublocation[:id].ljust(2, ' ')} | #{sublocation[:name].ljust(max_len, ' ')} |"
    end
    puts seperators
    print "Enter sublocation id :"
    sublocation_id = STDIN.gets.strip.to_i

    listing_ids = []
    fp = open("http://www.thehomesteadgroup.com/uploads/photos/Craigslist_Export.csv")
    CSV.foreach(fp) do |row|
      puts ",-------------------"
      foreign_hash = row[0] + row[3] + row[22]

      listing = Listing.find_by_customer_id_and_sublocation_id_and_foreign_id(customer_id, sublocation_id, foreign_hash)
      if listing.nil?
        special_puts "Creating New Listing"
        listing = Listing.new
        listing.customer_id = customer_id
        listing.sublocation_id = sublocation_id
        listing.foreign_id = foreign_hash
      else
        special_puts "Old Listing Found"
      end

      status = (row[2] == "Active") ? true : false
      listing.foreign_active = status
      listing.infos["ad_apt_id"] = row[0] # Int
      listing.infos["ad_address"] = row[3] # String
      listing.infos["ad_price"] = row[4] # Int
      listing.infos["ad_description"] = row[6] # String
      listing.infos["ad_bedrooms"] = row[7] # Int
      listing.infos["ad_bathrooms"] = row[8] # Int
      listing.infos["ad_parkng"] = row[11] # 0/1
      listing.infos["ad_pets"] = row[12] # String
      listing.infos["ad_rental_terms"] = row[12] # (So the poster_clients knows to post as cats / dogs friendly)
      listing.infos["ad_fireplace"] = row[13] # yes/no
      listing.infos["ad_balcony"] = row[14] # y/n
      listing.infos["ad_flooring"] = row[15] # String
      listing.infos["ad_dishwasher"] = row[16] # y/n
      listing.infos["ad_laundry"] = row[17] # String
      listing.infos["ad_type"] = row[18] # String
      listing.infos["ad_heat"] = row[19] # yes/no
      listing.infos["ad_ac"] = row[20] # yes/no
      listing.infos["ad_square_footage"] = row[21] # Int
      listing.infos["ad_location"] = row[22] # String (CL Location String)
      listing.infos["ad_available"] = row[23] # Available: mm/dd/yyyy (or now)
      titles = []
      (0..2).each{
        title = ListingTitle.generate(listing)
        if !title.nil? and !title.empty? and title.length > 20
          special_puts "New title generated: #{c(pink)}#{title}#{ec}"
          titles << title
        end
      }                            
      listing.infos["ad_title"] = titles if !titles.nil? and !titles.empty?

      image_url_strings = []
      for image_url_string in row[25..30]
        next if image_url_string.nil? or image_url_string.empty?
        image_url_strings << image_url_string
      end
      listing.foreign_active = false if image_url_strings.count == 0

      if listing.changed? or true # (true because we are creating new titles) 
        special_puts "Listing Updated/Created"
        listing.save
      end
      listing_ids << listing.id
      
      load_images(listing, image_url_strings) if image_url_strings.count > 0

      special_puts "Finished"
      puts "`-------------------"
    end
    activate_new_listings(customer_id, listing_ids)
    deactivate_old_listings(customer_id, listing_ids)
    puts "Successfully Imported Data"
    fp.close
  end
end
