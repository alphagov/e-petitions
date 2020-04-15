RSpec.configure do |config|
  config.around(:each) do |example|
    I18n.with_locale(:"en-GB") { example.run }
  end
end
