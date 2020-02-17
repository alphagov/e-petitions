require 'rails_helper'

RSpec.describe NotifyTrendingDomainJob, type: :job do
  let(:rate_limits) { double(RateLimit) }
  let(:url) { "https://hooks.slack.com/services/account/channel/token" }
  let(:petition) { FactoryBot.create(:open_petition, action: "Do Stuff!") }

  let(:trending_domain) do
    FactoryBot.create(:trending_domain,
      petition: petition,
      domain: "example.com",
      count: 32,
      starts_at: "2019-03-31T16:00:00Z"
    )
  end

  before do
    allow(RateLimit).to receive(:first_or_create!).and_return(rate_limits)
    allow(rate_limits).to receive(:trending_items_notification_url).and_return(url)

    stub_request(:post, "https://hooks.slack.com/services/account/channel/token")
  end

  it "sends a notification to the Slack channel" do
    described_class.perform_now(trending_domain)

    message = "32 signatures between 5:00pm and 6:00pm on "
    message << "<https://moderate.petition.senedd.wales/admin/petitions/#{petition.id}|Do Stuff!> "
    message << "from <https://moderate.petition.senedd.wales/admin/petitions/#{petition.id}/signatures?q=%40example.com&window=2019-03-31T16%3A00%3A00Z|example.com>"

    body = { payload: { text: message }.to_json }.to_query

    expect(WebMock).to have_requested(:post, url).with(body: body)
  end
end
