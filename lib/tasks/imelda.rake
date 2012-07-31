require 'listing_title'
require 'scrape_utils'

namespace :imelda do
  desc "Scrape Imelda Gonzales' data."
  task :scrape => :environment do
    url = 'http://imeldagonzalez.sef.mlxchange.com/?r=776680776&id=3637323233313831.414'
    customer = Customer.where("key = 'arcadia_realty_llc'").first

    driver = Selenium::WebDriver.for :firefox
    page = driver.get(url)
    listings = []

    loop {
      driver.find_elements(:css, "table.PropertyDetailGridTableBorder").each{|table|
        images = driver.execute_script("return arguments[0].innerHTML;", table.find_element(:css, "#ResultsPhoto script")).scan(/http:[^']*/) rescue next
        fields = {}
        table.find_elements(:css, "table.PropertyDetailGridTable td").each{|td|
          fields[td.text.gsub(/:.*/,'').downcase] = td.text.gsub(/[^:]*:[^A-Za-z0-9]*/,'').strip
        }

        listing = Listing.where("foreign_id", fields["ml number"]).first
        if listing.nil?
          listing = Listing.new
          listing.customer_id = customer.id
          listing.foreign_id = fields["ml number"]
          listing.craigslist_type = 'apa'
          listing.location_id = customer.location.id
          listing.sublocation_id = customer.sublocation.id
        end
        new_infos = {}
        new_infos["ad_address"] = fields["address"]
        new_infos["ad_price"] = fields["list price"]
        new_infos["ad_location"] = fields["city"]
        new_infos["ad_bedrooms"] = fields["br"].to_i
        new_infos["ad_bathrooms"] = fields["fb"] + (fields["hb"] == "0" ? "" : "0.5")
        new_infos["ad_year_built"] = fields["year built"]
        new_infos["ad_description"] = fields["remarks"]
        listing.infos = new_infos

        titles = []
        (0..15).each{
          title = ListingTitle.generate(listing, new_infos)
          if !title.nil? and !title.empty? and title.length > 20
            titles << title
          end
          break if titles.count >= 3
        }
        new_infos["ad_title"] = titles if !titles.nil? and !titles.empty?

        listing.infos = new_infos
        listing.save

        images.uniq!
        load_images(listing, images)
      }

      begin
        next_link = driver.find_element(:partial_link_text, "Next")
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        break
      end
      if next_link
        page = next_link.click
      else
        break
      end
    }

    driver.quit
  end
end
