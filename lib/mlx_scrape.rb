require 'open-uri'
require 'mechanize'
require 'listing_title'
require 'scrape_utils'

#info is a hash in the form:
# :data => [{:url=>"scrape_url",:infos=>{}},] # One inner hash per url
# :key => 'customer_key'
# :new_titels => bool (generate new titles (true/false)?)
def mlx_import(info)
  @running = true
  Kernel.trap("INT"){
    @running = false
    print " *****************************\n"
    print " * Gracefully killing import *\n"
    print " *****************************\n"
  }

  agent = Mechanize.new

  new_titles = info[:new_titles]
  customer_key = info[:key]
  begin
    customer_id = Customer.where("key like ?",customer_key).first.id 
  rescue 
    special_puts "#{c(red)}Customer Key '#{customer_key.to_s}' Not Found!#{ec}"
    return false
  end

  active = []
  $page = nil
  for data in info[:data]
    external_infos = data[:infos] #Hash
    url = data[:url].chomp.strip

    $page = agent.get(url)

    $record_ids = nil
    $record_ids = $page.frames.first.content.forms.first.field_with(:name => 'RecordIDList').options
    var_list = $page.frames.first.content.forms.first.field_with(:name => "VarList").value
    site_code = $page.frames.first.content.forms.first.field_with(:name => "SiteCode").value
    mul_type = $page.frames.first.content.forms.first.field_with(:name => "MULType").value
    for_print = $page.frames.first.content.forms.first.field_with(:name => "ForPrint").value
    for_email = $page.frames.first.content.forms.first.field_with(:name => "ForEmail").value

    base_url = url.sub(/EmailView.*/,'GetViewEx.aspx')

    index = 0
    for record_id in $record_ids
      print ",-----------------------------------------------------------------------\n"
      $listing_page = nil
      failed = false
      while !failed
        begin
          $listing_page = agent.post(base_url, {"ForEmail" => for_email, "RecordIDList" => record_id, "ForPrint" => for_print, "MULType" => mul_type, "SiteCode" => site_code, "VarList" => var_list} )
          failed = true
        rescue => e
          special_puts "#{e.inspect}"
          if record_id.nil?
            break
          end
        end
      end

      foreign_id = ""
      saw_foreign = false
      $listing_page.body.split("\n").each{|l|
        if saw_foreign
          saw_foreign = false
          foreign_id = l.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '')
        elsif l =~ /REF #:/ or l =~ /ML#:/
          saw_foreign = true
        elsif l =~ /top:78px;height:13px;left:312px;width:96px;font:8pt Tahoma;/
          foreign_id = l.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '')
          break
        end
      }
      foreign_id.strip!

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
      end 
      special_puts pre_message+"#{customer_key}#{ec}"
      special_puts "MLX ID: #{foreign_id}"
      special_puts "record_id = \"#{record_id}\""
      special_puts "Current listing is #{index += 1} of #{$record_ids.count}"

      new_infos = {}
      ########################## ADDRESS #############################
      address = ""
      for l in $listing_page.body.split("\n").each
        if (l =~ /top:120px;height:22px;left:192px;width:392px;font:bold 12pt/ or 
            l =~ /top:120px;height:19px;left:192px;width:432px;font:bold 11pt Tahoma;/ or 
            l =~ /top:64px;height:16px;left:8px;width:704px;font:bold 10pt Arial;/ or 
            l =~ /top:120px;height:24px;left:192px;width:416px;font:bold 11pt Tahoma;/ or 
            l =~ /top:109px;height:22px;left:209px;width:400px;font:bold 12pt Tahoma;/ or
            l =~ /top:120px;height:19px;left:192px;width:432px;font:bold 11pt Tahoma;/ or
            l =~ /top:120px;height:24px;left:208px;width:400px;font:bold 11pt Tahoma;/ or
            l =~ /top:232px;height:20px;left:200px;width:424px;font:bold 12pt Tahoma;/ or
            l =~ /top:56px;height:11px;left:89px;width:204px;font:7pt Tahoma;/)
              address = l
        end
      end
      address = address.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '').gsub(/&curren;/, '')
      new_infos["ad_address"] = address if !address.nil? and !address.empty?
      #if value_update(listing, "ad_address", address)
      #  save[:save] = true
      #  save[:why] << "New Address"
      #end

      ########################## LOCATION ############################
      location = nil
      building = nil
      for l in $listing_page.body.split("\n")
        if l.match(/top:256px;height:18px;left:16px;width:232px;font:10pt/)
          building = l
          building = building.gsub(/.*<NOBR> */, '').gsub(/<\/NOBR>.*/, '').gsub(/&curren; */, '')
          special_puts "Found Building #{building}, referencing neighborhood"
          location = building_to_location(building) if !building_to_location(building).nil?
          break
        elsif(l =~ /text-align:left;vertical-align:top;line-height:120%;color:rgb\(0,0,128\);background-color:rgb\(224,224,224\);z-index:1;overflow:hidden;/ or
              l =~ /top:232px;height:20px;left:32px;width:152px;font:bold 12pt Tahoma;/ or
              l =~ /top:114px;height:13px;left:300px;width:186px;font:8pt Tahoma;/)
          location = l
          location = location.gsub(/.*<NOBR> */, '').gsub(/<\/NOBR>.*/, '').gsub(/&curren; */, '')
          special_puts "Found Location #{location}"
          break
        else
          location = nil #This is implicit but, I like the clarity of writing it explicitly BBW
        end 
      end
      if location.nil?
        location = location_from_address(address)
      end
      new_infos["ad_location"] = location if !location.nil? and !location.empty?
      #if value_update(listing, "ad_location", location)
      #  save[:save] = true
      #  save[:why] << "New Location"
      #end

      ########################## PRICE ###############################
      $listing_page.body.split("\n").each{|l|
        if (l =~ /top:112px;height:16px;left:568px;width:128px;font:bold 10pt Arial;/ or 
           l =~ /background-color:rgb\(224,224,224\);z-index:1;overflow:hidden;/ or
           l =~ /top:232px;height:20px;left:624px;width:128px;font:bold 12pt Tahoma;/ or
           l =~ /top:378px;height:13px;left:114px;width:84px;font:8pt Tahoma;/) or
           l =~ /top:81px;height:26px;left:634px;width:62px;font:8pt Arial;/)
          price = l.gsub(/.*\$ */, '').gsub(/<\/NOBR>.*/, '').gsub(/<span[^>]*>/, '').gsub(/<\/span>/, '')
          new_infos["ad_price"] = price if !price.nil? and !price.empty?
          #if value_update(listing, "ad_price", price)
          #  save[:save] = true
          #  save[:why] << "New Price"
          #end
        end
      }

      ########################## BEDROOMS ############################
      bedrooms = ""
      saw_beds = false
      $listing_page.body.split("\n").each{|l|
        if saw_beds
          saw_beds = false
          bedrooms = l.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '')
        elsif l =~ /Bedrooms:/ or l =~ /Beds:/
          saw_beds = true
        end
      }
      new_infos["ad_bedrooms"] = bedrooms if !bedrooms.nil? and !bedrooms.empty?
      #if value_update(listing, "ad_bedrooms", bedrooms)
      #  save[:save] = true
      #  save[:why] << "New Bedrooms"
      #end

      ########################### COMPLEX ############################
      complex = nil
      saw_complex = false
      for l in $listing_page.body.split("\n")
        if saw_complex
          saw_complex = false
          complex = l.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '')
        elsif l =~ /Complex Name:/ or l =~ /Subdivision:/
          saw_complex = true
        end
      end
      new_infos["ad_complex"] = complex if !complex.nil? and !complex.empty?
      #if value_update(listing, "ad_complex", complex)
      #  save[:save] = true
      #  save[:why] << "New Complex"
      #end

      ########################## DESCRIPTION #########################
      desc = ""
      for l in $listing_page.body.split("\n")
        if (l =~ /background-color:rgb\(224,224,224\);border-color:rgb\((0,0|128,128),128\);border-style:solid;border-width:1;z-index:1;overflow:hidden;/ or
            l =~ /top:304px;height:128px;left:40px;width:656px;font:bold 10pt Arial;/ or
            l =~ /top:504px;height:105px;left:24px;width:576px;font:9pt Tahoma;/ or
            l =~ /top:864px;height:112px;left:112px;width:552px;font:10pt Tahoma;/ or
            l =~ /Public remarks:/i)
          desc = l
        end
      end
      desc = desc.gsub(/<span[^>]*>/, '').gsub(/<\/span>/, '').gsub(/.*Public remarks:/i, '')
      for l in $listing_page.body.split("\n")
        if l =~ /top:882px;height:99px;left:12px;width:756px;font:7pt Tahoma;/
          desc += l.gsub(/<span[^>]*>/, '').gsub(/<\/span>/, '')
        end
      end
      new_infos["ad_description"] = desc if !desc.nil? and !desc.empty?
      #if value_update(listing, "ad_description", desc)
      #  save[:save] = true
      #  save[:why] << "New Description"
      #end

      ########################### AMENITIES ##########################
      amenities = ""
      for l in $listing_page.body.split("\n")
        if (l =~ /top:280px;height:16px;left:136px;width:568px;font:bold 10pt Arial;/ or
            l =~ /top:752px;height:32px;left:24px;width:576px;font:10pt Tahoma;/ or
            l =~ /top:824px;height:32px;left:16px;width:432px;font:10pt Tahoma;/ )
          amenities = l
        end
      end
      amenities = amenities.gsub(/.*<NOBR>/i, '').gsub(/<\/NOBR>.*/i, '').gsub(/<span[^>]*>/i, '').gsub(/<\/span>/i, '').split(/ *\/ /).join('||')
      new_infos["ad_amenities"] = amenities if !amenities.nil? and !amenities.empty?
      #if value_update(listing, "ad_amenities", amenities)
      #  save[:save] = true
      #  save[:why] << "New Amenities"
      #end

      ########################## TITLES ##############################
      titles = []
      if listing.infos["ad_title"].nil? or new_titles
        (0..2).each{
          title = ListingTitle.generate(listing)
          if !title.nil? and !title.empty? and title.length > 20
            special_puts "New title generated: #{c(pink)}#{title}#{ec}"
            titles << title
          end
        }
        titles = (titles * "||").gsub(/  /,' ')
        new_infos["ad_title"] = titles if !titles.nil? and !titles.empty?
        #if value_update(listing, "ad_title", (titles * "||").gsub(/  /,' '))
        #  save[:save] = true
        #  save[:why] << "New Title"
        #end
      end
      
      ########################## COURTESY ############################
      for l in $listing_page.body.split("\n")
        if l =~ /Courtesy Of:/ or l =~ /top:444px;height:13px;left:138px;width:234px;font:8pt Tahoma;/
          attribution = l.gsub(/.*Courtesy Of: */, '').gsub(/.*<NOBR>/i, '').gsub(/<\/NOBR>.*/, '').gsub(/&nbsp;/, '').gsub(/<span[^>]*>/i, '').gsub(/<\/span>/i, '').strip
          new_infos["ad_attribution"] = attribution if !attribution.nil? and !attribution.empty?
          #if value_update(listing, "ad_attribution", attribution)
          #  save[:save] = true
          #  save[:why] << "New Attribution"
          #end
        end
      end

      ################### APPLYING EXTERNAL INFOS ####################
      if !external_infos.nil?
        for key, value in external_infos
          new_infos[key] = value
        end
      end

      ######################## SAVING INFOS ##########################
      if new_infos != listing.infos or listing.changed?
        special_puts "#{c(l_blue)}Saving Listing#{ec}:"
        for key, new_value in new_infos.diff(listing.infos)
          print_change(key, listing.infos[key], new_value)
          listing.infos[key] = new_value
        end
        listing.save
        if !listing.errors.empty?
          special_puts "#{c(red)}#{listing.errors}#{ec}"
        end
      end

      ########################## IMAGES ##############################
      images = []
      $listing_page.body.split("\n").each{|l|
        if l =~ /^ViewObject_[0-9]*_List = /
          images += l.gsub(/^ViewObject_[0-9]*_List = "(.*)";/, '\1').split('|')
        end
      }
      images.uniq!
      load_images(listing, images)

      ########################## STATUS ##############################
      if $listing_page.body =~ /Status:/
        status = ""
        saw_status = false
        $listing_page.body.split("\n").each{|l|
          if saw_status
            saw_status = false
            status = l.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '')
          elsif l =~ /Status:/
            saw_status = true
          end
        }
      else
        status = "Active-Available"
      end
      #$listing_page.body.split("\n").each{ |l| temp_active = l if l =~ /top:192px;height:18px;left:72px;width:120px;font:10pt Tahoma;/ or l =~ /top:176px;height:18px;left:80px;width:120px;font:10pt Tahoma;/ or l =~ /top:168px;height:18px;left:80px;width:128px;font:10pt Tahoma;/ }

      if (status =="Active-Available" or status == "Active") and !disable?(listing)
        special_puts "Rental Status #{c(green)}Active #{ec}: #{status}"
        active << listing.id
      else
        special_puts "Rental Status #{c(red)}Inactive #{ec}: #{c(red)}#{status}#{ec}"
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
