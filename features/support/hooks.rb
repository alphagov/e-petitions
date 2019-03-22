Before do
  default_url_options[:protocol] = 'https'
end

Before do
  Location.create!(code: 'GB', name: 'United Kingdom')
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

After do
  Site.reload
  Parliament.reload
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
