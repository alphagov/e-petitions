require "notify_mock"

RSpec.configure do |config|
  config.before(:each) do |example|
    unless example.metadata[:notify] == false
      stub_request(:post, NotifyMock.url).to_rack(NotifyMock.app)
    end
  end
end
