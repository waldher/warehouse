require 'uri'
require 'mechanize'
require 'listing_title'

class MlxScrape

  def blue; 4; end
  def gray; 8; end
  def l_blue; 6; end
  def pink; 5; end
  def yellow; 3; end
  def green; 2; end
  def red; 1; end
  def c( fg, bg = nil ); "#{fg ? "\x1b[38;5;#{fg}m" : ''}#{bg ? "\x1b[48;5;#{bg}m" : ''}" end
  def ec; "\x1b[0m"; end

#Info is a hash with:
# :url => ''
# :key =>
  def mlx_import(info)
    @running = true
    Kernel.trap("INT"){
      @running = false
      print " *****************************\n"
      print " * Gracefully killing import *\n"
      print " *****************************\n"
    }

    agent = Mechanize.new

    #This saves the need to query and loop through the Listings table for each customer.
    customer_key = info[:key]
    customer_id = Customer.where("key like ?",customer_key).first.id

    $page = nil
    $page = agent.get(info[:url].chomp.strip)

    $record_ids = nil
    $record_ids = $page.frames.first.content.forms.first.field_with(:name => 'RecordIDList').options

    index = 0
    active = []
    for record_id in $record_ids
      puts "-----------------------------------------------------------------------"
      $listing_page = nil
      failed = false
      while !failed
        begin
          $listing_page = agent.post('http://sef.mlxchange.com/DotNet/Pub/GetViewEx.aspx', {"ForEmail" => "1", "RecordIDList" => record_id, "ForPrint" => "false", "MULType" => "2", "SiteCode" => "SEF", "VarList" => "1GdCmTJIpLlcE4KGf5pa5HC6P58ljE1n7BHGsz7yzuG+18HEq2nRnWCJYEeepcbz"} )
          failed = true
        rescue => e
          puts "#{e.inspect}"
        end
      end

      foreign_id = ""
      $listing_page.body.split("\n").each{ |l| foreign_id = l if l =~ /top:168px;height:15px;left:56px;width:56px;font:8pt/}
      foreign_id = foreign_id.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '')
      foreign_id.strip!

      #Detect an old listing
      listings = nil
      listings = Listing.where("customer_id = ? and foreign_id = ?", customer_id, foreign_id)
      if !listings.nil? and listings.count > 1 
        puts "Duplicate Listings Please Check Advo ID #{customer_id} RJ ID #{foreign_id}."
        return
      end 
      listing = listings.nil? ? nil : listings[0]
      if !listing.nil?
        print "Old Listing Found for "
      else
        print "#{c(green)}New Listing Found for "
        listing = Listing.new
        listing.customer_id = customer_id
        listing.foreign_id = foreign_id
        listing.active = true
        save = true
      end 
      puts "#{customer_key}#{ec}"
      puts "MLX ID: #{foreign_id}"
      puts "record_id = \"#{record_id}\""
      puts "Current listing is #{index += 1} of #{$record_ids.count}"

      address = ""
      $listing_page.body.split("\n").each{ |l| address = l if l =~ /120px;height:22px;left:192px;width:392px;font:bold 12pt/ }
      address = address.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '').gsub(/&curren;/, '')
      if val_update(listing, :ad_address, address)
        save = true
      end

      address += ", Miami, FL"
      json_string = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(address)}&sensor=true").read
      sleep(0.1)
      parsed_json = ActiveSupport::JSON.decode(json_string)
      location = parsed_json["results"].first["address_components"][2]["short_name"]
      if val_update(listing, :ad_location, (info[:location].nil? ? location : info[:location]))
        save = true
      end

      price = ""
      $listing_page.body.split("\n").each{ |l| (price = l ) if l =~ /120px;height:22px;left:608px;width:152px;font:bold 12pt.*\$/ }
      price = price.gsub(/.*<NOBR>\$ */, '').gsub(/<\/NOBR>.*/, '')
      if val_update(listing, :ad_price, price)
        save = true
      end

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
      if val_update(listing, :ad_bedrooms, bedrooms)
        save = true
      end
      
      desc = ""
      $listing_page.body.split("\n").each{|l| desc = l if l =~ /.*552.*224,224,224.*/ }
      desc = desc.gsub(/<span[^>]*>/, '').gsub(/<\/span>/, '')
      if val_update(listing, :ad_description, desc)
        save = true
      end

      titles = []
      if true or listing.infos[:ad_title].nil?
        (0..2).each{
          title = ListingTitle.generate(
            :bedrooms => listing.infos[:ad_bedrooms].to_i,
            :location => listing.infos[:ad_location],
            :type => "",
            :amenities => "")
          if title.length > 20
            #puts "New title generated: #{c(pink)}#{title}#{ec}"
            titles << title
          end
        }
        if val_update(listing, :ad_title, (titles * ",").gsub(/  /,' '))
          save = true
        end
      end

      puts "#{c(l_blue)}Saving Listing#{ec}"
      listing.save

      images = []
      $listing_page.body.split("\n").each{|l|
        if l =~ /^ViewObject_[0-9]*_List = /
          images << l.gsub(/^ViewObject_[0-9]*_List = "/, '').gsub(/\|.*/, '')
        end
      }
      images.rotate!(-3)
      load_images(listing, images)

      temp_active = nil
      $listing_page.body.split("\n").each{ |l| temp_active = l if l =~ /192px;height:18px;left:72px;width:120px;font:10pt/ }
      temp_active = temp_active.gsub(/.*<NOBR>/, '').gsub(/<\/NOBR>.*/, '')
      if temp_active =="Active-Available" and  !disable(listing)
        puts "#{c(green)}Foreign Active#{ec} #{temp_active}"
        active << listing.id
      else
        puts "#{c(red)}Foreing Inactive#{ec} #{temp_active}"
      end

      puts "Succereated/Updated Listing. Leadadvo ID #{listing.id}"
      puts "-----------------------------------------------------------------------"
      if !@running
        puts "#{active.count} listings seen."
        activate = Listing.where("customer_id = ? and id in (?)", customer_id, active).update_all("foreign_active = 't'")
        puts "#{activate} listings were activated."

        deactivate = Listing.where("customer_id = ? and id not in (?)", customer_id, active).update_all("foreign_active = 'f'")
        puts "#{deactivate} listing(s) were deactivated."
        return
      end
    end
    puts "#{active.count} listings seen."
    activate = Listing.where("customer_id = ? and id in (?)", customer_id, active).update_all("foreign_active = 't'")
    puts "#{activate} listings were activated."

    deactivate = Listing.where("customer_id = ? and id not in (?)", customer_id, active).update_all("foreign_active = 'f'")
    puts "#{deactivate} listing(s) were deactivated."
  end

  def val_update(listing, key_symbol, val)
    if !val.nil? and !val.to_s.empty? and listing.infos[key_symbol].to_s != val.to_s
      print_change(key_symbol, listing.infos[key_symbol], val)
      listing.infos[key_symbol] = val.to_s
      return true
    end
    return false
  end

  def print_change(symbol, was, now)
    print "#{c(yellow)}#{symbol.to_s.ljust(20," ")} Changed#{ec}"
    print "  Was #{c(blue)}<#{ec}#{was.to_s[0..100]}#{c(blue)}>#{ec} "
    print "  #{c(green)}Now #{c(blue)}<#{ec}#{now.to_s[0..100]}#{c(blue)}>#{ec}\n"
  end

  @@connections = {}
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
              if !photo.nil?
                photo_uri = photo
              else
                break
              end

              http = nil
              urisplit = URI.split(photo_uri).reject{|i| i.nil?}
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
              puts "Imported: #{photo_uri}"

              attempts = 0
            rescue => e
              puts "#{c(red)}Attempt #{6 - attempts} failed: #{e.inspect}#{ec}"
              attempts -= 1
            end
          end

        end
      end

      puts listing.ad_image_urls
    end
  end

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

    #In theory this should never be seen
    if image_urls.*(",").include?("/images/original/missing.png")
      puts "|#{c(red)}Disabled due to missing.png image#{ec}"
      return true
    end
    return false
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
end
