require 'uri'
require 'rentjuicer'

def in_memory_file(data, pathname)
  #load up some data
  file = StringIO.new(data)

  #tell the class that it knows about a "name" property,
  #and assign the filename to it
  file.class.class_eval { attr_accessor :original_filename } 
  file.original_filename = pathname 
  
  file.class.class_eval { attr_accessor :content_type } 
  file.content_type = "image/#{pathname.split(".").last }"

  #FPDF uses the rindex and [] funtions on the "filename",
  #so we'll make our in-memory file object act like a filename
  #with respect to these functions:
  def file.rindex arg 
    name.rindex arg 
  end 

  #this same pattern could be used to add other metadata
  #to the file (e.g., creation time)
  def file.[] arg 
    name[arg] 
  end  

  #change open so that it follows the formal behavior
  #of the original (call a block with data, return
  #the file-like object, etc.) but alter it so that
  #it doesn't create a new instance and can be
  #called multiple times (rewind)
  def file.open(*mode, &block) 
    self.rewind 
    block.call(self) if block 
    return self 
  end 

  return file 
end

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
    casa_neighborhoods = ["Boca Raton", "Deerfield Beach", "Delray Beach", "Highland Beach", "Hillsboro Beach", "Parkland"]

    kanga = [{:min_rent => 850, :has_photos => 1, :include_mls => 1}]
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
    },

    {:name => 'casabellaboca',
    :rj_id => 'e18a66e3f23c9d65e53072fcf0560542',
    :hoods => {:neighborhoods => casa_neighborhoods},
    :filter => [{:include_mls => 1}],
    :email => {:agent => "john@casabellaboca.com"}
    }
    ]

    connections = {}
  
    for customer in customers
      puts "============================================="

      @rentjuicer = Rentjuicer::Client.new(customer[:rj_id])
      puts "Rentjuice Client Created"

      @listings = Rentjuicer::Listings.new(@rentjuicer)
      puts "Rentjuice Listings Object Created"
 
      start=Time.now
      rentjuice_listings = []
      for condition in customer[:filter]
        rentjuice_listings += @listings.find_all(condition.merge(customer[:hoods]).merge({:limit => 50}))
        puts "Downloaded #{customer[:name]}'s Rentjuce listings, #{rentjuice_listings.count} in total"
      end
      puts "Took #{Time.now-start}"

      leadadvo_id = Customer.where("key = ?",customer[:name]).last.id
      puts "Identified #{customer[:name]}'s Leadadvo ID as #{leadadvo_id}"

      #These keys hold the foregin keys.
      #This way we don't have to iterate through all listings for every rentjuice unit.
      key_map = {}
      #These keys will be deleted when an listing is active.
      #That way at the end of the import we know what listings to disable
      to_deactivate = {}
      Listing.where("customer_id = ?", leadadvo_id).each{ |listing|
        key_map[listing.infos[:ad_foreign_id]] = listing.id
        to_deactivate[listing.id] = listing
      }
      puts "Constructed foreign to local id/key map."

      index = 0
      max = rentjuice_listings.count
      rentjuice_listings.each { |rentjuicer|
        puts "Now working on listing #{index += 1} of #{max} for #{customer[:name]}"

        save = false

        new = true
        if key_map[rentjuicer.id.to_s]
            puts "Old Listing Found"
            listing = Listing.find(key_map[rentjuicer.id.to_s])
            new = false
        end
        if new
          save = true
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
 
          listing.infos[:ad_latitude] = rentjuicer.latitude || ""
          listing.infos[:ad_longitude] = rentjuicer.longitude || ""
      
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
              puts "#{c(red)}Location Error: #{e.inspect}, trying again.#{ec}"
              #If for some reason the minimum is surpased. Make sure to wait a long time before trying again.
              #(I have seen it border on black listing requests.)
              sleep(0.5)
            end
          end
        end
 
        #listing.infos[:ad_agent_name] = rentjuicer.agent_name || ""
        #listing.infos[:ad_agent_email] = rentjuicer.agent_email || ""
        #listing.infos[:ad_agent_phone] = rentjuicer.agent_phone || ""
    
        puts "Updating/ adding listing infos"

        #---Title
        if !rentjuicer.title.nil? and !rentjuicer.title.empty?
          if listing.infos[:ad_title] != rentjuicer.title
            puts "Title Changed. Was '#{listing.infos[:ad_title]}' is now '#{(rentjuicer.title || "")}'."
            listing.infos[:ad_title] = (rentjuicer.title || "")
            listing.active = true
            save = true
          end
        #If new data not viable
        else
          if !listing.active
            if listing.infos[:ad_title] and !listing.infos[:ad_title].empty?
              listing.active = true
              save = true
            end
          else
            if listing.infos[:ad_title].nil? or listing.infos[:ad_title].empty?
              listing.active = false
              save = true
            end
          end
        end

        #---Description
        if listing.infos[:ad_description] != (rentjuicer.description || "")
          puts "Description Changed"
          save = true
          listing.infos[:ad_description] = (rentjuicer.description || "")
        end

        #---Price
        if listing.infos[:ad_price] != (rentjuicer.rent.to_s || "")
          puts "Price Changed. Was '#{listing.infos[:ad_price]}'(nil? #{listing.infos[:ad_price].nil?}) is now '#{(rentjuicer.rent.to_s || "")}'(nil? #{rentjuicer.rent.to_s.nil?})."
          save = true
          listing.infos[:ad_price] = (rentjuicer.rent.to_s || "")
        end
       
        #---Keywords
        if listing.infos[:ad_keywords] != ((rentjuicer.features * ", ") || "")
          puts "Keywords Changed"
          save = true
          listing.infos[:ad_keywords] = ((rentjuicer.features * ", ") || "")
        end
        
        #---Neighborhoods
        if listing.infos[:ad_neighborhoods] != ((rentjuicer.neighborhoods * ", ") || "")
          puts "Neighborhoods Changed"
          save = true
          listing.infos[:ad_neighborhoods] = ((rentjuicer.neighborhoods * ", ") || "")
        end

        #---Rental Terms
        if listing.infos[:ad_rental_terms] != ((rentjuicer.rental_terms * ", ") || "")
          puts "Rental Terms Changed"
          save = true
          listing.infos[:ad_rental_terms] = ((rentjuicer.rental_terms * ", ") || "")
        end

        new_foreign_active = true
        #If there are no images we don't want to save the listing.
        if !rentjuicer.sorted_photos
          puts "Disabled due to photos"
          new_foreign_active = false
          save = true
        elsif rentjuicer.status != "active"
          puts "Disabled due to status"
          new_foreign_active = false
          save = true
        end

        if new_foreign_active != listing.foreign_active
          puts "Foreign Active Sataus Changed from #{listing.foreign_active} to #{new_foreign_active}"
          listing.foreign_active = new_foreign_active
          save = true
        end
    
        if save
          puts "Saving Listing"
          listing.save
        end

        puts "Deleting from deactivation map"
        to_deactivate.delete(listing.id)

        puts "Updating key_map"
        key_map[rentjuicer.id.to_s] = listing.id

        #Assumption being, images never change.
        if new and !rentjuicer.sorted_photos.empty?
          puts "New Ad, Import Images #{rentjuicer.sorted_photos}"
          for image in rentjuicer.sorted_photos
            uploaded = 5
            while uploaded > 0
              begin
                image_uri = ""
                if !image.fullsize.nil?
                  image_uri = image.fullsize
                elsif !image.original.nil?
                  image_uri = image.original
                else
                  break
                end
                  
                http = nil
                urisplit = URI.split(image_uri).reject{|i| i.nil?}
                domain = urisplit[1]
                path = urisplit[2..-1] * "/"
                if connections.has_key?(domain)
                  http = connections[domain]
                else
                  http = Net::HTTP.start(domain)
                  connections[domain] = http
                end
                resp = http.get(path)
                image_file = in_memory_file(resp.body, urisplit.last.split("/").last)

                ListingImage.create(:listing_id => listing.id, :image => image_file, :threading => image.sort_order)
                uploaded = 0
                puts "Imported Image: #{image_uri}"
              rescue => e
                puts "#{c(red)}Attempt: #{uploaded}, #{e.inspect}#{ec}"
                uploaded -= 1
                if uploaded == 0
                  return
                end
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

      puts "Found #{to_deactivate.count} listing(s) that may need to be deactivated."
      for listing_id, listing in to_deactivate do
        if listing.foreign_active
          puts "Disabling listing with Leadadvo ID #{listing_id}"
          listing.foreign_active = false
          listing.save
        end
      end
      puts "Finished deactivation"
    end
  end
end

def gray; 8; end 
def green; 2; end 
def red; 1; end 
def c( fg, bg = nil ); "#{fg ? "\x1b[38;5;#{fg}m" : ''}#{bg ? "\x1b[48;5;#{bg}m" : ''}" end 
def ec; "\x1b[0m"; end 
