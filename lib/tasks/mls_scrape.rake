require 'selenium-webdriver'
require 'listing_title'
require 'uri'
#require 'scrape_utils'

namespace :scrape do
  desc "scrape NW mls"
  task :mls => :environment do
    @driver = Selenium::WebDriver.for :firefox
    @driver.manage.timeouts.implicit_wait = 30
    @driver.navigate.to "http://www.matrix.nwmls.com/DE.asp?ID=3837675446"
    @driver.find_elements(:tag_name, "option").reject{|op| op.attribute('value') != "109"}.first.click
   
    customer_key = "shannon_sea"
    begin customer_id = Customer.where(:key => customer_key).first.id rescue special_puts("#{c(red)}Customer Key (#{customer_key.to_s}) Not Found!#{ec}") end

    index = 0
    #Because I use the Next link's href at the end to decide if I continue the loop or not but, do the next click at the start.
    #I need to delay the click, avoiding it on the first 
    first = true
    #List of listings to be enabled
    active = []
    max_listings = @driver.find_elements(:css, "#_ctl0_m_pnlPagingSummaryTop b")[1].text.to_i

    begin
      print ",-----------------------------------------------------------------------\n"
      if !first
        @driver.script @driver.find_element(:link_text, "Next").attribute("href")
      else
        first = false
      end
     
      max_images = @driver.find_elements(:css, "span.d109m15 b")[1].text.to_i

      foreign_id = get_first_table(2,1)
      listings = Listing.where(:customer_id => customer_id, :foreign_id => foreign_id)
      (special_puts "Duplicate Listings Please Check Advo ID #{customer_id} RJ ID #{foreign_id}."; return) if !listings.nil? and listings.count > 1

      listing = listings.nil? ? nil : listings.first
      if !listing.nil? then pre_msg = "Old Listing Found for "
      else
        pre_msg = "#{c(green)}New Listing Found for "
        listing = Listing.new
        listing.customer_id = customer_id
        listing.foreign_id = foreign_id
        save = true
      end
      special_puts "#{pre_msg}#{customer_key}#{ec}"
      special_puts "MLX ID: #{foreign_id}"
      special_puts "Current listing is #{index += 1} of #{max_listings}"

      save = true if value_update(listing, :ad_address, get_first_table(1,0))
      save = true if value_update(listing, :ad_location, get_first_table(3,1).sub(/[0-9]* - /, ''))
      save = true if value_update(listing, :ad_price, get_first_table(6,1))

      save = true if value_update(listing, :ad_description, @driver.find_elements(:css, "td.d109m47")[0].text)

      save = true if value_update(listing, :ad_bedrooms, get_second_table(4,1))
      save = true if value_update(listing, :ad_bathrooms, get_second_table(4,3))
      save = true if value_update(listing, :ad_lot_size, get_second_table(5,5))

      if listing.title.nil?
        titles = (0..2).collect{
          ListingTitle.generate(listing)}
        save = true if value_update(listing, :ad_title, titles)
      end

      foreign_status = get_first_table(2,3)

      listing.save if save
      
      original_handle = @driver.window_handles[0]
      #########IMAGES########
      @driver.find_element(:link_text, "Open All").click
      @driver.switch_to.window @driver.window_handles[1]

      image_urls = @driver.find_elements(:xpath, "//img").collect{|img| img.attribute("src").sub(/Size=[0-9]/, "Size=4") }
      load_images(listing, image_urls)
      
      @driver.close
      @driver.switch_to.window original_handle

      if foreign_status == "Active" and !disable(listing)
        special_puts "Rental Status #{c(green)}Active #{ec}: #{foreign_status}"
        active << listing.id
      else
        special_puts "Rental Status #{c(red)}Inactive #{ec}: #{c(red)}#{foreign_status}#{ec}"
      end

      special_puts "Created/Updated Listing. Leadadvo ID #{listing.id}"
      print "`-----------------------------------------------------------------------\n"
      #TODO activate_listings(customer_id, active) if !@running
    end while !@driver.find_element(:link_text, "Next").attribute("href").nil?
    activate_listings(customer_id, active)
  end
end

def get_first_table (row, col)
  return @driver.find_elements(:css, "tr.d109m4 td.d109m3 table.d109m2 table.d109m2 tr")[row].find_elements(:tag_name, "td")[col].text
end

def get_second_table (row, col)
  return @driver.find_elements(:css, "td.d109m49 table.d109m2 tr")[row].find_elements(:tag_name, "td")[col].text
end

def print_elements #Test tools
  i=0
  j=0
  trs = @driver.find_elements(:css, "td.d109m49 table.d109m2 tr")
  trs = @driver.find_elements(:css, "tr.d109m4 td.d109m3 table.d109m2 table.d109m2 tr")
  for tr in trs
    tds = tr.find_elements(:tag_name, "td")
    break if tds[0].text.strip == "Listing Information"
    for td in tds 
      p "#{i} #{j} #{td.text}"
      j+=1
    end
    i+=1
    j=0
  end
end
