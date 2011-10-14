require 'rentjuicer'

namespace :rentjuicer do
  desc "Import from RentJuicer"
  task :import => :environment do
    @rentjuicer = Rentjuicer::Client.new('3b97f4ec544152dd3a79ca0c19b32aab')
    puts "Rentjuice Client Created"

    @listings = Rentjuicer::Listings.new(@rentjuicer)
    puts "Rentjuice Listings Object Created"

    customer_id = Customer.where("key = ?","kangarent").last.id
    puts "Identified Kangarent's Leadadvo ID (#{customer_id})"

    customer_listings = @listings.find_all
    puts "Downloaded Kangarent's Rentjuce listings (#{customer_listings.count} in total)"

    key_map = {}
    Listing.where("customer_id = ?", customer_id).each{ |listing|
      key_map[listing.infos[:ad_foreign_id]] = listing.id
    }
    puts "Constructed foreign to local id/key map."

    customer_listings.each { |customer|

      old_listings = Listing.where("customer_id = ?", customer_id)
      puts "Identified Kangarent's Leadadvo listings (#{old_listings.count} in total)"

      new = true
      if key_map[customer.id.to_s]
          puts "Old Listing Found"
          listing = Listing.find(key_map[customer.id.to_s])
          new = false
      end
      if new
        puts "New Listing Found, Rentjuce ID #{customer.id}"
        listing = Listing.new

        listing.customer_id = customer_id
        listing.infos[:ad_foreign_id] = customer.id
      end
  
      listing.active = true
      listing.infos[:ad_title] = customer.title || ""
      listing.infos[:ad_description] = customer.description || ""
      listing.infos[:ad_address] = customer.address || ""
      listing.infos[:ad_price] = customer.rent || ""
      listing.infos[:ad_bedrooms] = customer.bedrooms || ""
      listing.infos[:ad_bathrooms] = customer.bathrooms || ""
      listing.infos[:ad_square_footage] = customer.square_footage || ""
      listing.infos[:ad_keywords] = (customer.features * ", ") || ""
      listing.infos[:ad_latitude] = customer.latitude || ""
      listing.infos[:ad_longitude] = customer.longitude || ""
      listing.infos[:ad_neighborhoods] = (customer.neighborhoods * ", ") || ""
      listing.infos[:ad_property_type] = customer.property_type || ""
      listing.infos[:ad_floor_number] = customer.floor_number || ""
      listing.infos[:ad_agent_name] = customer.agent_name || ""
      listing.infos[:ad_agent_email] = customer.agent_email || ""
      listing.infos[:ad_agent_phone] = customer.agent_phone || ""
      listing.infos[:ad_rental_terms] = (customer.rental_terms * ", ") || ""
      listing.infos[:ad_city] = customer.city || ""
      listing.infos[:ad_state] = customer.state || ""
      listing.infos[:ad_zip_code] = customer.zip_code || ""
      
      address = "#{customer.street_number} #{customer.street}, #{customer.city}, #{customer.state} #{customer.zip_code}" 
      json_string = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(address)}&sensor=true").read
      parsed_json = ActiveSupport::JSON.decode(json_string)
      location = parsed_json["results"].first["address_components"][2]["short_name"]
      listing.infos[:ad_location] = location
      puts "Detected location: #{location}"

      #If there are no images we don't want to save the listing.
      if customer.sorted_photos or customer.status != "active"
        listing.active = false
      end
      listing.save

      #Assumption being, images never change.
      if new
        puts "New add Import Images"
        for image in customer.sorted_photos
          uploaded = false
          while !uploaded
            begin
              ListingImage.create(:listing_id => listing.id, :image => open(image.fullsize), :threading => image.sort_order)
              uploaded = true
              puts "Imported Image: #{image.fullsize}"
            rescue => e
              puts "#{e.inspect}"
            end
          end
        end
      end

      puts "Created/Updated new Listing. Leadadvo ID #{listing.id}"
      puts "-----------------------------------------"
    }
  end
end
