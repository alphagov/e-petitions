Before do
  default_url_options[:protocol] = 'https'
end

Before do
  stub_api_request_for("CF991NA").to_return(api_response(:ok, "cardiff_south_and_penarth"))
  stub_api_request_for("CF991ZZ").to_return(api_response(:ok, "no_results"))
end

Before do
  RateLimit.create!(
    burst_rate: 10, burst_period: 60,
    sustained_rate: 20, sustained_period: 300,
    allowed_domains: "example.com", allowed_ips: "127.0.0.1"
  )
end

Before do
  Rails.cache.clear
end

After do
  Site.reload
end

Before('@welsh') do
  I18n.locale = :"cy-GB"
end

Before('~@welsh') do
  I18n.locale = :"en-GB"
end

Before('@admin') do
  Capybara.app_host = 'https://moderate.petition.senedd.wales'
  Capybara.default_host = 'https://moderate.petition.senedd.wales'
end

Before('~@admin') do
  Capybara.app_host = 'https://petition.senedd.wales'
  Capybara.default_host = 'https://petition.senedd.wales'
end

Before('@skip') do
  skip_this_scenario
end
