require 'rails_helper'

RSpec.describe SignatureLogs do
  describe SignatureLogs::Log do
    let(:ip) { "192.168.1.1" }
    let(:time) { "[09/Apr/2019:23:00:16 +0000]" }
    let(:uri) { "/petitions/200000/signatures/new" }
    let(:request) { "GET #{uri} HTTP/1.1" }
    let(:agent) { "Mozilla/5.0" }

    subject(:log) { described_class.new(message) }

    context "when not running behind CloudFront" do
      let(:message) { %[#{ip} - - #{time} "#{request}" 200 19688 "-" "#{agent}" (via 10.0.7.171)] }

      it "parses a log line" do
        expect(log.ip_address).to eq("192.168.1.1")
        expect(log.timestamp).to eq(Time.utc(2019, 4, 9, 23, 0, 16))
        expect(log.method).to eq("GET")
        expect(log.uri).to eq("/petitions/200000/signatures/new")
        expect(log.agent).to eq("Mozilla/5.0")
      end
    end

    context "when running behind CloudFront" do
      let(:message) { %[#{ip}, 10.0.1.1 - - #{time} "#{request}" 200 19688 "-" "#{agent}" (via 10.0.7.171)] }

      it "parses a log line" do
        expect(log.ip_address).to eq("192.168.1.1")
        expect(log.timestamp).to eq(Time.utc(2019, 4, 9, 23, 0, 16))
        expect(log.method).to eq("GET")
        expect(log.uri).to eq("/petitions/200000/signatures/new")
        expect(log.agent).to eq("Mozilla/5.0")
      end
    end

    context "when a message is corrupted" do
      let(:message) { "foobar" }

      it "doesn't blow up" do
        expect(log.ip_address).to be_nil
        expect(log.timestamp).to be_nil
        expect(log.method).to be_nil
        expect(log.uri).to be_nil
        expect(log.agent).to be_nil
      end

      it "responds as blank" do
        expect(log).to be_blank
      end
    end
  end

  describe ".find" do
    let(:signature) { FactoryBot.create(:validated_signature) }
    subject { described_class.find(123) }

    before do
      allow(Signature).to receive(:find).with(123).and_return(signature)
    end

    it "finds the associated signature" do
      expect(subject.signature).to eq(signature)
    end
  end

  describe "#each" do
    let(:client) { double(Aws::CloudWatchLogs::Client) }
    let(:create_message) { %[192.168.1.1 - - [09/Apr/2019:23:00:16 +0000] "GET /petitions/200000/signatures/new HTTP/1.1" 200 5678 "-" "Mozilla/5.0" (via 10.0.7.171)] }
    let(:validate_message) { %[192.168.1.2 - - [09/Apr/2019:23:10:16 +0000] "GET /signatures/123/verify?token=abc123 HTTP/1.1" 200 1234 "-" "Mozilla/5.0" (via 10.0.7.171)] }

    let(:create_request) do
      {
        log_group_name: "nginx-access-logs",
        start_time: 1554850516000,
        end_time: 1554851116000,
        filter_pattern: "192.168.1.1",
        interleaved: true
      }
    end

    let(:create_response) do
      double(:response, events: [double(message: create_message), double(message: "foobar")])
    end

    let(:validate_request) do
      {
        log_group_name: "nginx-access-logs",
        start_time: 1554851116000,
        end_time: 1554851716000,
        filter_pattern: "192.168.1.2",
        interleaved: true
      }
    end

    let(:validate_response) do
      double(:response, events: [double(message: "foobar"), double(message: validate_message)])
    end

    let(:signature) do
      FactoryBot.create(
        :validated_signature,
        ip_address: "192.168.1.1",
        created_at: "2019-04-09T23:00:16Z",
        validated_ip: "192.168.1.2",
        validated_at: "2019-04-09T23:10:16Z"
      )
    end

    subject { described_class.find(123) }

    before do
      allow(Signature).to receive(:find).with(123).and_return(signature)
      allow(Aws::CloudWatchLogs::Client).to receive(:new).and_return(client)
      allow(client).to receive(:filter_log_events).with(create_request).and_return(create_response)
      allow(client).to receive(:filter_log_events).with(validate_request).and_return(validate_response)
    end

    it "yields the valid log lines" do
      expect { |b| subject.each(&b) }.to yield_successive_args(
        SignatureLogs::Log.new(create_message),
        SignatureLogs::Log.new(validate_message)
      )
    end
  end
end
