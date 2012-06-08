require 'csv'
require 'in_memory_file'
require 'open-uri'
 
 namespace :thehomesteadgroup do
 	desc "Import listing"
  	task :import => :environment do
  		print "Enter customer id :"
		customer_id = STDIN.gets.strip
		print "Enter sublocation id :"
		sublocation_id = STDIN.gets.strip
    fp = open("http://www.thehomesteadgroup.com/uploads/photos/Craigslist_Export.csv")
 		CSV.foreach(fp) do |row| 
 			status = (row[2] == "Active") ? true : false
 			listing_object = Listing.new(:customer_id => customer_id,:sublocation_id => sublocation_id,:manual_enabled => status)
			infos = Hash.new
			infos["ad_address"] = row[3]
			infos["ad_price"] = row[4]
			infos["ad_description"] = row[6]
			infos["ad_bedrooms"] = row[7]
			infos["ad_style"] = row[18]
			infos["ad_square_footage"] = row[21]
			infos["ad_location"] = row[22]
			infos["ad_title"] = "[]"

      image_url_strings = []
      for image_url_string in row[25..30]
        if image_url_string.nil?
          next
        end

        image_url_strings << image_url_string
      end

			if listing_object.save
				infos.each do |key, value|
					listing_info = ListingInfo.create(:listing_id => listing_object.id, :key => key, :value => value )
				end
			end		

      load_images(listing_object, image_url_strings)
		end
		puts "successfully data imported"
    fp.close
	end
end


