require 'selenium-webdriver'
require 'listing_title'
require 'uri'

def gray;   8 end
def l_blue; 6 end
def pink;   5 end
def blue;   4 end
def yellow; 3 end
def green;  2 end
def red;    1 end
def c( fg, bg = nil ); "#{fg ? "\x1b[38;5;#{fg}m" : ''}#{bg ? "\x1b[48;5;#{bg}m" : ''}" end
def ec; "\x1b[0m"; end
def special_puts(string) puts "|#{string}" end

def scrape(info)
  @driver = Selenium::WebDriver.for :firefox
  @driver.manage.timeouts.implicit_wait = 30
  @driver.navigate.to "http://www.matrix.nwmls.com/DE.asp?ID=3837675446"
  @driver.find_elements(:tag_name, "option").reject{|op| op.attribute('value') != "109"}.first.click
 
  customer_key = info[:key]
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
      listing.manual_enabled = true
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
        ListingTitle.generate(
          :bedrooms => listing.infos[:ad_bedrooms].to_i,
          :location => listing.infos[:ad_location],
          :type => "",
          :amenities => "")}.reject{|title| title.length < 20}.join(",")
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

def get_first_table (row, col)
  return @driver.find_elements(:css, "tr.d109m4 td.d109m3 table.d109m2 table.d109m2 tr")[row].find_elements(:tag_name, "td")[col].text
end

def get_second_table (row, col)
  return @driver.find_elements(:css, "td.d109m49 table.d109m2 tr")[row].find_elements(:tag_name, "td")[col].text
end

def value_update(listing, key_symbol, val)
  if !val.nil? and !val.to_s.empty? and listing.infos[key_symbol].to_s != val.to_s
    print_change(key_symbol, listing.infos[key_symbol], val)
    listing.infos[key_symbol] = val.to_s
    return true
  end 
  return false
end 

def print_change(symbol, was, now)
  print "|#{c(yellow)}#{symbol.to_s.ljust(20," ")} Changed#{ec}"
  print "  Was #{c(blue)}<#{ec}#{was.to_s[0..100]}#{c(blue)}>#{ec} "
  print "  #{c(green)}Now #{c(blue)}<#{ec}#{now.to_s[0..100]}#{c(blue)}>#{ec}\n"
end

def activate_listings(customer_id, active)
  special_puts "#{active.count} listings seen."
  activate = Listing.where("customer_id = ? and id in (?)", customer_id, active).update_all("foreign_active = 't'")
  special_puts "#{activate} listings were activated."

  deactivate = Listing.where("customer_id = ? and id not in (?)", customer_id, active).update_all("foreign_active = 'f'")
  special_puts "#{deactivate} listing(s) were deactivated."
end

def disable(listing)
  if listing.infos[:ad_title].nil? or listing.infos[:ad_title].empty?
    special_puts "#{c(red)}Disabled due to empty title#{ec}"
    return true
  end

  image_urls = listing.ad_image_urls
  if image_urls.nil? or image_urls.empty?
    special_puts "#{c(red)}Disabled due to empty images#{ec}"
    return true
  end

  #In theory this should never be seen
  if image_urls.*(",").include?("/images/original/missing.png")
    special_puts "#{c(red)}Disabled due to missing.png image#{ec}"
    return true
  end
  return false
end

@@connections = {}
def load_images(listing, image_urls)
  #Assumption being, images never change.
  if !image_urls.empty? and listing.ad_image_urls.empty?

    for photo_uri in image_urls
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
            path = urisplit[2..-2] * "/" + "?" + urisplit[-1]
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
            special_puts "#{c(red)}Attempt #{6 - attempts} failed: #{e.inspect}#{ec}\n#{e.backtrace.join("\n")}"
            attempts -= 1
          end
        end

      end
    end

    listing.ad_image_urls.each{|url| special_puts url}
  end
end

def in_memory_file(data, pathname)
  #load up some data
  file = StringIO.new(data)

  #tell the class that it knows about a "name" property,
  #and assign the filename to it
  file.class.class_eval { attr_accessor :original_filename }
  file.original_filename = pathname

  file.class.class_eval { attr_accessor :content_type }
  file.content_type = "image/jpeg }"

  #FPDF uses the rindex and [] funtions on the "filename",
  #so we'll make our in-memory file object act like a filename
  #with respect to these functions:
  def file.rindex arg
    name.rindex arg
  end

  #this same pattern could be used to add other metadata
  #to the file (e.g., creation time)
  def file.[] arg
    name[arg]
  end

  #change open so that it follows the formal behavior
  #of the original (call a block with data, return
  #the file-like object, etc.) but alter it so that
  #it doesn't create a new instance and can be
  #called multiple times (rewind)
  def file.open(*mode, &block)
    self.rewind
    block.call(self) if block
    return self
  end

  return file
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
