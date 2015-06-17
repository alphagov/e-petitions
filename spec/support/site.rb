RSpec.configure do |config|

  config.before(:suite) do
    Site.destroy_all
    Site.reload
  end

  config.before(:each) do |example|
    Site.destroy_all
    Site.reload
  end

end
