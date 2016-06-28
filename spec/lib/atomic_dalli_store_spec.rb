require 'rails_helper'

RSpec.describe ActiveSupport::Cache::AtomicDalliStore do
  let(:options) do
    { namespace: "epets_test", expires_in: 5.minutes }
  end

  around do |example|
    subject.with do |client|
      @client = client
      @client.delete("epets_test:foo")
      @client.delete("epets_test:foo.ttl")

      example.run
    end
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
          @client.get("epets_test:foo")
        }.from(nil).to("bar")
      end

      it "writes the TTL value to the cache" do
        expect {
          subject.fetch("foo", options) { "bar" }
        }.to change {
          @client.get("epets_test:foo.ttl")
        }.from(nil).to("")
      end

      it "returns the value" do
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
    end
  end

  describe "#read" do
    context "when the cache is not set" do
      it "returns nil" do
        expect(subject.read("foo")).to be_nil
      end
    end

    context "when the cache is set" do
      before do
        subject.write("foo", "bar", options)
      end

      it "returns the value" do
        expect(subject.read("foo", options)).to eq("bar")
      end
    end
  end

  describe "#write" do
    it "writes the value to the cache" do
      expect {
        subject.write("foo", "bar", options)
      }.to change {
        @client.get("epets_test:foo")
      }.from(nil).to("bar")
    end

    it "writes the TTL value to the cache" do
      expect {
        subject.write("foo", "bar", options)
      }.to change {
        @client.get("epets_test:foo.ttl")
      }.from(nil).to("")
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
        @client.get("epets_test:foo")
      }.from("bar").to(nil)
    end

    it "deletes the TTL value from the cache" do
      expect {
        subject.delete("foo", options)
      }.to change {
        @client.get("epets_test:foo.ttl")
      }.from("").to(nil)
    end
  end
end
