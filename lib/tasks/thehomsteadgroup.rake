require 'csv'
 
 namespace :thehomsteadgroup do
 	desc "Import listing"
  	task :import => :environment do
  		print "Enter customer id :"
		customer_id = STDIN.gets.strip
		print "Enter sublocation id :"
		sublocation_id = STDIN.gets.strip
 		CSV.foreach("db/thehomsteadgroup/Craigslist_Export.csv") do |row| 
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
			if listing_object.save
				infos.each do |key, value|
					listing_info = ListingInfo.create(:listing_id => listing_object.id, :key => key, :value => value )
				end
			end		
		end
		puts "successfully data imported"
	end
end