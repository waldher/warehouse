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
            special_puts "Importing: #{photo_uri}"
            urisplit = URI.split(photo_uri).reject{|i| i.nil?}
            #special_puts "`-> Pieces " + urisplit.join(" - ")
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
            special_puts "#{c(red)}Attempt #{4 - attempts} failed: #{e.inspect}#{ec}"
            attempts -= 1
          end
        end

      end
    end

    listing.ad_image_urls.each{|url| special_puts url}
  end
end
