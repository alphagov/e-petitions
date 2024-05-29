RSpec.configure do |config|

  config.before(:suite) do
    Site.reset!
  end

  config.before(:each) do |example|
    Site.reset!
  end

end
