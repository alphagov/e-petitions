require 'rails_helper'

RSpec.describe ActiveSupport::Cache::AtomicDalliStore do
  let(:options) do
    { namespace: "epets_test", expires_in: 2.seconds }
  end

  let(:client) { subject.dalli }
  let(:exception) { Dalli::DalliError.new }

  let(:ttl_key) { "epets_test:foo.ttl" }
  let(:ttl_set_args) { [ttl_key, "", 2.seconds, raw: true] }
  let(:ttl_get_args) { [ttl_key, raw: true] }
  let(:ttl_add_args) { [ttl_key, "", 10, raw: true] }

  around do |example|
    client.delete("epets_test:foo")
    client.delete("epets_test:foo.ttl")
    example.run
  end

  before do
    allow(client).to receive(:get).and_call_original
    allow(client).to receive(:set).and_call_original
    allow(client).to receive(:add).and_call_original
    allow(client).to receive(:delete).and_call_original
  end

  describe "#fetch" do
    context "when the cache is not set" do
      it "calls the block" do
        expect {
          |b| subject.fetch("foo", options, &b)
        }.to yield_control
      end

      it "writes the value to the cache" do
        expect {
          subject.fetch("foo", options) { "bar" }
        }.to change {
          client.get("epets_test:foo")
        }.from(nil).to("bar")
      end

      it "writes the TTL value to the cache" do
        expect {
          subject.fetch("foo", options) { "bar" }
        }.to change {
          client.get("epets_test:foo.ttl")
        }.from(nil).to("")
      end

      it "returns the value" do
        expect(subject.fetch("foo", options) { "bar" }).to eq("bar")
      end

      it "handles exceptions" do
        expect(subject.dalli).to receive(:set).with(*ttl_set_args).and_raise(exception)
        expect(subject.fetch("foo", options) { "bar" }).to eq("bar")
      end
    end

    context "when the cache is set" do
      before do
        subject.write("foo", "bar", options)
      end

      it "doesn't calls the block" do
        expect {
          |b| subject.fetch("foo", options, &b)
        }.not_to yield_control
      end

      it "returns the value" do
        expect(subject.fetch("foo", options) { "bar" }).to eq("bar")
      end

      it "handles exceptions when reading the lock" do
        expect(subject.dalli).to receive(:get).with(*ttl_get_args).and_raise(exception)
        expect(subject.fetch("foo", options) { "bar" }).to eq("bar")
      end

      it "handles exceptions when setting the lock" do
        client.delete(ttl_key)
        expect(subject.dalli).to receive(:add).with(*ttl_add_args).and_raise(exception)
        expect(subject.fetch("foo", options) { "bar" }).to eq("bar")
      end
    end
  end

  describe "#read" do
    context "when the cache is not set" do
      it "returns nil" do
        expect(subject.read("foo", options)).to be_nil
      end
    end

    context "when the cache is set" do
      before do
        subject.write("foo", "bar", options)
      end

      it "returns the value" do
        expect(subject.read("foo", options)).to eq("bar")
      end

      it "handles exceptions when reading the lock" do
        expect(subject.dalli).to receive(:get).with(*ttl_get_args).and_raise(exception)
        expect(subject.read("foo", options)).to eq("bar")
      end

      it "handles exceptions when setting the lock" do
        client.delete(ttl_key)
        expect(subject.dalli).to receive(:add).with(*ttl_add_args).and_raise(exception)
        expect(subject.read("foo", options)).to eq("bar")
      end
    end
  end

  describe "#write" do
    it "writes the value to the cache" do
      expect {
        subject.write("foo", "bar", options)
      }.to change {
        client.get("epets_test:foo")
      }.from(nil).to("bar")
    end

    it "writes the TTL value to the cache" do
      expect {
        subject.write("foo", "bar", options)
      }.to change {
        client.get("epets_test:foo.ttl")
      }.from(nil).to("")
    end

    it "handles exceptions when setting the TTL" do
      expect(subject.dalli).to receive(:set).with(*ttl_set_args).and_raise(exception)
      expect(subject.write("foo", "bar", options)).to be_falsey
    end
  end

  describe "#delete" do
    before do
      subject.write("foo", "bar", options)
    end

    it "deletes the value from the cache" do
      expect {
        subject.delete("foo", options)
      }.to change {
        client.get("epets_test:foo")
      }.from("bar").to(nil)
    end

    it "deletes the TTL value from the cache" do
      expect {
        subject.delete("foo", options)
      }.to change {
        client.get("epets_test:foo.ttl")
      }.from("").to(nil)
    end

    it "handles exceptions when deleting the TTL" do
      expect(subject.dalli).to receive(:delete).with(ttl_key).and_raise(exception)
      expect(subject.delete("foo", options)).to be_falsey
    end
  end
end
