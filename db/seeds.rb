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
  'gus_b' => 'GusBergamini@yahoo.com',
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
