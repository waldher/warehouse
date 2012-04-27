def special_print(str) print "|#{str}" end 
def special_puts(str)  puts  "|#{str}" end

def c(fg,bg = nil)
  "#{fg ? "\x1b[38;5;#{fg}m" : ''}#{bg ? "\x1b[48;5;#{bg}m" : ''}" 
end 

def gray;   8 end
def l_blue; 6 end
def pink;   5 end
def blue;   4 end
def yellow; 3 end
def green;  2 end
def red;    1 end

def ec; "\x1b[0m" end

def value_update(listing, key_symbol, val)
  if !val.nil? and !val.empty? and listing.infos[key_symbol].to_s != val.to_s
    print_change(key_symbol, listing.infos[key_symbol], val.to_s)
    listing.infos[key_symbol] = val.to_s

    return true
  end
  return false
end

def print_change(symbol, was, now)
  print "|#{c(yellow)}#{":"if symbol.class == Symbol}#{symbol.to_s.ljust(21," ")} Changed#{ec}"
  print "  #{c(green)}Was #{c(blue)}<#{ec}#{was.to_s[0..59]}#{c(blue)}>#{ec} ".ljust(104,'.') + ".>"
  print "  #{c(green)}Now #{c(blue)}<#{ec}#{now.to_s[0..59]}#{c(blue)}>#{ec}\n"
end

def disable(listing)
  pre_msg = "#{c(red)}Disabled due to: "

  if listing.infos["ad_title"].nil? or listing.infos["ad_title"].empty?
    special_puts pre_msg + "no titles#{ec}"
    return true
  end

  image_urls = listing.ad_image_urls
  if image_urls.nil? or image_urls.empty?
    special_puts pre_msg + "empty images#{ec}"
    return true
  end 

  if listing.ad_image_urls.count < 4 
    special_puts pre_msg + "too few images#{ec}"
    return true
  end

  #In theory this should never be seen - it is a paperclip related error
  if listing.ad_image_urls.*(",").include?("/images/original/missing.png")
    special_puts pre_msg + "missing.png image#{ec}"
    return true
  end

  return false
end

def activate_listings(customer_id, active)
  special_puts "#{active.count} listings seen."
  activate = Listing.where("customer_id = ? and id in (?)", customer_id, active).each{|l| l.update_attribute(:foreign_active, true) }
  special_puts "#{activate} listings were activated."

  deactivate = Listing.where("customer_id = ? and id not in (?)", customer_id, active).each{|l| l.update_attribute(:foreign_active, false) }
  special_puts "#{deactivate} listing(s) were deactivated."
end

