namespace :grimes do
  desc "Scrape Heather Grimes' data."
  task :scrape => :environment do
    require 'scrape_utils'

    driver = Selenium::WebDriver.for :firefox
    driver.manage.timeouts.implicit_wait = 10
    customer = Customer.find_by_key("heather_grimes")

    url = "http://rentalhomepros.com/Membership.aspx"
    driver.get url

    xpath_un = "//*[@id=\"ctl00_BodyContainerPlaceHolder_UcLogin1_Login1_UserName\"]"
    driver.find_element(:xpath, xpath_un).send_keys "HeatherCGrimes@Yahoo.com"
    xpath_pw = "//*[@id=\"ctl00_BodyContainerPlaceHolder_UcLogin1_Login1_Password\"]"
    driver.find_element(:xpath, xpath_pw).send_keys "09031981"
    xpath_login = "//*[@id=\"ctl00_BodyContainerPlaceHolder_UcLogin1_Login1_LoginButton1\"]"
    driver.find_element(:xpath, xpath_login).click

    xpath_CL = "//*[@id=\"ctl00_BodyContainerPlaceHolder_UcSideNavBar1_SideBarNavTreen9\"]"
    driver.find_element(:xpath, xpath_CL).click

    active = []
    infos = {}
    total = driver.find_elements(:xpath, "/html/body/form/div[3]/div[2]/table/tbody/tr/td[2]/div[2]/div/table/tbody/tr[2]/td/div/table/tbody/tr[2]/td/table/tbody/tr/td[2]/select/option").count
    for i in (1..total)
      puts ",--"
      foreign_listing = driver.find_element(:xpath, "/html/body/form/div[3]/div[2]/table/tbody/tr/td[2]/div[2]/div/table/tbody/tr[2]/td/div/table/tbody/tr[2]/td/table/tbody/tr/td[2]/select/option[#{i}]")

      foreign_id = foreign_listing.attribute("value")
      puts "|Foreign ID: #{foreign_id}"
      listing = Listing.find_by_customer_id_and_foreign_id(customer.id, foreign_id)
      if listing.nil?
        listing = Listing.new
        listing.customer_id = customer.id
        listing.foreign_id = foreign_id
        listing.location_id = customer.location_id
        listing.sublocation_id = customer.sublocation_id
        listing.save
      end

      foreign_listing.click
      sleep(0.3)
      while infos == get_ad_info(driver)
        sleep(0.3)
      end
      infos = get_ad_info(driver)
      for key, val in infos
        value_update(listing, key, val)
      end
      listing.save
      puts "|#{listing.errors}" if !listing.errors.nil? and !listing.errors.empty?
      active << listing.id
      puts "`--"
    end
    driver.quit
    activate_new_listings(customer.id, active)
    deactivate_old_listings(customer.id, active)
  end

  def get_ad_info(driver)
    info = {}
    info["ad_price"] = get_element(driver, '//*[@id="divRent"]')
    info["ad_bedrooms"] = get_element(driver, '//*[@id="divBeds"]')
    info["ad_address"] = get_element(driver, '//*[@id="divAddress"]')
    info["ad_city"] = get_element(driver, '//*[@id="divCity"]')
    info["ad_state"] = get_element(driver, '//*[@id="divState"]')
    info["ad_title"] = [get_element(driver, '//*[@id="divHeadline"]')[0..69]]
    info["ad_body"] = get_element(driver, '//*[@id="divHTML"]')
    return info
  end

  def get_element(driver, xpath)
    data = ""
    retryable {
      Timeout::timeout(10){
        data = driver.find_element(:xpath, xpath).text
      }
    }
    return data
  end

  def retryable(options = {}, &block)
    opts = { :tries => 5, :on => Exception }.merge(options)

    retry_exception, retries = opts[:on], opts[:tries]

    begin
      return yield
    rescue => e
      print "Failed form submission. Retrying.\n"
      print "Error #{e.inspect}\n"
      sleep(3)
      retry if (retries -= 1) > 0
    end

    yield
  end
end
