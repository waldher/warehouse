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
