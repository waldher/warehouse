require 'rentjuicer'

namespace :rentjuicer do
  desc "Import from RentJuicer"
  task :import => :environment do
    @rentjuicer = Rentjuicer::Client.new('3b97f4ec544152dd3a79ca0c19b32aab')
    puts "Rentjuice Client Created"

    @listings = Rentjuicer::Listings.new(@rentjuicer)
    puts "Rentjuice Listings Object Created"

    kangarent_id = Customer.where("key = ?","kangarent").last.id
    puts "Identified Kangarent's Leadadvo ID (#{kangarent_id})"

    kangarent_listings = @listings.find_all
    puts "Downloaded Kangarent's Rentjuce listings (#{kangarent_listings.count} in total)"

    kangarent_listings.each { |kang|
      if kang.status == "active"

        old_listings = Listing.where("customer_id = ?", kangarent_id)
        puts "Identified Kangarent's Leadadvo listings (#{old_listings.count} in total)"

        new = true
        for old_listing in old_listings
          if old_listing.infos[:ad_foreign_id].to_i == kang.id
            puts "Old Listing Found"
            listing = old_listing
            new = false
            break
          end
        end
        if new
          puts "New Listing Found, Rentjuce ID #{kang.id}"
          listing = Listing.new

          listing.customer_id = kangarent_id
          listing.active = false
          listing.infos[:ad_foreign_id] = kang.id
        end
     
        listing.infos[:ad_description] = kang.description || ""
        listing.infos[:ad_title] = kang.title || ""
        next if !kang.title
        listing.infos[:ad_address] = kang.address || ""
        listing.infos[:ad_price] = kang.rent || ""
        puts "Price : #{kang.rent}"
        next if kang.rent < 100
        listing.infos[:ad_bedrooms] = kang.bedrooms || ""
        listing.infos[:ad_bathrooms] = kang.bathrooms || ""
        listing.infos[:ad_square_footage] = kang.square_footage || ""
        listing.infos[:ad_keywords] = (kang.features * ", ") || ""
        listing.infos[:ad_latitude] = kang.latitude || ""
        listing.infos[:ad_longitude] = kang.longitude || ""
        listing.infos[:ad_neighborhoods] = kang.neighborhoods || ""
        listing.infos[:ad_property_type] = kang.property_type || ""
        listing.save
        puts "Listing has Leadadvo ID #{listing.id}"

        for image in kang.sorted_photos
          uploaded = false
          while !uploaded
            begin
              ListingImage.create(:listing_id => listing.id, :image => open(image.fullsize))
              uploaded = true
            rescue => e
              puts "#{e.inspect}"
            end
          end
          puts "Saved image #{image.fullsize}"
        end

        puts "Created new Listing"
        puts "-----------------------------------------"
      end
    }
  end
end
