Before do
  if Petition.respond_to?(:remove_all_from_index!)
    Petition.remove_all_from_index!
  end
end

Before do
  default_url_options[:protocol] = 'https'
end

Before do
  Location.create!(code: 'GB', name: 'United Kingdom')
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
