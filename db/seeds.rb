# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)i
#Miami
{
  'maf_elizabeth' => 'elizabeth@miamiapartmentfinders.com',
  'maf_ronda' => 'ronda@miamiapartmentfinders.com',
  'maf_paola' => 'paola@miamiapartmentfinders.com',
  'maf_luis' => 'luis@miamiapartmentfinders.com',
  'kangarent' => 'leads@kangarent.com',
  'casabellaboca' => 'john@casabellaboca.com',
  'bnrfn_kendall' => 'mmorsy@buynrentfreenow.com',
  'bnrfn_homestead' => 'nhozien@buynrentfreenow.com',
  'sea_rea_test' => 'brendan@leadadvo.com',
  'mdc_rea_test' => 'brendan@leadadvo.com',
  'gus_b' => 'gusbergamini@yahoo.com',
  'jennifer_homes' => 'jenniferhomes@gmail.com',
  'majestic_properties' => 'justinmrubin@gmail.com',
  'plumpads' => 'mike.thinking@gmail.com'
}.each{ |key, val|
  if Customer.where("key like ?", key).count == 0
    Customer.create({
      :email_address => val,
      :key => key,
      :craigslist_type => 'apa',
      :location_id => 1,
      :sublocation_id => 1
    })
    puts "Added customer #{key}, email #{val}"
  else
    puts "Customer #{key}, email #{val} exists"
  end
}

kanga_neighborhoods = [
  "Boynton Beach", "Boca Raton", "Coconut Creek", "Coral Springs", "Deerfield Beach", 
  "Delray Beach", "Jupiter", "Lake Park", "Lake Worth", "Palm Beach", "Palm Beach Gardens", 
  "North Palm Beach", "Royal Palm Beach", "Stuart", "Tequesta", "Wellington", "West Palm Beach"] * ", "
  kanga = [{:min_rent => 850, :max_rent => 1500, :has_photos => 1, :include_mls => 1, :featured => 1}]

  casa_neighborhoods = ["Boca Raton", "Deerfield Beach", "Delray Beach", "Highland Beach", "Hillsboro Beach", "Parkland"] * ", "

  maf = [
    {:min_beds => 1, :max_beds => 1, :min_rent => 1800, :max_rent => 2500, :has_photos => 1, :include_mls => 1},
    {:min_beds => 2, :max_beds => 2, :min_rent => 2000, :max_rent => 5000, :has_photos => 1, :include_mls => 1}
  ]
  elizabeth_neighborhoods = ["Miami Beach", "Brickell", "Surfside"] * ", "
  paola_neighborhoods     = [               "Brickell", "Coral Gables", "Coconut Grove", "Downtown Miami"] * ", "
  ronda_neighborhoods     = ["Miami Beach", "North Beach", "Bay Harbour"] * ", "
  luis_neighborhoods      = [               "Brickell", "Midtown Miami"] * ", "

  customers = [
    {:name => 'maf_elizabeth',
      :rj_id => '868f2445f9f09786e35f8a1b9356a417',
      :hoods => {:neighborhoods => elizabeth_neighborhoods},
      :filter => maf,
      :email => {:agent => "elizabeth@miamiapartmentfinders.com"},
      :location => Location.find_by_url("miami"),
      :sublocation => Sublocation.find_by_url("mdc")
  },

    {:name => 'maf_ronda',
      :rj_id => '868f2445f9f09786e35f8a1b9356a417',
      :hoods => {:neighborhoods => ronda_neighborhoods},
      :filter => maf,
      :email => {:agent => "ronda@miamiapartmentfinders.com"},
      :location => Location.find_by_url("miami"),
      :sublocation => Sublocation.find_by_url("mdc")
  },

    {:name => 'maf_paola',
      :rj_id => '868f2445f9f09786e35f8a1b9356a417',
      :hoods => {:neighborhoods => paola_neighborhoods},
      :filter => maf,
      :email => {:agent => "paola@miamiapartmentfinders.com"},
      :location => Location.find_by_url("miami"),
      :sublocation => Sublocation.find_by_url("mdc")
  },

    {:name => 'maf_luis',
      :rj_id => '868f2445f9f09786e35f8a1b9356a417',
      :hoods => {:neighborhoods => luis_neighborhoods},
      :filter => maf,
      :email => {:agent => "luis@miamiapartmentfinders.com"},
      :location => Location.find_by_url("miami"),
      :sublocation => Sublocation.find_by_url("mdc")
  },

    {:name => 'kangarent',
      :rj_id => '3b97f4ec544152dd3a79ca0c19b32aab',
      :hoods => {:neighborhoods => kanga_neighborhoods},
      :filter => kanga,
      :email => {:agent => "leads@kangarent.com"},
      :location => Location.find_by_url("miami"),
      :sublocation => Sublocation.find_by_url("pbc")
  },

    {:name => 'casabellaboca',
      :rj_id => 'e18a66e3f23c9d65e53072fcf0560542',
      :hoods => {:neighborhoods => casa_neighborhoods},
      :filter => [{:include_mls => 1, :featured => 1}],
      :email => {:agent => "john@casabellaboca.com"},
      :location => Location.find_by_url("miami"),
      :sublocation => Sublocation.find_by_url("pbc")
  },

    {:name => 'sea_rea_test',
      :rj_id => 'e18a66e3f23c9d65e53072fcf0560542',
      :hoods => {:neighborhoods => casa_neighborhoods},
      :filter => [{:include_mls => 1, :featured => 1}],
      :email => {:agent => "brendan@leadadvo.com"},
      :location => Location.find_by_url("seattle"),
      :sublocation => Sublocation.find_by_url("see")
  },

    {:name => 'mdc_rea_test',
      :rj_id => 'e18a66e3f23c9d65e53072fcf0560542',
      :hoods => {:neighborhoods => casa_neighborhoods},
      :filter => [{:include_mls => 1, :featured => 1}],
      :email => {:agent => "brendan@leadadvo.com"},
      :location => Location.find_by_url("miami"),
      :sublocation => Sublocation.find_by_url("mdc")
  }
  ]


  customers.each do |cst|
    customer = Customer.find_or_create_by_key_and_email_address(cst[:name], cst[:email][:agent])
    if customer && customer.valid?
      customer.customer_infos.create(:key => "rj_id", :value => cst[:rj_id])
      customer.customer_infos.create(:key => "neighborhoods", :value => cst[:hoods][:neighborhoods])
      customer.customer_infos.create(:key => "filter", :value => cst[:filter].to_json)
      customer.location_id = cst[:location].id
      customer.sublocation_id = cst[:sublocation].id
      customer.save
    end
  end
