namespace :plumpads do 
  desc "Import Listing for plumpads from files"
  task :import, [:folder] => [:environment] do |t, args|
  
    http_dir = "http://www.2rentit.com/other/bens/"
    
    agent = Mechanize.new
    page = agent.get(http_dir)

    listing_attr = {
      "rentals rate" => "ad_price",
      "bedroom" => "ad_bedrooms",
      "Square Footage" => "ad_square_footage",
      "Title" => "ad_title",
      "Location/city" => "ad_location",
      "description" => "ad_description",
      "image load area" => "ad_image_list",
      "top text" => "ad_top_text",
      "Address" => "ad_address"
    }
    customer = Customer.where(:key => "plumpads").first
    if customer.nil?
      puts "Customer not found"
    else
      puts "Customer with key #{customer.key} found"
    end
    location = Location.where("url = ?", "miami").first
    sublocation = location.sublocations.where("url = ?", "brw").first
    if customer
      Listing.where("customer_id = ?", customer.id).update_all("foreign_active = 'f'")
      page.links.each{|link|
        ## Skip files starting with . (dot)
        next if (link.href =~ /[.]txt$/).nil?
        
        print ",-----------------------------\n"
        foreign_key = link.href.split("\.")[0]
        listing = Listing.where("customer_id = ? and foreign_id = ?", customer.id, foreign_key)[0]
        if listing.nil?
          print "New Listing\n"
          listing = Listing.new
          listing.customer_id = customer.id
          listing.foreign_id = foreign_key
        else
          print "Old Listing\n"
        end

        file = link.click

        multiline_label = nil
        multiline_body = ""

        for line in file.body.split("\n")
          if line.strip.empty?
            next
          elsif line.strip =~ /:$/
            if multiline_label
              listing.infos[listing_attr[multiline_label]] = multiline_body
              print "#{listing_attr[multiline_label]} => #{multiline_body}\n"
            end
            multiline_label = line.split(":").first.strip
            multiline_body = ""
          elsif multiline_label
            multiline_body += "\n" + line
          elsif (element = line.strip.split(":")).size == 2
            key = listing_attr[element[0].strip]
            value = element[1].nil? ? "" : element[1].strip
            if key && value
              print "#{key} => #{value}\n"
              listing.infos[key.to_sym] = value
            end
          end
        end

        if multiline_label
          listing.infos[listing_attr[multiline_label]] = multiline_body
          print "#{listing_attr[multiline_label]} => #{multiline_body}\n"
        end
        
        listing.foreign_active = true
        listing.location = location
        listing.sublocation = sublocation
        listing.save
      }

    end
  end
end
