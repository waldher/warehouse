require 'csv'
require 'in_memory_file'
require 'open-uri'
 
namespace :thehomesteadgroup do
  desc "Import listing"
  task :import => :environment do
    lens = []
    customers = []
    for customer in Customer.all
      lens << customer.key.length
      customers << {:id => customer.id.to_s, :key => customer.key}
    end
    lens << "Customer".length
    max_len = lens.max
    seperators = "+----+#{(1..max_len+2).map{"-"}.join}+"
    puts seperators
    puts "| ID | #{"Customer".ljust(max_len, ' ')} |"
    puts seperators
    for customer in customers
      puts "| #{customer[:id].ljust(2, ' ')} | #{customer[:key].ljust(max_len, ' ')} |"
    end
    puts seperators
    print "Enter customer id :"
    customer_id = STDIN.gets.strip.to_i

    lens = []
    sublocations = []
    for sublocation in Sublocation.all
      lens << sublocation.name.length
      sublocations << {:id => sublocation.id.to_s, :name => sublocation.name}
    end
    lens << "Sublocation".length
    max_len = lens.max
    seperators = "+----+#{(1..max_len+2).map{"-"}.join}+"
    puts seperators
    puts "| ID | #{"Sublocation".ljust(max_len, ' ')} |"
    puts seperators
    for sublocation in sublocations
      puts "| #{sublocation[:id].ljust(2, ' ')} | #{sublocation[:name].ljust(max_len, ' ')} |"
    end
    puts seperators
    print "Enter sublocation id :"
    sublocation_id = STDIN.gets.strip.to_i

    fp = open("http://www.thehomesteadgroup.com/uploads/photos/Craigslist_Export.csv")
    CSV.foreach(fp) do |row|
      status = (row[2] == "Active") ? true : false
      listing = Listing.new(:customer_id => customer_id,:sublocation_id => sublocation_id,:manual_enabled => status)
      listing.infos["ad_address"] = row[3]
      listing.infos["ad_price"] = row[4]
      listing.infos["ad_description"] = row[6]
      listing.infos["ad_bedrooms"] = row[7]
      listing.infos["ad_style"] = row[18]
      listing.infos["ad_square_footage"] = row[21]
      listing.infos["ad_location"] = row[22]
      listing.infos["ad_title"] = ListingTitle.generate(listing)

      image_url_strings = []
      for image_url_string in row[25..30]
        if image_url_string.nil?
          next
        end

        image_url_strings << image_url_string
      end

      load_images(listing, image_url_strings)
    end
    puts "successfully data imported"
    fp.close
  end
end
