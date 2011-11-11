namespace :plumpads do 
  desc "Import Listing for plumpads from files"
  task :import, [:folder] => [:environment] do |t, args|
   
    listing_dir = args[:folder].strip
    unless(Dir.exists?(listing_dir)) 
      puts "No such directory exists"
      exit
    end
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
      Listing.where("customer_id = ?", customer.id).update_all("foreign_active = false")
      Dir.foreach(listing_dir) do |filename|
        ## Skip files starting with . (dot)
        next if filename =~ /^[.]/
        
        print ",-----------------------------\n"
        foreign_key = filename.split("\.")[0]
        listing = Listing.where("customer_id = ? and foreign_id = ?", customer.id, foreign_key)[0]
        if listing.nil?
          print "New Listing\n"
          listing = Listing.new
          listing.customer_id = customer.id
          listing.foreign_id = foreign_key
        else
          print "Old Listing\n"
        end

        file_path = "#{listing_dir}/#{filename}"
        file = File.open(file_path)

        file.read.split("\r\n\r\n").each do |ele| 
          element = ele.strip.split(":")
          key = listing_attr[element[0].strip]
          value = element[1].nil? ? "" : element[1].strip
          if key && value
            print "#{key} => #{value}\n"
            #listing_infos = listing.listing_infos.create!({:key => key, :value => value})
            listing.infos[key.to_sym] = value
          end
        end

        file = File.open(file_path)
        file.read.match(/Body :(.*)/m) do
          print "#ad_body => #{$1}\n"
          #listing_infos = listing.listing_infos.create!({:key => "ad_description", :value => $1}) if $1
          listing.infos[:ad_body] = $1 if $1
        end
        
        listing.active = true
        listing.foreign_active = true
        listing.save
      end

    end
  end
end
