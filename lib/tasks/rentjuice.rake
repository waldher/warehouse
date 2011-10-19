require 'rentjuicer'

namespace :rentjuicer do
  desc "Import from RentJuicer"
  task :import => :environment do
    @running = true
    Kernel.trap("INT"){
      @running = false
      print " *****************************\n"
      print " * Gracefully killing import *\n"
      print " *****************************\n"
    }

    kanga_neighborhoods = ["Boynton Beach", "Boca Raton", "Coconut Creek", "Coral Springs", "Deerfield Beach", "Delray Beach", "Jupiter", "Lake Park", "Lake Worth", "Palm Beach", "Palm Beach Gardens", "North Palm Beach", "Royal Palm Beach", "Stuart", "Tequesta", "Wellington", "West Palm Beach"] * ", "
    elizabeth_neighborhoods = ["Miami Beach", "Surfside", "Brickell"] * ", " 
    paola_neighborhoods = ["Brickell", "Coral Gables", "Coconut Grove", "Downtown"] * ", "
    ronda_neighborhoods = ["Miami Beach", "North Beach", "Bay Harbour"] * ", "

    kanga = [{:min_rent => 850, :neighborhoods => kanga_neighborhoods, :has_photos => 1, :include_mls => 1}]
    maf = [
    {:min_beds => 1, :max_beds => 1, :min_rent => 1800, :max_rent => 2500, :has_photos => 1, :include_mls => 1},
    {:min_beds => 2, :max_beds => 2, :min_rent => 2000, :max_rent => 4000, :has_photos => 1, :include_mls => 1}
    ]

    customers = [
    {:name => 'maf_elizabeth',
    :rj_id => '868f2445f9f09786e35f8a1b9356a417',
    :hoods => {:neighborhoods => elizabeth_neighborhoods},
    :filter => maf,
    :email => {:agent => "elizabeth@miamiapartmentfinders.com"}
    },

    {:name => 'maf_ronda',
    :rj_id => '868f2445f9f09786e35f8a1b9356a417',
    :hoods => {:neighborhoods => ronda_neighborhoods},
    :filter => maf,
    :email => {:agent => "ronda@miamiapartmentfinders.com"}
    },

    {:name => 'maf_paola',
    :rj_id => '868f2445f9f09786e35f8a1b9356a417',
    :hoods => {:neighborhoods => paola_neighborhoods},
    :filter => maf,
    :email => {:agent => "paola@miamiapartmentfinders.com"}
    },

    {:name => 'kangarent',
    :rj_id => '3b97f4ec544152dd3a79ca0c19b32aab',
    :hoods => {:neighborhoods => kanga_neighborhoods},
    :filter => kanga,
    :email => {:agent => "leads@kangarent.com"}
    }
    ]
  
    for customer in customers

      @rentjuicer = Rentjuicer::Client.new(customer[:rj_id])
      puts "Rentjuice Client Created"

      @listings = Rentjuicer::Listings.new(@rentjuicer)
      puts "Rentjuice Listings Object Created"
 
      start=Time.now
      rentjuice_listings = []
      for condition in customer[:filter]
        rentjuice_listings += @listings.find_all(condition.merge(customer[:hoods]).merge({:limit => 50}))
        puts "Downloaded Kangarent's Rentjuce listings, #{rentjuice_listings.count} in total"
      end
      puts "Took #{Time.now-start}"

      leadadvo_id = Customer.where("key = ?",customer[:name]).last.id
      puts "Identified Kangarent's Leadadvo ID as #{leadadvo_id}"

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
          listing.infos[:ad_address] = rentjuicer.address || ""
   
          listing.infos[:ad_bedrooms] = rentjuicer.bedrooms || ""
          listing.infos[:ad_bathrooms] = rentjuicer.bathrooms || ""
          listing.infos[:ad_square_footage] = rentjuicer.square_footage || ""
          listing.infos[:ad_property_type] = rentjuicer.property_type || ""
          listing.infos[:ad_floor_number] = rentjuicer.floor_number || ""
       
          address = "#{rentjuicer.street_number} #{rentjuicer.street}, #{rentjuicer.city}, #{rentjuicer.state} #{rentjuicer.zip_code}"
          address.gsub!(/'/,' ')
          puts "Address: #{address}"

          done = false
          while !done
            begin
              json_string = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(address)}&sensor=true").read
              parsed_json = ActiveSupport::JSON.decode(json_string)
              location = parsed_json["results"].first["address_components"][2]["short_name"]
              listing.infos[:ad_location] = location
              puts "Detected location: #{location}"
              done = true
              #0.1 is minimum but, with all the other code the total time between requests should be >> 0.1
              sleep(0.1)
            rescue => e
              puts "Error: #{c(red)}#{e.inspect}#{ec}"
              #If for some reason the minimum is surpased. Make sure to wait a long time before trying again.
              #(I have seen it border on black listing requests.)
              sleep(0.5)
            end
          end
        end
    
        puts "Updating/ adding listing infos"

        if !listing.infos[:ad_title].nil? and listing.infos[:ad_title].empty?
          listing.infos[:ad_title] = rentjuicer.title || ""
        end
        if listing.infos[:ad_title].nil? or listing.infos[:ad_title].emtpy?
          listing.active = false
        end
        listing.infos[:ad_description] = rentjuicer.description || ""
        listing.infos[:ad_price] = rentjuicer.rent || ""
        listing.infos[:ad_agent_name] = rentjuicer.agent_name || ""
        listing.infos[:ad_agent_email] = rentjuicer.agent_email || ""
        listing.infos[:ad_agent_phone] = rentjuicer.agent_phone || ""

        listing.infos[:ad_keywords] = (rentjuicer.features * ", ") || ""
        listing.infos[:ad_neighborhoods] = (rentjuicer.neighborhoods * ", ") || ""
        listing.infos[:ad_rental_terms] = (rentjuicer.rental_terms * ", ") || ""

        listing.infos[:ad_latitude] = rentjuicer.latitude || ""
        listing.infos[:ad_longitude] = rentjuicer.longitude || ""

        puts "Deleting from deactivation map"
        to_deactivate.delete(listing.id)
        listing.foreign_active = true

        #If there are no images we don't want to save the listing.
        if !rentjuicer.sorted_photos
          puts "Disabled due to photos"
          listing.foreign_active = false
        elsif rentjuicer.status != "active"
          puts "Disabled due to status"
          listing.foreign_active = false
        elsif !rentjuicer.title or rentjuicer.title.empty?
          puts "Disabled due to no title"
          listing.foreign_active = false
        end

        puts "Saving Listing"
        listing.save

        puts "Updating key_map"
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
        if !@running
          return
        end
      }

      puts "Found #{to_deactivate.count} listing(s) that need(s) to be deactivated."
      for listing_id, listing in to_deactivate do
        puts "Disabling listing with Leadadvo ID #{listing_id}"
        listing.foreign_active = false
        listing.save
      end
    end
  end
end

def gray; 8; end 
def green; 2; end 
def red; 1; end 
def c( fg, bg = nil ); "#{fg ? "\x1b[38;5;#{fg}m" : ''}#{bg ? "\x1b[48;5;#{bg}m" : ''}" end 
def ec; "\x1b[0m"; end 
