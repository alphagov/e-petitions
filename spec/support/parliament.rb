RSpec.configure do |config|

  config.before(:suite) do
    Parliament.destroy_all
    Parliament.reload
  end

  config.before(:each) do |example|
    Parliament.destroy_all
    Parliament.reload
  end

end
