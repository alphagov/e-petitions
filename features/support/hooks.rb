Before do
  default_url_options[:protocol] = 'https'
end

Before do
  Location.create!(code: 'GB', name: 'United Kingdom')
  Location.create!(code: 'US', name: 'United States')
end

Before do
  stub_api_request_for("SW1A1AA").to_return(api_response(:ok, "london_and_westminster"))
  stub_api_request_for("SW149RQ").to_return(api_response(:ok, "no_results"))
end

Before do
  RateLimit.create!(
    burst_rate: 10, burst_period: 60,
    sustained_rate: 20, sustained_period: 300,
    allowed_domains: "example.com", allowed_ips: "127.0.0.1"
  )
end

Before do
  ::RSpec::Mocks.setup
end

After do
  ::RSpec::Mocks.verify
ensure
  ::RSpec::Mocks.teardown
end

Before do
  Rails.cache.clear
end

After do
  Site.reload
  Parliament.reload
end

After do
  page.driver.options[:headers] = nil
end

After do
  ENV["INLINE_UPDATES"] = "true"
end

Before('@admin') do
  Capybara.app_host = 'https://moderate.petition.parliament.uk'
  Capybara.default_host = 'https://moderate.petition.parliament.uk'
end

Before('~@admin') do
  Capybara.app_host = 'https://petition.parliament.uk'
  Capybara.default_host = 'https://petition.parliament.uk'
end

Before('@skip') do
  skip_this_scenario
end

Before do
  ActiveRecord::FixtureSet.create_fixtures("#{::Rails.root}/spec/fixtures", ["rejection_reasons"])
end

After do
  ActiveRecord::FixtureSet.reset_cache
end

Before do
  Rails.application.env_config['action_dispatch.show_detailed_exceptions'] = false
end
