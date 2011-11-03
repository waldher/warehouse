# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)i
#Miami
if Location.where("name like 'FL%'").count == 0
  puts "Creating Locations"
  location = Location.create({:name => "FL - South Florida", :enabled => true})

  Sublocation.create({:name => "miami / dade", :location_id => location.id}) 
  Sublocation.create({:name => "broward county", :location_id => location.id}) 
  Sublocation.create({:name => "palm beach county", :location_id => location.id})
end 

{
  'maf_elizabeth' => 'elizabeth@miamiapartmentfinders.com',
  'maf_ronda' => 'ronda@miamiapartmentfinders.com',
  'maf_paola' => 'paola@miamiapartmentfinders.com',
  'kangarent' => 'leads@kangarent.com',
  'casabellaboca' => 'john@casabellaboca.com',
  'plumpads' => 'mike.thinking@gmail.com'
}.each{ |key, val|
  if Customer.where("key like ?", key).count == 0
    Customer.create({
      :email_address => val,
      :key => key,
      :craigslist_type => 'apa'
    })
    puts "Added customer #{key}, email #{val}"
  else
    puts "Customer #{key}, email #{val} exists"
  end
}


