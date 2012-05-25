# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

Dir[File.join(File.dirname(__FILE__),'seeds','*.rb')].each do |f|
  puts "Seeding from #{ File.basename f }..."
  load f
  puts "Done."
end