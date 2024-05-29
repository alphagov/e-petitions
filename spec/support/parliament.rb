RSpec.configure do |config|

  config.before(:suite) do
    Parliament.reset!(government: "TBC", opening_at: 2.weeks.ago)
  end

  config.before(:each) do |example|
    Parliament.reset!(government: "TBC", opening_at: 2.weeks.ago)
  end

end
