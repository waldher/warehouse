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
    }
    customer = Customer.where(:key => "plumpads").first
    if customer.nil?
      puts "Customer not found"
    else
      puts "Customer with key #{customer.key} found"
    end
    if customer
      Listing.where("customer_id = ?", customer.id).update_all("foreign_active = ?", false)
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

        file.body.split("\n\n").each do |ele| 
          element = ele.strip.split(":")
          key = listing_attr[element[0].strip]
          value = element[1].nil? ? "" : element[1].strip
          if key && value
            print "#{key} => #{value}\n"
            #listing_infos = listing.listing_infos.create!({:key => key, :value => value})
            listing.infos[key.to_sym] = value
          end
        end

        file.body.match(/Body :(.*)/m) do
          print "#ad_body => #{$1}\n"
          #listing_infos = listing.listing_infos.create!({:key => "ad_description", :value => $1}) if $1
          listing.infos[:ad_body] = $1 if $1
        end
        
        listing.active = true
        listing.foreign_active = true
        location = Location.find_by_url("miami")
        sublocation = Sublocation.where("location_id = ? and url = ", location.id, "brw")
        listing.save
      }

    end
  end
end
