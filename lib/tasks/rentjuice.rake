require 'open-uri'
require 'rentjuicer'
require 'listing_title'

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

    kanga_neighborhoods = [
    "Boynton Beach", "Boca Raton", "Coconut Creek", "Coral Springs", "Deerfield Beach", 
    "Delray Beach", "Jupiter", "Lake Park", "Lake Worth", "Palm Beach", "Palm Beach Gardens", 
    "North Palm Beach", "Royal Palm Beach", "Stuart", "Tequesta", "Wellington", "West Palm Beach"] * ", "
    kanga = [{:min_rent => 850, :max_rent => 1500, :has_photos => 1, :include_mls => 1, :featured => 1}]

    casa_neighborhoods = ["Boca Raton", "Deerfield Beach", "Delray Beach", "Highland Beach", "Hillsboro Beach", "Parkland"] * ", "

    maf = [
    {:min_beds => 1, :max_beds => 1, :min_rent => 1800, :max_rent => 2500, :has_photos => 1, :include_mls => 1},
    {:min_beds => 2, :max_beds => 2, :min_rent => 2000, :max_rent => 5000, :has_photos => 1, :include_mls => 1}
    ]
    elizabeth_neighborhoods = ["Miami Beach", "Brickell", "Surfside"] * ", "
    paola_neighborhoods     = [               "Brickell", "Coral Gables", "Coconut Grove", "Downtown Miami"] * ", "
    ronda_neighborhoods     = ["Miami Beach", "North Beach", "Bay Harbour"] * ", "
    luis_neighborhoods      = [               "Brickell", "Midtown Miami"] * ", "

    customers = [
    {:name => 'maf_elizabeth',
    :rj_id => '868f2445f9f09786e35f8a1b9356a417',
    :hoods => {:neighborhoods => elizabeth_neighborhoods},
    :filter => maf,
    :email => {:agent => "elizabeth@miamiapartmentfinders.com"},
    :location => Location.find_by_url("miami"),
    :sublocation => Sublocation.find_by_url("mdc")
    },

    {:name => 'maf_ronda',
    :rj_id => '868f2445f9f09786e35f8a1b9356a417',
    :hoods => {:neighborhoods => ronda_neighborhoods},
    :filter => maf,
    :email => {:agent => "ronda@miamiapartmentfinders.com"},
    :location => Location.find_by_url("miami"),
    :sublocation => Sublocation.find_by_url("mdc")
    },

    {:name => 'maf_paola',
    :rj_id => '868f2445f9f09786e35f8a1b9356a417',
    :hoods => {:neighborhoods => paola_neighborhoods},
    :filter => maf,
    :email => {:agent => "paola@miamiapartmentfinders.com"},
    :location => Location.find_by_url("miami"),
    :sublocation => Sublocation.find_by_url("mdc")
    },

    {:name => 'maf_luis',
    :rj_id => '868f2445f9f09786e35f8a1b9356a417',
    :hoods => {:neighborhoods => luis_neighborhoods},
    :filter => maf,
    :email => {:agent => "luis@miamiapartmentfinders.com"},
    :location => Location.find_by_url("miami"),
    :sublocation => Sublocation.find_by_url("mdc")
    },

    {:name => 'kangarent',
    :rj_id => '3b97f4ec544152dd3a79ca0c19b32aab',
    :hoods => {:neighborhoods => kanga_neighborhoods},
    :filter => kanga,
    :email => {:agent => "leads@kangarent.com"},
    :location => Location.find_by_url("miami"),
    :sublocation => Sublocation.find_by_url("pbc")
    },

    {:name => 'casabellaboca',
    :rj_id => 'e18a66e3f23c9d65e53072fcf0560542',
    :hoods => {:neighborhoods => casa_neighborhoods},
    :filter => [{:include_mls => 1, :featured => 1}],
    :email => {:agent => "john@casabellaboca.com"},
    :location => Location.find_by_url("miami"),
    :sublocation => Sublocation.find_by_url("pbc")
    },

    {:name => 'sea_rea_test',
    :rj_id => 'e18a66e3f23c9d65e53072fcf0560542',
    :hoods => {:neighborhoods => casa_neighborhoods},
    :filter => [{:include_mls => 1, :featured => 1}],
    :email => {:agent => "brendan@leadadvo.com"},
    :location => Location.find_by_url("seattle"),
    :sublocation => Sublocation.find_by_url("see")
    },

    {:name => 'mdc_rea_test',
    :rj_id => 'e18a66e3f23c9d65e53072fcf0560542',
    :hoods => {:neighborhoods => casa_neighborhoods},
    :filter => [{:include_mls => 1, :featured => 1}],
    :email => {:agent => "brendan@leadadvo.com"},
    :location => Location.find_by_url("miami"),
    :sublocation => Sublocation.find_by_url("mdc")
    }
    ]

    @connections = {}
  
    for customer in customers.shuffle
      puts ",============================================="
      leadadvo_id = Customer.where("key = ?",customer[:name]).last.id
      puts "|Identified #{customer[:name]}'s Leadadvo ID as #{leadadvo_id}"

      find_dupe_ids(leadadvo_id)

      @rentjuicer = Rentjuicer::Client.new(customer[:rj_id])
      puts "|Rentjuice Client Created"
      @listings = Rentjuicer::Listings.new(@rentjuicer)
      puts "|Rentjuice Listings Object Created"
 
      rentjuice_listings = []
      for condition in customer[:filter]
        start = Time.now
        rentjuice_listings += @listings.find_all(condition.merge(customer[:hoods]).merge({:limit => 50, :order_by => "rentjuice_id"}))
        puts "|Downloaded #{customer[:name]}'s Rentjuce listings, #{rentjuice_listings.count} in total"
        puts "|Took #{Time.now - start}"
      end

      find_dupe_vals(rentjuice_listings)

      index = 0
      active = []
      for rentjuicer in rentjuice_listings
        puts ",-----------------------------------------"

        listing = nil
        listings = Listing.where("customer_id = ? and foreign_id = ?", leadadvo_id, rentjuicer.id.to_s)
        if !listings.nil? and listings.count > 1
          puts "|Duplicate Listings Please Check Advo ID #{leadadvo_id} RJ ID #{rentjuicer_id}."
          exit
        end
        listing = listings.nil? ? nil : listings[0]
        if !listing.nil?
          print "|Old Listing Found for "
          new = false
        else
          print "|#{c(green)}New Listing Found for "
          listing = Listing.new
          listing.customer_id = leadadvo_id
          listing.manual_enabled = true
          new = true
        end
        puts "#{customer[:name]}#{ec}"
        puts "|RentJuice ID: #{rentjuicer.id}"
        puts "|Current listing is #{index += 1} of #{rentjuice_listings.count}"

        location_changed = false
        if listing.location.nil? or listing.location.id != customer[:location].id
          print "|#{c(yellow)}Location   Changed#{ec}"
          print "  Was #{c(blue)}<#{ec}#{listing.location.id.to_s[0..100] rescue ""}#{c(blue)}>#{ec} "
          print "|  #{c(green)}Now #{c(blue)}<#{ec}#{customer[:location].id.to_s[0..100]}#{c(blue)}>#{ec}\n"
          listing.location = customer[:location]
          location_changed = true
        end
        hoods = rentjuicer.as_json["neighborhoods"]
        subloc = nil
        for hood in hoods
          temp_subloc = detect_sublocation(hood)
          if !temp_subloc.nil? and temp_subloc != subloc
            print "|#{c(red)}Error two sublocations detected: #{hoods.to_s}"
          end
          subloc = temp_subloc
        end
        subloc = Sublocation.find_by_url(subloc)
        if listing.sublocation.nil? or listing.sublocation.id != subloc.id 
          print "|#{c(yellow)}Sublocaion Changed#{ec}"
          print "  Was #{c(blue)}<#{ec}#{listing.sublocation.id.to_s[0..100] rescue ""}#{c(blue)}>#{ec} "
          print "|  #{c(green)}Now #{c(blue)}<#{ec}#{subloc || customer[:sublocation].id.to_s[0..100]}#{c(blue)}>#{ec}\n"
          listing.sublocation = subloc || customer[:sublocation]
          location_changed = true
        end

        if update_vars(listing, rentjuicer) or new or location_changed #(New implies updated_vars returns true but, just for clarity I have included it.)
          puts "|#{c(l_blue)}Saving Listing#{ec}"
          listing.save
        end

        #if new #New implies listing.save, so this could be external but, again I like the clarity of: listing.save MUST happen before images are saved.
        if !listing.id.nil?
          load_images(listing, rentjuicer.sorted_photos)
        end
      
        if rentjuicer.status == "active"
          puts "|#{c(green)}Foreign state is #{rentjuicer.status}#{ec}"
        else
          puts "|#{c(red)}Foreign state is #{rentjuicer.status}#{ec}"
        end

        if rentjuicer.status == "active" and !disable(listing)
          active << listing.id
        end

        puts "|Created/Updated Listing. Leadadvo ID #{listing.id}"
        puts "`-----------------------------------------"
        if !@running
          #Before bailing disabled what you can.
          puts "#{active.count} listings seen."
          activate = Listing.where("customer_id = ? and id in (?)", leadadvo_id, active).update_all("foreign_active = 't'")
          puts "#{activate} listings were activated."
         
          deactivate = Listing.where("customer_id = ? and id not in (?)", leadadvo_id, active).update_all("foreign_active = 'f'")
          puts "#{deactivate} listing(s) were deactivated."
          return
        end
      end
      
      puts "#{active.count} listings seen."
      activate = Listing.where("customer_id = ? and id in (?)", leadadvo_id, active).update_all("foreign_active = 't'")
      puts "#{activate} listings were activated."
     
      deactivate = Listing.where("customer_id = ? and id not in (?)", leadadvo_id, active).update_all("foreign_active = 'f'")
      puts "#{deactivate} listing(s) were deactivated."
      
      if !@running
        return
      end

    end
  end
end

###########################################################
############# Disable Check
###########################################################
def disable(listing)
  if listing.infos[:ad_title].nil? or listing.infos[:ad_title].empty?
    puts "|#{c(red)}Disabled due to empty title#{ec}"
    return true
  end

  image_urls = listing.ad_image_urls
  if image_urls.nil? or image_urls.empty?
    puts "|#{c(red)}Disabled due to empty images#{ec}"
    return true
  end

  if listing.ad_image_urls.count < 4
    puts "|#{c(red)}Disabled due to too few images#{ec}"
    return true
  end

  #In theory this should never be seen
  if image_urls.*(",").include?("/images/original/missing.png")
    puts "|#{c(red)}Disabled due to missing.png image#{ec}"
    return true
  end
  return false
end

###########################################################
############# Download Images
###########################################################
def load_images(listing, photos)
  #Assumption being, images never change.
  if !photos.empty? and listing.ad_image_urls.empty?

    for photo in photos
      if !photo.include?("/images/original/missing.png")

        attempts = 5
        while attempts > 0
          begin

            photo_uri = ""
            #Some listings don't have fullsize versions of the photos
            if !photo.fullsize.nil?
              photo_uri = photo.fullsize
            elsif !photo.original.nil?
              photo_uri = photo.original
            else
              break
            end
              
            http = nil
            urisplit = URI.split(photo_uri).reject{|i| i.nil?}
            domain = urisplit[1]
            path = urisplit[2..-1] * "/"
            if @connections.has_key?(domain)
              http = @connections[domain]
            else
              http = Net::HTTP.start(domain)
              @connections[domain] = http
            end
            resp = http.get(path)

            photo_file = in_memory_file(resp.body, urisplit.last.split("/").last)

            ListingImage.create(:listing_id => listing.id, :image => photo_file, :threading => photo.sort_order)
            puts "|Imported: #{photo_uri}"

            attempts = 0
          rescue => e
            puts "|#{c(red)}Attempt #{6 - attempts} failed: #{e.inspect}#{ec}"
            attempts -= 1
          end
        end

      end
    end

    puts listing.ad_image_urls
  end
end

###########################################################
############# Updated all Listing Variables
###########################################################
#Update all the vairables
#Requires the rentjuicer object to give values
#Requires the listing object to store the values locally
def update_vars(listing, rentjuicer)
  save = false
  #Need to run the location before the infos are set
  if get_location(listing, rentjuicer)
    save = true
  end
  rJson = rentjuicer.as_json
  #Convert the rentjuicer into json so it's easy to access the key, val pairs
  rJson.each{| key, val |
    #If the value is an array this needs to be converted into a string
    if val.class == Array
      val = val.join(",") || ""
    end

    #Create the infos symbol
    key_symbol = "ad_#{key}".to_sym
    #Deal with special symbols
    if key_symbol == :ad_rent
      key_symbol = :ad_price
    elsif key_symbol == :ad_rentjuice_id
      if !val.nil? and !val.to_s.empty? and (listing.foreign_id.nil? or listing.foreign_id != val.to_s)
        print_change(key_symbol, listing.foreign_id.nil? ? "": listing.foreign_id, val)
        listing.foreign_id = val.to_s
        save = true
      end
      next
    elsif key_symbol == :ad_title and (listing.infos[:ad_title].nil? or listing.infos[:ad_title].empty?)
      titles = []
      (0..2).each{
        title = ListingTitle.generate(
          :bedrooms => rJson["bedrooms"].to_i,
          :location => listing.infos[:ad_location],
          :type => rJson["property_type"],
          :amenities => rJson["features"]).gsub(/  /, " ")
        if title.length > 20
          #puts "|,New title generated:#{c(pink)}#{title}#{ec}"
          titles << title
        end
      }
      val = titles * ","
    end

    #If the value is new then update the infos
    if !val.nil? and !val.to_s.empty? and listing.infos[key_symbol].to_s != val.to_s
      print_change(key_symbol, listing.infos[key_symbol], val)
      listing.infos[key_symbol] = val.to_s
      save = true
    end
  }
  return save
end

def print_change(symbol, was, now)
  print "|#{c(yellow)}#{symbol.to_s.ljust(20," ")} Changed#{ec}"
  print "  Was #{c(blue)}<#{ec}#{was.to_s[0..100]}#{c(blue)}>#{ec} "
  print "|  #{c(green)}Now #{c(blue)}<#{ec}#{now.to_s[0..100]}#{c(blue)}>#{ec}\n"
end

###########################################################
############# Get_Location
###########################################################
#Takes a listing and rentjuice object
#Returns true or false depending on success of variable setting
def get_location(listing, rentjuicer)
  old_address = "#{listing.infos[:ad_street_number]} #{listing.infos[:ad_street]}, #{listing.infos[:ad_city]}, #{listing.infos[:ad_state]} #{listing.infos[:ad_zip_code]}" 
  new_address   = "#{rentjuicer.street_number} #{rentjuicer.street}, #{rentjuicer.city}, #{rentjuicer.state} #{rentjuicer.zip_code}"

  old_address.gsub!(/'/,' ')
  new_address.gsub!(/'/,' ')
  puts "|Old Address: #{old_address}"
  puts "|New Address: #{new_address}"

  done = false
  fail_attempts = 0
  while !done and (listing.infos[:ad_location].nil? or old_address != new_address)

    begin
      json_string = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(new_address)}&sensor=true").read
      #0.1 sec is the minimum wait between request but, with all the other code the total time between requests should be >> 0.1
      #Thus, cutting it close ought to be safe.
      sleep(0.1)

      parsed_json = ActiveSupport::JSON.decode(json_string)
      location = parsed_json["results"].first["address_components"][2]["short_name"]

      puts "|Detected location: #{location}"
      if listing.infos[:ad_location] != location
        listing.infos[:ad_location] = location

        return true
      end
      done = true
    rescue => e
      puts "|#{c(red)}Location Error: #{e.inspect}, trying again. Fail Attempt #{fail_attempts += 1}#{ec}"
      if fail_attempts > 5
        return false
      end
      #If for some reason the minimum is surpased. Make sure to wait a long time before trying again.
      #(I have seen it border on black listing if there are too many requests.)
      sleep(0.5)
    end
  end
  return false
end

###########################################################
############# Get_SubLocation
###########################################################
def detect_sublocation(neighborhood)
  if neighborhood == "Lakeworth"
    neighborhood = "Lake Worth"
  end
  puts "|Neighborhood: #{neighborhood}"
  search_address = neighborhood + ", FL"

  done = false
  attempts = 0
  while !done
    begin
      json_string = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(search_address)}&sensor=true").read
      sleep(0.1)

      parsed_json = ActiveSupport::JSON.decode(json_string)
      location1 = parsed_json["results"].first["address_components"][1]["short_name"] rescue location1 = nil
      location2 = parsed_json["results"].first["address_components"][2]["short_name"] rescue location2 = nil
      mdc = ["Miami-Dade","Miami"].to_h{"mdc"}
      brw = ["Broward"].to_h{"brw"}
      pbc = ["Palm Beach"].to_h{"pbc"}
      locations = {}.merge(mdc).merge(brw).merge(pbc)
      return locations[location1] if locations.keys.include?(location1)
      return locations[location2] if locations.keys.include?(location2)

      done = true
    rescue => e
      puts "|#{c(red)}Location Error: #{e.inspect}, trying again. Fail Attempt #{attempts += 1}#{ec}"
      done = true if attempts > 5
      sleep(0.5)
    end
  end
  return false
end

def blue; 4; end
def gray; 8; end
def l_blue; 6; end
def pink; 5; end
def yellow; 3; end
def green; 2; end
def red; 1; end
def c( fg, bg = nil ); "#{fg ? "\x1b[38;5;#{fg}m" : ''}#{bg ? "\x1b[48;5;#{bg}m" : ''}" end 
def ec; "\x1b[0m"; end

class Array
  def to_h(&block)
    Hash[*self.collect { |v|
      [v, block.call(v)]
    }.flatten]
  end
end

def find_dupe_vals (rentjuice_listings)
  key_map = {}
  for rentjuicer in rentjuice_listings
    foreign_id = rentjuicer.id
    if !key_map[foreign_id].nil?
      key_map[foreign_id] << rentjuicer
    else
      key_map[foreign_id] = [rentjuicer]
    end
  end

  for foreign_id, listings in key_map
    if listings.count > 1
      puts "|#{c(pink)}Found a duplicate foregin ID <#{foreign_id}>, count #{listings.count}. Value differences are as follows:#{ec}"
      key_count = {}
      for listing in listings
        for key in listing.as_json.keys
          if key_count[key].nil?
            key_count[key] = 1
          else
            key_count[key] += 1
          end
        end
      end
      for key, count in key_count
        if count != listings.count
          puts "#{key} has fewer instances than listings. #{count} for #{listings.count}. aka duplicates w/ similar values."
        end
      end

      for listing in listings
        for key in listing.as_json.keys
          vals = []
          for rj in listings
            if rj.as_json[key].class == Array
              for val in rj.as_json[key]
                if val.class == Hashie::Rash
                  ans = [] if ans.nil?
                  ans << val.values
                else
                  ans = "" if ans.nil?
                  ans << val
                end
              end
              vals << ans
              ans = nil
            else
              vals << rj.as_json[key]
            end
          end
          if vals[0] == Array
            index = 0
            for val in vals
              puts "#{val[index]}"
              index += 1
            end
          else
            if vals.uniq.count > 1         
              puts "|#{key} #{vals.class}"
              puts "|#{vals * "\n"}"
            end
          end
        end
      end
    end
    if !@running
      exit
    end
  end
  return rentjuice_listings
end

def find_dupe_ids (leadadvo_id)
  #Key is foreign_id, value is listing
  key_map = {}
  Listing.where("customer_id = ?", leadadvo_id).each{ |listing|
    foreign_id = listing.foreign_id
    if !key_map[foreign_id].nil?
      old_listing = key_map[foreign_id]
      puts "|#{c(pink)}Found a duplicate foregin ID <#{foreign_id}>, local IDs <#{listing.id}> - <#{old_listing.id}>#{ec}"
      if listing.id > old_listing.id
        puts "|Tossing the Old"
        old_listing.destroy
      else
        puts "|Tossing the New"
        listing.destroy
      end
    end
    key_map[foreign_id] = listing
    if !@running
      exit
    end
  }
end 
