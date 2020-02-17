require 'rails_helper'

RSpec.describe NotifyTrendingIpJob, type: :job do
  let(:geoip_db_path) { "/path/to/GeoLite2-Country.mmdb" }
  let(:geoip_db) { double(:geoip_db) }
  let(:geoip_result) { double(:geoip_result) }
  let(:geoip_country) { double(:geoip_country) }

  let(:rate_limits) { double(RateLimit) }
  let(:url) { "https://hooks.slack.com/services/account/channel/token" }
  let(:petition) { FactoryBot.create(:open_petition, action: "Do Stuff!") }

  let(:trending_ip) do
    FactoryBot.create(:trending_ip,
      petition: petition,
      ip_address: "127.0.0.1",
      country_code: "GB",
      count: 32,
      starts_at: "2019-03-31T16:00:00Z"
    )
  end

  before do
    allow(MaxMindDB).to receive(:new).with(geoip_db_path).and_return(geoip_db)
    allow(geoip_db).to receive(:lookup).and_return(geoip_result)
    allow(geoip_result).to receive(:found?).and_return(true)
    allow(geoip_result).to receive(:country).and_return(geoip_country)
    allow(geoip_country).to receive(:iso_code).and_return("GB")

    allow(RateLimit).to receive(:first_or_create!).and_return(rate_limits)
    allow(rate_limits).to receive(:trending_items_notification_url).and_return(url)

    stub_request(:post, "https://hooks.slack.com/services/account/channel/token")
  end

  it "sends a notification to the Slack channel" do
    described_class.perform_now(trending_ip)

    message = "32 signatures between 5:00pm and 6:00pm on "
    message << "<https://moderate.petition.senedd.wales/admin/petitions/#{petition.id}|Do Stuff!> "
    message << "from <https://moderate.petition.senedd.wales/admin/petitions/#{petition.id}/signatures?q=127.0.0.1&window=2019-03-31T16%3A00%3A00Z|127.0.0.1>"

    body = { payload: { text: message }.to_json }.to_query

    expect(WebMock).to have_requested(:post, url).with(body: body)
  end
end
