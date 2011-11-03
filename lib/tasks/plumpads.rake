namespace :rentjuicer do 
  desc "Import Listing for plumpads from files"
  task :plumpads => :environment do
    listing_dir = Rails.root.join("lib", "plumpads")
    listing_attr = {
      "rentals rate" => "ad_price",
      "bedroom" => "ad_bedrooms",
      "Square Footage" => "ad_square_footage",
      "Title" => "ad_title",
      "Location/city" => "ad_location",
    }
    customer = Customer.where(:key => "plumpads").first
    if customer
      Dir.foreach(listing_dir) do |filename|
        ## Skip files starting with . (dot)
        next if filename =~ /^[.]/
        file_path = "#{listing_dir}/#{filename}"
        file = File.open(file_path)

        # create a new listing with customer_id
        #
        listing = customer.listings.create!
        file.read.split("\r\n\r\n").each do |ele| 
          element = ele.strip.split(":")
          key = listing_attr[element[0].strip]
          value = element[1].strip rescue ""
          if key && value
            #p "#{key} => #{value}"
            listing_infos = listing.listing_infos.create!({:key => key, :value => value})
          end
        end


        file = File.open(file_path)
        file.read.match(/Body(.*)/m) do
          #p "#ad_description => #{$1}"
          listing_infos = listing.listing_infos.create!({:key => "ad_description", :value => $1}) if $1
        end
      end
    end
  end
end
