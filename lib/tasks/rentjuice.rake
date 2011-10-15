require 'rentjuicer'

namespace :rentjuicer do
  desc "Import from RentJuicer"
  task :import => :environment do
    @rentjuicer = Rentjuicer::Client.new('3b97f4ec544152dd3a79ca0c19b32aab')
    puts "Rentjuice Client Created"

    @listings = Rentjuicer::Listings.new(@rentjuicer)
    puts "Rentjuice Listings Object Created"

    leadadvo_id = Customer.where("key = ?","kangarent").last.id
    puts "Identified Kangarent's Leadadvo ID (#{leadadvo_id})"

    rentjuice_listings = @listings.find_all
    puts "Downloaded Kangarent's Rentjuce listings (#{rentjuice_listings.count} in total)"

    #These keys hold the foregin keys.
    #This way we don't have to iterate through all listings for every listing.
    key_map = {}
    #These keys will be deleted when an listing is active.
    #That way at the end of the import we know what listings to disable
    to_deactivate = {}
    Listing.where("customer_id = ?", leadadvo_id).each{ |listing|
      key_map[listing.infos[:ad_foreign_id]] = listing.id
      to_deactivate[listing.id] = listing
    }
    puts "Constructed foreign to local id/key map."

    rentjuice_listings.each { |rentjuicer|
      
      puts "RentJuice has #{rentjuice_listings.count()} listings for customer."

      active = 0
      total = Listing.where("customer_id = ?", leadadvo_id).each{|l| active += 1 if l.active }.count()
      puts "Leadadvo has #{total} listings for customer."
      puts "Leadadvo has #{active} active listings for customer."

      new = true
      if key_map[rentjuicer.id.to_s]
          puts "Old Listing Found"
          listing = Listing.find(key_map[rentjuicer.id.to_s])
          new = false
      end
      if new
        puts "#{c(green)}New Listing Found, Rentjuce ID #{rentjuicer.id}#{ec}"
        listing = Listing.new

        listing.customer_id = leadadvo_id
        listing.infos[:ad_foreign_id] = rentjuicer.id.to_s

        #Stuff that should never change (Trying to help skipped listings run faster.)
        listing.infos[:ad_city] = rentjuicer.city || ""
        listing.infos[:ad_state] = rentjuicer.state || ""
        listing.infos[:ad_zip_code] = rentjuicer.zip_code || ""
        
        address = "#{rentjuicer.street_number} #{rentjuicer.street}, #{rentjuicer.city}, #{rentjuicer.state} #{rentjuicer.zip_code}"
        address.gsub!(/'/,' ')
        puts "Address: #{address}"

        done = false
        while !done
          begin

            json_string = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(address)}&sensor=true").read
            parsed_json = ActiveSupport::JSON.decode(json_string)
            location = parsed_json["results"].first["address_components"][2]["short_name"]
            #listing.infos[:ad_location] = location
            puts "Detected location: #{location}"
            done = true
            sleep(0.1)
          rescue => e
            puts "Error: #{c(red)}#{e.inspect}#{ec}"
            sleep(0.5)
          end
        end
      end
  
      puts "Deleting from deactivation map"
      to_deactivate.delete(listing.id)
      listing.active = true

      puts "Updating/ adding listing infos"
      listing.infos[:ad_title] = rentjuicer.title || ""
      listing.infos[:ad_description] = rentjuicer.description || ""
      listing.infos[:ad_address] = rentjuicer.address || ""
      listing.infos[:ad_price] = rentjuicer.rent || ""
      listing.infos[:ad_bedrooms] = rentjuicer.bedrooms || ""
      listing.infos[:ad_bathrooms] = rentjuicer.bathrooms || ""
      listing.infos[:ad_square_footage] = rentjuicer.square_footage || ""
      listing.infos[:ad_property_type] = rentjuicer.property_type || ""
      listing.infos[:ad_floor_number] = rentjuicer.floor_number || ""
      listing.infos[:ad_agent_name] = rentjuicer.agent_name || ""
      listing.infos[:ad_agent_email] = rentjuicer.agent_email || ""
      listing.infos[:ad_agent_phone] = rentjuicer.agent_phone || ""

      listing.infos[:ad_keywords] = (rentjuicer.features * ", ") || ""
      listing.infos[:ad_neighborhoods] = (rentjuicer.neighborhoods * ", ") || ""
      listing.infos[:ad_rental_terms] = (rentjuicer.rental_terms * ", ") || ""

      listing.infos[:ad_latitude] = rentjuicer.latitude || ""
      listing.infos[:ad_longitude] = rentjuicer.longitude || ""

      #If there are no images we don't want to save the listing.
      if rentjuicer.sorted_photos or rentjuicer.status != "active"
        listing.active = false
      end
      puts "Saving Listing"
      listing.save
      puts "Adding to key_map"
      key_map[rentjuicer.id.to_s] = listing.id

      #Assumption being, images never change.
      if new
        puts "New add Import Images"
        for image in rentjuicer.sorted_photos
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

    puts "Found #{to_deactivate.count} listing(s) that need(s) to be deactivated."
    for listing_id, listing in to_deactivate do
      puts "Disabling listing with Leadadvo ID #{listing_id}"
      listing.active = false
      listing.save
    end
  end
end

def gray; 8; end 
def green; 2; end 
def red; 1; end 
def c( fg, bg = nil ); "#{fg ? "\x1b[38;5;#{fg}m" : ''}#{bg ? "\x1b[48;5;#{bg}m" : ''}" end 
def ec; "\x1b[0m"; end 
