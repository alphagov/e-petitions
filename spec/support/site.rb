RSpec.configure do |config|

  config.before(:suite) do
    Site.destroy_all
    Site.reset
  end

  config.before(:each) do |example|
    Site.destroy_all
    Site.reset
  end

end
