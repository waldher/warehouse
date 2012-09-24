require 'open-uri'
require 'mechanize'
require 'listing_title'
require 'scrape'

class Mlxchange < Scrape
  COORDINATES_MAP = {
    "168,56" => { # 8 Photo View
      "120,192" => "ad_address",
      "824,16" => "ad_amenities",
      "1000,16" => "ad_attribution",
      "288,120" => "ad_bedrooms",
      "552,16" => "ad_description",
      "760,16" => "ad_exterior",
      "304,120" => "ad_full_bathrooms",
      "336,120" => "ad_half_bathrooms",
      "696,16" => "ad_interior",
      "120,24" => "ad_location",
      "120,608" => "ad_price",
      "352,120" => "ad_square_feet",
      "192,72" => "ad_status",
      "256,16" => "ad_subdivision",
      "504,104" => "ad_waterfront",
    },
    "184,120" => { # GCR - REA 2
      "64,16" => "ad_address",
      "672,72" => "ad_amenities",
      "920,16" => "ad_attribution",
      "416,664" => "ad_bedrooms",
      "240,64" => "ad_complex",
      "312,64" => "ad_description",
      "656,104" => "ad_exterior",
      "528,72" => "ad_equipment",
      "448,80" => "ad_full_bathrooms",
      "448,176" => "ad_half_bathrooms",
      "512,104" => "ad_interior",
      "88,104" => "ad_location",
      "736,552" => "ad_pets",
      "112,120" => "ad_price",
      "464,112" => "ad_square_feet",
      "160,120" => "ad_status",
      "24,16" => "ad_type",
      "576,336" => "ad_waterfont",
      "88,104" => "ad_zip",
    },
    "168,128" => { # GCR - REA 1
      "48,48" => "ad_address",
      "752,136" => "ad_amenities",
      "920,16" => "ad_attribution",
      "368,80" => "ad_bedrooms",
      "248,80" => "ad_subdivision",
      "280,64" => "ad_description",
      "688,8" => "ad_exterior",
      "496,80" => "ad_equipment",
      "368,168" => "ad_full_bathrooms",
      "368,272" => "ad_half_bathrooms",
      "480,112" => "ad_interior",
      "72,48" => "ad_location",
      "672,608" => "ad_pets",
      "96,128" => "ad_price",
      "368,416" => "ad_square_feet",
      "144,128" => "ad_status",
      "8,16" => "ad_type",
      "640,112" => "ad_waterfont",
      "72,48" => "ad_zip",
    },
    "136,568" => {
      "64,8" => "ad_address",
      "280,136" => "ad_amenities",
      "920,8" => "ad_attribution",
      "112,152" => "ad_bedrooms",
      "256,16" => "ad_subdivision",
      "304,40" => "ad_description",
      "232,136" => "ad_exterior",
      "112,264" => "ad_full_bathrooms",
      "112,264" => "ad_half_bathrooms",
      "208,136" => "ad_interior",
      "112,568" => "ad_price",
      "160,568" => "ad_status",
      "160,96" => "ad_waterfont",
    },
    "176,64" => {
      "16,200" => "ad_address",
      "792,520" => "ad_amenities",
      "992,16" => "ad_attribution",
      "200,104" => "ad_bedrooms",
      "176,520" => "ad_complex",
      "280,16" => "ad_description",
      "648,520" => "ad_exterior",
      "528,120" => "ad_equipment",
      "224,10" => "ad_full_bathrooms",
      "248,104" => "ad_half_bathrooms",
      "480,120" => "ad_interior",
      "16,16" => "ad_location",
      "632,520" => "ad_pets",
      "16,616" => "ad_price",
      "176,328" => "ad_square_feet",
      "48,240" => "ad_status",
      "208,328" => "ad_type",
      "728,144" => "ad_waterfont",
      "64,496" => "ad_zip",
    },
    "192,128" => {
      "64,24" => "ad_address",
      "688,72" => "ad_amenities",
      "936,8" => "ad_attribution",
      "376,480" => "ad_bedrooms",
      "248,80" => "ad_subdivision",
      "304,72" => "ad_description",
      "376,584" => "ad_full_bathrooms",
      "376,688" => "ad_half_bathrooms",
      "144,128" => "ad_location",
      "640,608" => "ad_pets",
      "120,128" => "ad_price",
      "376,112" => "ad_square_feet",
      "168,128" => "ad_status",
      "232,200" => "ad_type",
      "608,96" => "ad_waterfont",
      "88,24" => "ad_zip",
    }
    "56,391" =>
    {
      "56,89" => "ad_address",
      "792,78" => "ad_amenities",
      "444,138" => "ad_attribution",
      "282,114" => "ad_bedrooms",
      "534,12" => "ad_description",
      "696,78" => "ad_equipment",
      "720,78" => "ad_exterior",
      "294,114" => "ad_full_bathrooms",
      "306,114" => "ad_half_bathrooms",
      "672,78" => "ad_interior",
      "114,300" => "ad_location",
      "204,450" => "ad_pets",
      "81,634" => "ad_price",
      "330,114" => "ad_square_feet",
      "92,625" => "ad_status",
      "204,354" => "ad_waterfront",
      "114,636" => "ad_zip",
    },
    "160,64" => #RE2 8-photo view
    {
      "120,192" => "ad_address",
      "752,24" => "ad_amenities",
      "992,24" => "ad_attribution",
      "248,128" => "ad_bedrooms",
      "224,24" => "ad_complex",
      "480,120" => "ad_cooling",
      "504,24" => "ad_description",
      "272,128" => "ad_full_bathrooms",
      "296,128" => "ad_half_bathrooms",
      "688,24" => "ad_interior",
      "120,24" => "ad_location",
      "896,24" => "ad_maintenance",
      "120,600" => "ad_price",
      "320,128" => "ad_square_feet",
      "176,80" => "ad_status",
      "456,120" => "ad_waterfront"
    },
    "152,64" => #RE1 8-photo view
    {
      "120,208" => "ad_address",
      "1000,16" => "ad_attribution",
      "240,128" => "ad_bedrooms",
      "504,24" => "ad_description",
      "832,24" => "ad_exterior",
      "264,128" => "ad_full_bathrooms",
      "288,128" => "ad_half_bathrooms",
      "920,136" => "ad_hoa",
      "768,24" => "ad_interior",
      "120,24" => "ad_location",
      "896,24" => "ad_lot",
      "120,616" => "ad_price",
      "312,128" => "ad_square_feet",
      "216,24" => "ad_subdivision",
      "168,80" => "ad_status",
      "464,112" => "ad_waterfront"
    }
  }
  #info is a hash in the form:
  # :data => [{:url=>"scrape_url",:infos=>{}},] # One inner hash per url
  # :customer_key => 'customer_key'
  # :disable_new_titles => bool (generate new titles (true/false)?)
  # :activate_new => bool (activate newly imported listings)
  # :deactivate_old => bool (deactivate old listings)
  def mlx_import
    agent = Mechanize.new

    disable_new_titles = @import_run.input_parsed["disable_new_titles"]
    customer_key = @import_run.input_parsed["customer_key"]
    activate_new = @import_run.input_parsed["activate_new"]
    deactivate_old = @import_run.input_parsed["deactivate_old"]
    begin
      customer_id = Customer.where("key like ?",customer_key).first.id 
    rescue 
      @output["failed"] = "Customer Key '#{customer_key.to_s}' Not Found"
      return false
    end

    active = []
    $page = nil
    for data in @import_run.input_parsed["data"]
      craigslist_type = data["craigslist_type"].chomp.strip
      location = Location.find_by_url(data["location"].chomp.strip)
      sublocation = Sublocation.find_by_url(data["sublocation"].chomp.strip)

      external_infos = data["infos"]

      url = data["url"].chomp.strip
      $page = agent.get(url)

      $record_ids = $page.frames.first.content.forms.first.field_with(:name => 'RecordIDList').options.collect(&:to_s)
      var_list = $page.frames.first.content.forms.first.field_with(:name => "VarList").value
      site_code = $page.frames.first.content.forms.first.field_with(:name => "SiteCode").value
      mul_type = $page.frames.first.content.forms.first.field_with(:name => "MULType").value
      for_print = $page.frames.first.content.forms.first.field_with(:name => "ForPrint").value
      for_email = $page.frames.first.content.forms.first.field_with(:name => "ForEmail").value

      base_url = url.sub(/EmailView.*/,'GetViewEx.aspx')

      index = 0
      for record_id in $record_ids
        next if record_id.nil?
        $listing_page = nil
        failed = false
        while !failed
          begin
            $listing_page = agent.post(base_url, {"ForEmail" => for_email, "RecordIDList" => record_id, "ForPrint" => for_print, "MULType" => mul_type, "SiteCode" => site_code, "VarList" => var_list} )
            failed = true
          rescue => e
            @output["failed"] = e.inspect
          end
        end

        coordinates = {}
        $listing_page.body.each_line {|line|
          if line =~ /<span style="position:absolute;/
            coordinates[line.gsub(/.*top:([0-9]*)px;[^"]*left:([0-9]*)px;.*/, '\1,\2').strip] = line.gsub(/.*<span[^>]*>(.*)<\/span>.*/, '\1').gsub(/<.?NOBR>/, '').gsub(/&[^;]*;/, '').strip
          end
        }
        new_infos = {}

        foreign_id = nil
        COORDINATES_MAP.each{|foreign_id_coordinates, info_map|
          next if coordinates[foreign_id_coordinates].nil?

          foreign_id = coordinates[foreign_id_coordinates]
          info_map.each{|value_coordinates, info_key|
            new_infos[info_key] = coordinates[value_coordinates]
          }

          break
        }

        new_infos["ad_attribution"] = (new_infos["ad_attribution"] and new_infos["ad_attribution"].gsub(/.*Courtesy Of: */, ''))
        new_infos["ad_price"] = new_infos["ad_price"].gsub(/[^0-9]/, '')
        if data["include_body"]
          new_infos["ad_body"] = $listing_page.body
        end
        
        new_infos.merge((external_infos or {}))
        new_infos.delete_if{|k,v| v.nil?}

        listing = Listing.where("customer_id = ? and foreign_id = ?", customer_id, foreign_id).first
        if listing.nil?
          listing = Listing.new
          listing.customer_id = customer_id
          listing.foreign_id = foreign_id
          listing.craigslist_type = craigslist_type
          listing.location_id = location.id
          listing.sublocation_id = sublocation.id
        end 
        @listings_output[foreign_id] = {}
        @listings_output[foreign_id]["new"] = listing.id.nil?
        @listings_output[foreign_id]["record_id"] = record_id
        @listings_output[foreign_id]["infos"] = {}
        new_infos.merge!((data["infos"] or {}))
        new_infos.each{|k, v|
          @listings_output[foreign_id]["infos"][k] = [listing.infos[k], v]
        }

        if new_infos["ad_title"].nil?
          new_infos["ad_title"] = []
          5.times {
            title = ListingTitle.generate(listing, new_infos)
            new_infos["ad_title"] << title if !title.nil? and !title.empty? and title.length > 20
            break if new_infos["ad_title"].size >= 3
          }
        end

        listing.infos = new_infos

        listing.save
        
        images = []
        $listing_page.body.split("\n").each{|l|
          if l =~ /^ViewObject_[0-9]*_List = /
            images += l.gsub(/^ViewObject_[0-9]*_List = "(.*)";/, '\1').split('|')
          end
        }
        images.uniq!
        load_images(listing, images)

        active << listing.id if (data["force_active"] or
                                 !(new_infos["ad_status"] =~ /^Active/).nil? or 
                                 !(new_infos["ad_status"] =~ /^New/).nil? or 
                                 !(new_infos["ad_status"] =~ /^Price Change/).nil?) and !disable?(listing)
      end
    end
    activate_new_listings(customer_id, active) if activate_new
    deactivate_old_listings(customer_id, active) if deactivate_old
  rescue => e
    @output["failed"] = "#{e.inspect}\n\n#{e.backtrace.join("\n")}"
  ensure
    save_output
  end
#  handle_asynchronously :mlx_import, :attempts => 1
end
