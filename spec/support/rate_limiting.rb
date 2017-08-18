RSpec.configure do |config|
  config.before(:each) do
    RateLimit.create!(
      burst_rate: 10, burst_period: 60,
      sustained_rate: 20, sustained_period: 300,
      allowed_domains: "example.com", allowed_ips: "127.0.0.1"
    )
  end
end
