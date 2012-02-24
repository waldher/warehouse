require 'open-uri'
require 'mechanize'
require 'listing_title'
require 'scrape_utils'

#Info is a hash with:
# :urls => ['array of mlx scrape urls']
# :key => 'customer_key'
# :location => 'default location' (Nil if - autodetect required or location unknown)
def mlx_import(info)
  @running = true
  Kernel.trap("INT"){
    @running = false
    print " *****************************\n"
    print " * Gracefully killing import *\n"
    print " *****************************\n"
  }

  agent = Mechanize.new

  customer_key = info[:key]
  begin
    customer_id = Customer.where("key like ?",customer_key).first.id 
  rescue 
    special_puts "#{c(red)}Customer Key (#{customer_key.to_s}) Not Found!#{ec}"
    return false 
  end

  active = []
  $page = nil
  for url in info[:urls]
    $page = agent.get(url.chomp.strip)

    $record_ids = nil
    $record_ids = $page.frames.first.content.forms.first.field_with(:name => 'RecordIDList').options

    index = 0
    for record_id in $record_ids
      print ",-----------------------------------------------------------------------\n"
      $listing_page = nil
      failed = false
      while !failed
        begin
          $listing_page = agent.post('http://sef.mlxchange.com/DotNet/Pub/GetViewEx.aspx', {"ForEmail" => "1", "RecordIDList" => record_id, "ForPrint" => "false", "MULType" => "2", "SiteCode" => "SEF", "VarList" => "1GdCmTJIpLlcE4KGf5pa5HC6P58ljE1n7BHGsz7yzuG+18HEq2nRnWCJYEeepcbz"} )
          failed = true
        rescue => e
          special_puts "#{e.inspect}"
          if record_id.nil?
            break
          end
        end
      end

      foreign_id = ""
      $listing_page.body.split("\n").each{ |l| foreign_id = l if l =~ /top:168px;height:15px;left:56px;width:56px;font:8pt/}
      foreign_id = foreign_id.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '')
      foreign_id.strip!

      save = {:save => false, :why => []}
      #Detect an old listing
      listings = nil
      listings = Listing.where("customer_id = ? and foreign_id = ?", customer_id, foreign_id)
      if !listings.nil? and listings.count > 1 
        special_puts "Duplicate Listings Please Check Advo ID #{customer_id} RJ ID #{foreign_id}."
        return
      end 
      listing = listings.nil? ? nil : listings[0]
      if !listing.nil?
        pre_message = "Old Listing Found for "
      else
        pre_message = "#{c(green)}New Listing Found for "
        listing = Listing.new
        listing.customer_id = customer_id
        listing.foreign_id = foreign_id
        save[:save] = true
        save[:why] << "New Listing"
      end 
      special_puts pre_message+"#{customer_key}#{ec}"
      special_puts "MLX ID: #{foreign_id}"
      special_puts "record_id = \"#{record_id}\""
      special_puts "Current listing is #{index += 1} of #{$record_ids.count}"

      ########################## ADDRESS #############################
      address = ""
      $listing_page.body.split("\n").each{ |l| address = l if l =~ /120px;height:22px;left:192px;width:392px;font:bold 12pt/ }
      address = address.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '').gsub(/&curren;/, '')
      if value_update(listing, :ad_address, address)
        save[:save] = true
        save[:why] << "New Address"
      end

      ########################## LOCATION ############################
      location = nil
      if !info[:location].nil?
        location = info[:location]
      else
        building = nil
        $listing_page.body.split("\n").each{|l| building = l if l.match(/top:256px;height:18px;left:16px;width:232px;font:10pt/) }
        if !building.nil?
          building = building.gsub(/.*<NOBR> */, '').gsub(/<\/NOBR>.*/, '').gsub(/&curren; */, '')
          location = building_to_location(building)
        else
          location = nil #This is implicit but, I like the clarity of writing it explicitly BBW
        end
      end
      #If, for whatever reason, location is nil it ought to be detected.
      if location.nil?
        address += ", FL"
        json_string = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(address)}&sensor=true").read
        sleep(0.1)
        parsed_json = ActiveSupport::JSON.decode(json_string)
        location = parsed_json["results"].first["address_components"][2]["short_name"]
      end
      if value_update(listing, :ad_location, location)
        save[:save] = true
        save[:why] << "New Location"
      end

      ########################## PRICE ###############################
      price = ""
      $listing_page.body.split("\n").each{ |l| (price = l ) if l =~ /120px;height:22px;left:608px;width:152px;font:bold 12pt.*\$/ }
      price = price.gsub(/.*<NOBR>\$ */, '').gsub(/<\/NOBR>.*/, '')
      if value_update(listing, :ad_price, price)
        save[:save] = true
        save[:why] << "New Prive"
      end

      ########################## BEDROOMS ############################
      bedrooms = ""
      saw_beds = false
      $listing_page.body.split("\n").each{|l|
        if saw_beds
          saw_beds = false
          bedrooms = l.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '')
        elsif l =~ /Bedrooms:/
          saw_beds = true
        end
      }
      if value_update(listing, :ad_bedrooms, bedrooms)
        save[:save] = true
        save[:why] << "New Bedrooms"
      end

      ########################## DESCRIPTION #########################
      desc = ""
      $listing_page.body.split("\n").each{|l| desc = l if l =~ /.*552.*224,224,224.*/ }
      desc = desc.gsub(/<span[^>]*>/, '').gsub(/<\/span>/, '')
      if value_update(listing, :ad_description, desc)
        save[:save] = true
        save[:why] << "New Description"
      end

      ########################## TITLES ##############################
      titles = []
      if listing.infos[:ad_title].nil?
        (0..2).each{
          title = ListingTitle.generate(
            :bedrooms => listing.infos[:ad_bedrooms].to_i,
            :location => listing.infos[:ad_location],
            :type => "",
            :amenities => "")
          if title.length > 20
            #special_puts "New title generated: #{c(pink)}#{title}#{ec}"
            titles << title
          end
        }
        if value_update(listing, :ad_title, (titles * "||").gsub(/  /,' '))
          save[:save] = true
          save[:why] << "New Title"
        end
      end

      if save[:save]
        special_puts "#{c(l_blue)}Saving Listing#{ec}: #{save[:why].join(", ")}"
        listing.save
      end

      ########################## IMAGES ##############################
      images = []
      $listing_page.body.split("\n").each{|l|
        if l =~ /^ViewObject_[0-9]*_List = /
          images << l.gsub(/^ViewObject_[0-9]*_List = "/, '').gsub(/\|.*/, '')
        end
      }
      images.rotate!(-3)
      load_images(listing, images)
      
      ########################## COURTESY ############################
      $listing_page.body.split("\n").each{|l|
        if l =~ /Courtesy Of:/
          courtesy = l.gsub(/.*Courtesy Of: */, '').gsub(/<\/NOBR>.*/, '')
          if value_update(listing, :ad_courtesy, courtesy)
            save[:save]
            save[:why] << "New Courtesy"
          end
        end
      }

      ########################## STATUS ##############################
      temp_active = nil
      $listing_page.body.split("\n").each{ |l| temp_active = l if l =~ /192px;height:18px;left:72px;width:120px;font:10pt/ }
      temp_active = temp_active.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '')
      if temp_active =="Active-Available" and  !disable(listing)
        special_puts "Rental Status #{c(green)}Active #{ec}: #{temp_active}"
        active << listing.id
      else
        special_puts "Rental Status #{c(red)}Inactive #{ec}: #{c(red)}#{temp_active}#{ec}"
      end

      special_puts "Created/Updated Listing. Leadadvo ID #{listing.id}"
      print "`-----------------------------------------------------------------------\n"
      if !@running
        activate_listings(customer_id, active)
        return
      end
    end
  end
  activate_listings(customer_id, active)
end

@@connections = {}
def load_images(listing, photos)
  #Assumption being, images never change.
  if !photos.empty? and listing.ad_image_urls.empty?

    for photo_uri in photos
      if !photo_uri.include?("/images/original/missing.png")

        attempts = 3
        while attempts > 0
          begin

            #Some listings don't have fullsize versions of the photos
            if photo_uri.nil?
              break
            end

            http = nil
            special_puts "Importing: #{photo_uri}"
            urisplit = URI.split(photo_uri).reject{|i| i.nil?}
            #special_puts "`-> Pieces " + urisplit.join(" - ")
            domain = urisplit[1]
            path = urisplit[2..-1] * "/"
            if @@connections.has_key?(domain)
              http = @@connections[domain]
            else
              http = Net::HTTP.start(domain)
              @@connections[domain] = http
            end
            resp = http.get(path)

            photo_file = in_memory_file(resp.body, urisplit.last.split("/").last)

            ListingImage.create(:listing_id => listing.id, :image => photo_file, :threading => 0)

            attempts = 0
          rescue => e
            special_puts "#{c(red)}Attempt #{4 - attempts} failed: #{e.inspect}#{ec}"
            attempts -= 1
          end
        end

      end
    end

    listing.ad_image_urls.each{|url| special_puts url}
  end
end

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

def building_to_location(building)

  building = building.downcase.strip
 
  map = { 
    "icon brickell" => "brickell",
    "epic" => "downtown miami",
    "carbonell" => "brickell key",
    "asia" => "brickell key",
    "jade" => "brickell",
    "500 brickell" => "brickell",
    "plaza" => "brickell",
    "brickell on the river" => "brickell",
    "ivy" => "brickell riverfront",
    "mint" => "brickell riverfront",
    "wind" => "brickell riverfront"
  }   

  for key in map.keys
    return map[key].titlecase if building.match(/#{key}/)
  end 
  return nil
end
