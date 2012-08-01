require 'net/http'

class Scrape
  def initialize(import_run)
    @import_run = import_run
    @output = {}
    @listings_output = {}
  end

  def save_output
    @import_run.finished = true
    result_output = Hash.new(@output)
    result_output["listings"] = []
    @listings_output.each{|l| result_output["listings"] << l }
    @import_run.output = JSON.generate(result_output)
    @import_run.save
  end

  proxy_addr = ["http://74.221.217.34","http://74.221.217.28"].sample
  proxy_port = (47001..47020).to_a.sample
  @proxy = proxy_addr + ":" + proxy_port.to_s

  def value_update(listing, key_symbol, val)
    if !val.nil? and !val.empty? and listing.infos[key_symbol].to_s != val.to_s
      @listings_output[listing]["infos"][key_symbol.to_s] = [listing.infos[key_symbol], val.to_s]
      listing.infos[key_symbol] = val

      return true
    end
    return false
  end

  def disable?(listing)
    if listing.infos["ad_title"].nil? or listing.infos["ad_title"].empty?
      @listings_output[listing]["disabled"] = "no titles"
      return true
    end

    if listing.infos["ad_attribution"].nil? or listing.infos["ad_attribution"].empty?
      @listings_output[listing]["disabled"] = "no attribution"
      return true
    end

    image_urls = listing.ad_image_urls
    if image_urls.nil? or image_urls.empty?
      @listings_output[listing]["disabled"] = "no images"
      return true
    end 

    if listing.ad_image_urls.count < 3 
      @listings_output[listing]["disabled"] = "too few images"
      return true
    end

    #In theory this should never be seen - it is a paperclip related error
    if listing.ad_image_urls.*(",").include?("/images/original/missing.png")
      @listings_output[listing]["disabled"] = "missing images"
      return true
    end

    return false
  end

  def activate_new_listings(customer_id, listing_ids)
    @output["listings_seen"] = listing_ids.count
    activated = Listing.where("customer_id = ? and id in (?)", customer_id, listing_ids).update_all(:foreign_active => true, :updated_at => Time.now)
    @output["activated"] = activated
  end

  def deactivate_old_listings(customer_id, listing_ids)
    deactivated = Listing.where("customer_id = ? and id not in (?)", customer_id, listing_ids).update_all(:foreign_active => false, :updated_at => Time.now)
    @output["deactivated"] = deactivated
  end

  def location_from_address(address)
    #Remove Unit and apostrophies.
    address = address.gsub(/# *[^ ,]*/, '').gsub(/'/,'') 

    try_again = true
    #This allows for address detection failures to be tried again.
    while true
      begin
        json_string = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(address)}&sensor=true", :proxy => @proxy).read
        parsed_json = ActiveSupport::JSON.decode(json_string)
        return gmaps_api_to_location(parsed_json["results"].first["address_components"][2]["short_name"])
      rescue => e
        if try_again
          #Trying to fix some common errors that break the google query.
          address = address.
                      downcase.
                      sub(/ te /i, ' terrace ').
                      sub(/ point /i, ' pointe ').
                      sub(/ pa /i, ' pl ').
                      sub(/ Unincorporated /i, '').
                      sub(/([0-9]+) TH/i, '\1th').
                      sub(/ ca /i, ' cswy ') #Could mess up california - keep an eye on this
          
          try_again = false
        else
          raise "Google Maps API doesn't like the address format. Please Check."
        end
        #Sleep 0.5sec in case the error was due to query rate
        sleep(0.5)
      end
    end
    return "ERR"
  end

  #Because Gmaps occasionally misslables.
  def gmaps_api_to_location(detected)
    
    dcase = detected.downcase.strip

    map = { 
      "mid-beach"=>"miami beach",
      "city center"=>"miami beach",
      "south point"=>"miami beach",
      "lummus"=>"miami beach",
      "flamingo"=>"miami beach",
      "flamingo / lummus"=>"miami beach",
      "north beach"=>"north miami beach",
      "douglas"=>"coral gables",
      "bayshore"=>"miami beach"
    }

    for key in map.keys
      return map[key].titlecase if dcase.match(key) or key.match(dcase)
    end
    return detected
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
      return map[key].titlecase if building.match(key) or key.match(building)
    end
    return nil 
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

              attempts = 0
            rescue => e
              attempts -= 1
            end
          end

        end
      end
    end
  end
end
