RSpec.configure do |config|
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)

  config.before(:each) do
    ActionMailer::Base.deliveries.clear
  end
end
