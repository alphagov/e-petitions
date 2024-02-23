Before do
  default_url_options[:protocol] = 'https'
end

Before do
  Location.create!(code: 'GB', name: 'United Kingdom')
  Location.create!(code: 'US', name: 'United States')

  Region.create!(external_id: "113", name: "London", ons_code: "H")

  Constituency.create!(
    name: "Cities of London and Westminster",
    slug: "cities-of-london-and-westminster",
    external_id: "3415", ons_code: "E14000639",
    mp_id: "1405", mp_name: "Rt Hon Mark Field MP",
    mp_date: "2001-06-07", party: "Conservative",
    example_postcode: "W1H5TN", region_id: "113"
  )
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

Before do
  OmniAuth.config.test_mode = true

  OmniAuth.config.on_failure = Proc.new { |env|
    OmniAuth::FailureEndpoint.new(env).redirect_to_failure
  }
end

After do
  OmniAuth.config.mock_auth[:example] = nil
  OmniAuth.config.test_mode = false
end
