Before do
  default_url_options[:protocol] = 'https'
end

Before do
  FactoryBot.create(:constituency, :cardiff_south_and_penarth)
  FactoryBot.create(:postcode, :cardiff_south_and_penarth)
  FactoryBot.create(:member, :cardiff_south_and_penarth)
end

Before do
  RateLimit.create!(
    burst_rate: 10, burst_period: 60,
    sustained_rate: 20, sustained_period: 300,
    allowed_domains: "example.com", allowed_ips: "127.0.0.1"
  )
end

Before do
  stub_request(:post, NotifyMock.url).to_rack(NotifyMock.app)
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
end

Before('@welsh') do
  I18n.locale = :"cy-GB"
end

Before('~@welsh') do
  I18n.locale = :"en-GB"
end

Before('@admin') do
  Capybara.app_host = 'https://moderate.petitions.senedd.wales'
  Capybara.default_host = 'https://moderate.petitions.senedd.wales'
end

Before('~@admin') do
  Capybara.app_host = 'https://petitions.senedd.wales'
  Capybara.default_host = 'https://petitions.senedd.wales'
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
