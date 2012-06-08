require 'open-uri'
require 'mechanize'
require 'listing_title'
require 'scrape_utils'
require 'load_images'

#info is a hash in the form:
# :data => [{:url=>"scrape_url",:infos=>{}},] # One inner hash per url
# :customer_key => 'customer_key'
# :disable_new_titles => bool (generate new titles (true/false)?)
# :activate_new => bool (activate newly imported listings)
# :deactivate_old => bool (deactivate old listings)
def mlx_import(info)
  @running = true
  Kernel.trap("INT"){
    @running = false
    print " *****************************\n"
    print " * Gracefully killing import *\n"
    print " *****************************\n"
  }

  agent = Mechanize.new

  disable_new_titles = info[:disable_new_titles]
  customer_key = info[:customer_key]
  activate_new = info[:activate_new]
  deactivate_old = info[:deactivate_old]
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
      old_infos = listing.infos
      ########################## ADDRESS #############################
      address = ""
      for l in $listing_page.body.split("\n")
        if (l =~ /top:120px;height:22px;left:192px;width:392px;font:bold 12pt/ or 
            l =~ /top:120px;height:19px;left:192px;width:432px;font:bold 11pt Tahoma;/ or 
            l =~ /top:64px;height:16px;left:8px;width:704px;font:bold 10pt Arial;/ or 
            l =~ /top:120px;height:24px;left:192px;width:416px;font:bold 11pt Tahoma;/ or 
            l =~ /top:109px;height:22px;left:209px;width:400px;font:bold 12pt Tahoma;/ or
            l =~ /top:120px;height:19px;left:192px;width:432px;font:bold 11pt Tahoma;/ or
            l =~ /top:120px;height:24px;left:208px;width:400px;font:bold 11pt Tahoma;/ or
            l =~ /top:232px;height:20px;left:200px;width:424px;font:bold 12pt Tahoma;/ or
            l =~ /top:56px;height:11px;left:89px;width:204px;font:7pt Tahoma;/ or
            l =~ /top:64px;height:18px;left:16px;width:688px;font:bold 10pt Arial/)
              address = l
              break
        end
      end
      address = address.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '').gsub(/(&curren;|Address: )/, '')
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
              l =~ /top:114px;height:13px;left:300px;width:186px;font:8pt Tahoma;/i or
              l =~ /top:88px;height:16px;left:16px;width:688px;font:bold 10pt Arial;/)
          location = l
          location = location.gsub(/.*<NOBR> */, '').gsub(/<\/NOBR>.*/, '').gsub(/(&curren;|Subdivision: ) */, '')
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
           l =~ /top:378px;height:13px;left:114px;width:84px;font:8pt Tahoma;/ or
           l =~ /top:81px;height:26px;left:634px;width:62px;font:8pt Arial;/ or
           l  =~ /top:112px;height:19px;left:574px;width:127px;font:bold 11pt Arial;/)
          price = l.gsub(/.*\$ */, '').gsub(/<\/NOBR>.*/, '').gsub(/<span[^>]*>/, '').gsub(/<\/span>/, '')
          new_infos["ad_price"] = price if !price.nil? and !price.empty?
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

      ########################### COMPLEX ############################
      complex = nil
      saw_complex = false
      for l in $listing_page.body.split("\n")
        if saw_complex
          saw_complex = false
          complex = l.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '').gsub(/<&curren;/,'')
        elsif l =~ /Complex Name:/
          saw_complex = true
        end
      end
      new_infos["ad_complex"] = complex if !complex.nil? and !complex.empty?

      ########################## DESCRIPTION #########################
      desc = ""
      for l in $listing_page.body.split("\n")
        if (l =~ /background-color:rgb\(224,224,224\);border-color:rgb\((0,0|128,128),128\);border-style:solid;border-width:1;z-index:1;overflow:hidden;/ or
            l =~ /top:304px;height:128px;left:40px;width:656px;font:bold 10pt Arial;/ or
            l =~ /top:504px;height:105px;left:24px;width:576px;font:9pt Tahoma;/ or
            l =~ /top:864px;height:112px;left:112px;width:552px;font:10pt Tahoma;/ or
            l =~ /Public remarks:/i or 
            l =~ /top:264px;height:112px;left:16px;width:680px;font:10pt Arial;/)
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

      ########################### AMENITIES ##########################
      amenities = ""
      for l in $listing_page.body.split("\n")
        if (l =~ /top:280px;height:16px;left:136px;width:568px;font:bold 10pt Arial;/ or
            l =~ /top:752px;height:32px;left:24px;width:576px;font:10pt Tahoma;/ or
            l =~ /top:824px;height:32px;left:16px;width:432px;font:10pt Tahoma;/ )
          amenities = l
        end
      end
      amenities = amenities.gsub(/.*<NOBR>/i, '').gsub(/<\/NOBR>.*/i, '').gsub(/<span[^>]*>/i, '').gsub(/<\/span>/i, '').split(/ *[\/,] /).join('||')
      new_infos["ad_amenities"] = amenities if !amenities.nil? and !amenities.empty?

      ########################## TITLES ##############################
      titles = []
      if !disable_new_titles
        (0..2).each{
          title = ListingTitle.generate(listing)
          if !title.nil? and !title.empty? and title.length > 20
            special_puts "New title generated: #{c(pink)}#{title}#{ec}"
            titles << title
          end
        }
        new_infos["ad_title"] = titles if !titles.nil? and !titles.empty?
      else
        new_infos["ad_title"] = old_infos["ad_title"]
      end
      
      ########################## COURTESY ############################
      for l in $listing_page.body.split("\n")
        if (l =~ /Courtesy Of:/ or 
            l =~ /top:444px;height:13px;left:138px;width:234px;font:8pt Tahoma;/ or
            l =~ /top:920px;height:13px;left:8px;width:464px;font:8pt Arial;/)
          attribution = l.gsub(/.*Courtesy Of: */, '').gsub(/.*<NOBR>/i, '').gsub(/<\/NOBR>.*/, '').gsub(/&nbsp;/, '').gsub(/<span[^>]*>/i, '').gsub(/<\/span>/i, '').strip
          new_infos["ad_attribution"] = attribution if !attribution.nil? and !attribution.empty?
        end
      end

      ################### APPLYING EXTERNAL INFOS ####################
      if !external_infos.nil?
        for key, value in external_infos
          new_infos[key] = value
        end
      end

      ######################## SAVING INFOS ##########################
      infos_differ = false
      keys = (new_infos.keys + old_infos.keys).uniq.sort
      for key in keys
        new_infos[key] = new_infos[key] || ""
        if old_infos[key] != new_infos[key]
          print_change(key, old_infos[key], new_infos[key])
          listing.infos[key] = new_infos[key]
          infos_differ = true
        end
      end
      if infos_differ or listing.changed?
        special_puts "#{c(l_blue)}Saving Listing#{ec}"
        listing.updated_at = Time.now #If for some reason the listing doesn't have any change but the info changed we still want the "updated_at" to change (so customers can see)
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
        activate_new_listings(customer_id, active) if activate_new
        deactivate_old_listings(customer_id, active) if deactivate_old
        return
      end
    end
  end
  activate_new_listings(customer_id, active) if activate_new
  deactivate_old_listings(customer_id, active) if deactivate_old
end
