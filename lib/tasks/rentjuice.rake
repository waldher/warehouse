require 'open-uri'
require 'uri'
require 'rentjuicer'
require 'listing_title'
#require 'scrape_utils'

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

    rj_customers = Customer.includes([:customer_infos, :location, :sublocation]).
      where(:customer_infos => { :key => ['rj_id', 'filter', 'neighborhoods']})
    # Can add one more condition as enabled or disabled so we have more control 
    # on customers for whom we have to run this rake task for.....
    customers = []
    rj_customers.each do |customer|
      customer_hash = {}
      tmp_hash = {}
      customer.customer_infos.each { |info| tmp_hash[info.key.to_sym] = info.value }

      begin
        puts "Customer: #{customer.key}"
        customer_hash[:name] = customer.key

        puts "Rentjuicer id: #{tmp_hash[:rj_id]}"
        customer_hash[:rj_id] = tmp_hash[:rj_id]

        puts "Neighborhoods: #{tmp_hash[:neighborhoods]}"
        customer_hash[:hoods] = {:neighborhoods => tmp_hash[:neighborhoods]}

        puts "Filters : #{tmp_hash[:filter]}"
        customer_hash[:filter] = JSON.parse(tmp_hash[:filter])

        puts "Email : #{customer.email_address}"
        customer_hash[:email] = {:agent => customer.email_address }

        puts "Location : #{customer.location.name}"
        customer_hash[:location] = customer.location

        puts "Sublocation: #{customer.sublocation.name}"
        customer_hash[:sublocation] = customer.sublocation
      rescue
        # JSON on a customer w/o filters cause crashes
        next
      end

      customers << customer_hash
    end 

    @connections = {}
    @neighborhood_map = {}
  
    for customer in customers
      puts ",============================================="
      leadadvo_id = Customer.where("key = ?",customer[:name]).last.id
      special_puts "Identified #{customer[:name]}'s Leadadvo ID as #{leadadvo_id}"

      find_dupe_ids(leadadvo_id)

      @rentjuicer = Rentjuicer::Client.new(customer[:rj_id])
      special_puts "Rentjuice Client Created"
      @listings = Rentjuicer::Listings.new(@rentjuicer)
      special_puts "Rentjuice Listings Object Created"
 
      rentjuice_listings = []
      for condition in customer[:filter]
        start = Time.now
        rentjuice_listings += @listings.find_all(condition.merge(customer[:hoods]).merge({:limit => 50, :order_by => "rentjuice_id"}))
        special_puts "Downloaded #{customer[:name]}'s Rentjuce listings, #{rentjuice_listings.count} in total"
        special_puts "Took #{Time.now - start}"
      end

      find_dupe_vals(rentjuice_listings)

      index = 0
      active = []
      for rentjuicer in rentjuice_listings
        puts ",-----------------------------------------"

        listing = nil
        listings = Listing.where("customer_id = ? and foreign_id = ?", leadadvo_id, rentjuicer.id.to_s)
        if !listings.nil? and listings.count > 1
          special_puts "Duplicate Listings Please Check Advo ID #{leadadvo_id} RJ ID #{rentjuicer_id}."
          exit
        end
        listing = listings.nil? ? nil : listings[0]
        if !listing.nil?
          special_print "Old Listing Found for "
          new = false
        else
          special_print "#{c(green)}New Listing Found for "
          listing = Listing.new
          listing.customer_id = leadadvo_id
          new = true
        end
        puts "#{customer[:name]}#{ec}"
        special_puts "RentJuice ID: #{rentjuicer.id}"
        special_puts "Current listing is #{index += 1} of #{rentjuice_listings.count}"

        location_changed = false
        if listing.location.nil? or listing.location.id != customer[:location].id
          print_change("location",(listing.location.url.to_s rescue ""),customer[:location].url.to_s)
          listing.location = customer[:location]
          location_changed = true
        end
        save = {:save => false, :why => []}

        if detect_sublocation(listing,rentjuicer,customer)
          save[:save] = true
          save[:why] = "New Sublocation"
        end

        ########################## ADDRESS #############################
        address   = "#{rentjuicer.street_number} #{rentjuicer.street}, #{rentjuicer.city}, #{rentjuicer.state} #{rentjuicer.zip_code}"
        location = location_from_address(listing, address)
        if value_update(listing, "ad_location", location)
          save[:save] = true
          save[:why] = "New Location"
        end

        save = true if update_vars(listing,rentjuicer)

        if save or new or location_changed #(New implies updated_vars returns true but, just for clarity I have included it.)
          special_puts "#{c(l_blue)}Saving Listing#{ec}"
          listing.save
          if !listing.errors.empty?
            special_puts "#{c(red)}Save Errors: #{listing.errors}#{ec}"
          end 
        end

        #if new #New implies listing.save, so this could be external but, again I like the clarity of: listing.save MUST happen before images are saved.
        if !listing.id.nil?
          load_images(listing, rentjuicer.sorted_photos)
        end
      
        if rentjuicer.status == "active"
          special_puts "#{c(green)}Foreign state is #{rentjuicer.status}#{ec}"
        else
          special_puts "#{c(red)}Foreign state is #{rentjuicer.status}#{ec}"
        end

        if rentjuicer.status == "active" and !disable?(listing)
          active << listing.id
        end

        special_puts "Created/Updated Listing. Leadadvo ID #{listing.id}"
        puts "`-----------------------------------------"
        if !@running
          #Before bailing disabled what you can.
          activate_listings(leadadvo_id, active)
          exit
        end
      end
      
      if !@running
        activate_listings(leadadvo_id, active)
        exit
      end
    end
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

  rJson = rentjuicer.as_json
  #Convert the rentjuicer into json so it's easy to access the key, val pairs
  rJson.each{| key, val |
    #If the value is an array this needs to be converted into a string
    if val.class == Array
      val = val.join(", ") || ""
    end

    #Create the infos symbol
    key_symbol = "ad_#{key}"
    #Deal with special symbols
    if key_symbol == "ad_rent"
      key_symbol = "ad_price"
    elsif key_symbol == "ad_rentjuice_id"
      if !val.nil? and !val.to_s.empty? and (listing.foreign_id.nil? or listing.foreign_id != val.to_s)
        print_change(key_symbol, listing.foreign_id.nil? ? "": listing.foreign_id, val)
        listing.foreign_id = val.to_s
        save = true
      end
      next
    #length < 25 avoids the occasional title 'Xbr' titles that are going to ghost
    elsif key_symbol == "ad_title" and (listing.infos["ad_title"].nil? or listing.infos["ad_title"].empty? or (!val.nil? and val.length < 25) )
      titles = []
      (0..2).each{
        title = ListingTitle.generate(listing)
        if title.length > 20
          special_puts " New title generated:#{c(pink)}#{title}#{ec}"
          titles << title
        end
      }
      val = titles * "||"
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

###########################################################
############# Get_Location
###########################################################
#Takes a listing and rentjuice object
#Returns true or false depending on success of variable setting
def get_location(listing, rentjuicer)

end

###########################################################
############# Get_SubLocation
###########################################################
def detect_sublocation(listing, rentjuicer, customer)
  subloc = nil
  for neighborhood in rentjuicer.as_json["neighborhoods"] do
    #Special cases needed. Customer spelling error.
    if neighborhood == "Lakeworth"
      neighborhood = "Lake Worth"
    end
    special_puts "Neighborhood: #{neighborhood}"
    
    #Only if the neighborhood is one we haven't seen should we use the Google API
    if @neighborhood_map[neighborhood].nil?
      search_address = neighborhood + ", " + rentjuicer.state

      done = false
      attempts = 0
      while !done
        begin
          json_string = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(search_address)}&sensor=true",:proxy => @proxy).read
          sleep(0.1)

          parsed_json = ActiveSupport::JSON.decode(json_string)
          location1 = parsed_json["results"].first["address_components"][1]["short_name"] rescue location1 = nil
          location2 = parsed_json["results"].first["address_components"][2]["short_name"] rescue location2 = nil
          mdc = ["Miami-Dade","Miami"].to_h{"mdc"}
          brw = ["Broward"].to_h{"brw"}
          pbc = ["Palm Beach"].to_h{"pbc"}
          locations = {}.merge(mdc).merge(brw).merge(pbc)
          (@neighborhood_map[neighborhood] = locations[location1]; temp_subloc = locations[location1]) if locations.keys.include?(location1)
          (@neighborhood_map[neighborhood] = locations[location2]; temp_subloc = locations[location2]) if locations.keys.include?(location2)

          done = true
        rescue => e
          special_puts "#{c(red)}Location Error: #{e.inspect}, trying again. Fail Attempt #{attempts += 1}#{ec}"
          done = true if attempts > 5
          sleep(0.5)
        end
      end
    else
      temp_subloc = @neighborhood_map[neighborhood]
    end
    
    if !subloc.nil? and temp_subloc != subloc
      special_puts "#{c(red)}Error multiple sublocations detected: #{rentjuicer.as_json["neighborhoods"].to_s}: #{temp_subloc || "nil"} #{subloc || "nil"}#{ec}"
    end
    subloc ||= temp_subloc
  end
  
  subloc = Sublocation.find_by_url(subloc) || customer[:sublocation]
  if listing.sublocation.nil? or listing.sublocation.id != subloc.id 
    special_print "#{c(yellow)}Sublocaion Changed#{ec}"
    print "  Was #{c(blue)}<#{ec}#{listing.sublocation.url.to_s[0..100] rescue ""}#{c(blue)}>#{ec} "
    special_print "  #{c(green)}Now #{c(blue)}<#{ec}#{subloc.url || customer[:sublocation].url.to_s[0..100]}#{c(blue)}>#{ec}\n"
    listing.sublocation = subloc
    return true
  end
  return false
end

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
      special_puts "#{c(pink)}Found a duplicate foregin ID <#{foreign_id}>, count #{listings.count}. Value differences are as follows:#{ec}"
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
              special_puts "#{key} #{vals.class}"
              special_puts "#{vals * "\n"}"
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
      special_puts "#{c(pink)}Found a duplicate foregin ID <#{foreign_id}>, local IDs <#{listing.id}> - <#{old_listing.id}>#{ec}"
      if listing.id > old_listing.id
        special_puts "Tossing the Old"
        old_listing.destroy
      else
        special_puts "Tossing the New"
        listing.destroy
      end
    end
    key_map[foreign_id] = listing
    if !@running
      exit
    end
  }
end 
