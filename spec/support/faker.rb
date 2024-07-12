RSpec.configure do |config|
  config.before(:all) { Faker::UniqueGenerator.clear }
end
