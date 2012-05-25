begin
  RSpec::Core::RakeTask.new(:spec_no_rails) do |t|
    t.pattern = 'spec_no_rails/**/*.rb'
  end
rescue Exception => e
 # staging or production does not know about rspec
end
