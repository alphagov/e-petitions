RSpec.configure do |config|
  config.after do
    Admin::Current.user = nil
  end
end
