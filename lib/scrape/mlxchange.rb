require 'open-uri'
require 'mechanize'
require 'listing_title'
require 'scrape'

class Mlxchange < Scrape
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
        new_infos["ad_address"] = coordinates["120,192"]
        new_infos["ad_amenities"] = coordinates["824,16"]
        new_infos["ad_attribution"] = coordinates["1000,16"].gsub(/.*Courtesy Of: */, '')
        new_infos["ad_bedrooms"] = coordinates["288,120"]
        new_infos["ad_complex"] = coordinates[""]
        new_infos["ad_description"] = coordinates["552,16"]
        new_infos["ad_equipment"] = coordinates[""]
        new_infos["ad_exterior"] = coordinates["760,16"]
        new_infos["ad_floors"] = coordinates[""]
        new_infos["ad_full_bathrooms"] = coordinates["304,120"]
        new_infos["ad_half_bathrooms"] = coordinates["336,120"]
        new_infos["ad_interior"] = coordinates["696,16"]
        new_infos["ad_location"] = coordinates["120,24"]
        new_infos["ad_parking"] = coordinates[""]
        new_infos["ad_price"] = coordinates["120,608"].gsub(/[.].*/, '').gsub(/[^0-9]/, '')
        new_infos["ad_services"] = coordinates[""]
        new_infos["ad_square_feet"] = coordinates["352,120"]
        new_infos["ad_status"] = coordinates["192,72"]
        new_infos["ad_subdivision"] = coordinates["256,16"]
        new_infos["ad_view"] = coordinates[""]
        new_infos["ad_waterfront"] = coordinates["504,104"]
        foreign_id = coordinates["168,56"]
        
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
        new_infos.merge(listing.infos).each{|k, v|
          @listings_output[foreign_id]["infos"][k] = [listing.infos[k], new_infos[k]]
        }

        new_infos["ad_title"] = []
        loop {
          title = ListingTitle.generate(listing, new_infos)
          new_infos["ad_title"] << title if !title.nil? and !title.empty? and title.length > 20
          break if new_infos["ad_title"].size >= 3
        }

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

        active << listing.id if (!(new_infos["ad_status"] =~ /^Active/).nil?) and !disable?(listing)
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
