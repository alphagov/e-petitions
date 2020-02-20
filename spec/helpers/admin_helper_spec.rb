require 'rails_helper'

RSpec.describe AdminHelper, type: :helper do
  describe "#admin_petition_facets_for_select" do
    let(:selected) { "open" }

    let(:facets) do
      {
        all: 1, collecting_sponsors: 2, in_moderation: 3,
        recently_in_moderation: 4, nearly_overdue_in_moderation: 5,
        overdue_in_moderation: 6, tagged_in_moderation: 7, untagged_in_moderation: 8,
        open: 9, referred: 10, rejected: 11, hidden: 12,
        awaiting_debate_date: 13, with_debate_outcome: 14,
        in_debate_queue: 15
      }
    end

    subject { helper.admin_petition_facets_for_select(facets, selected) }

    it "generates the correct number of options" do
      expect(subject).to have_css("option", count: 15)
    end

    it "generates the correct option for 'all'" do
      expect(subject).to have_css("option:nth-of-type(1)[value='all']", text: "All petitions (1)")
    end

    it "generates the correct option for 'collecting_sponsors'" do
      expect(subject).to have_css("option:nth-of-type(2)[value='collecting_sponsors']", text: "Collecting sponsors (2)")
    end

    it "generates the correct option for 'in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(3)[value='in_moderation']", text: "Awaiting moderation (3)")
    end

    it "generates the correct option for 'recently_in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(4)[value='recently_in_moderation']", text: "Awaiting moderation - recent (4)")
    end

    it "generates the correct option for 'nearly_overdue_in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(5)[value='nearly_overdue_in_moderation']", text: "Awaiting moderation - nearly overdue (5)")
    end

    it "generates the correct option for 'overdue_in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(6)[value='overdue_in_moderation']", text: "Awaiting moderation - overdue (6)")
    end

    it "generates the correct option for 'tagged_in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(7)[value='tagged_in_moderation']", text: "Awaiting moderation - tagged (7)")
    end

    it "generates the correct option for 'untagged_in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(8)[value='untagged_in_moderation']", text: "Awaiting moderation - untagged (8)")
    end

    it "generates the correct option for 'open'" do
      expect(subject).to have_css("option:nth-of-type(9)[value='open']", text: "Open (9)")
    end

    it "generates the correct option for 'referred'" do
      expect(subject).to have_css("option:nth-of-type(10)[value='referred']", text: "Referred (10)")
    end

    it "generates the correct option for 'rejected'" do
      expect(subject).to have_css("option:nth-of-type(11)[value='rejected']", text: "Rejected (11)")
    end

    it "generates the correct option for 'hidden'" do
      expect(subject).to have_css("option:nth-of-type(12)[value='hidden']", text: "Hidden (12)")
    end

    it "generates the correct option for 'awaiting_debate_date'" do
      expect(subject).to have_css("option:nth-of-type(13)[value='awaiting_debate_date']", text: "Awaiting a debate in parliament (13)")
    end

    it "generates the correct option for 'with_debate_outcome'" do
      expect(subject).to have_css("option:nth-of-type(14)[value='with_debate_outcome']", text: "Has been debated in parliament (14)")
    end

    it "generates the correct option for 'in_debate_queue'" do
      expect(subject).to have_css("option:nth-of-type(15)[value='in_debate_queue']", text: "In debate queue (15)")
    end

    it "marks the correct option as selected" do
      expect(subject).to have_css("option[value='open'][selected]")
    end
  end

  describe "#admin_invalidation_facets_for_select" do
    let(:selected) { "running" }

    let(:facets) do
      { all: 1, completed: 2, cancelled: 3, enqueued: 4, pending: 5, running: 6 }
    end

    subject { helper.admin_invalidation_facets_for_select(facets, selected) }

    it "generates the correct number of options" do
      expect(subject).to have_css("option", count: 6)
    end

    it "generates the correct option for 'all'" do
      expect(subject).to have_css("option:nth-of-type(1)[value='all']", text: "All invalidations (1)")
    end

    it "generates the correct option for 'completed'" do
      expect(subject).to have_css("option:nth-of-type(2)[value='completed']", text: "Completed invalidations (2)")
    end

    it "generates the correct option for 'cancelled'" do
      expect(subject).to have_css("option:nth-of-type(3)[value='cancelled']", text: "Cancelled invalidations (3)")
    end

    it "generates the correct option for 'pending'" do
      expect(subject).to have_css("option:nth-of-type(5)[value='pending']", text: "Pending invalidations (5)")
    end

    it "generates the correct option for 'enqueued'" do
      expect(subject).to have_css("option:nth-of-type(4)[value='enqueued']", text: "Enqueued invalidations (4)")
    end

    it "generates the correct option for 'running'" do
      expect(subject).to have_css("option:nth-of-type(6)[value='running']", text: "Running invalidations (6)")
    end

    it "marks the correct option as selected" do
      expect(subject).to have_css("option[value='running'][selected]")
    end
  end

  describe "#selected_tags" do
    before do
      params[:tags] = ["foo", nil, "0", "1", 2]
    end

    it "sanitizes the tags param" do
      expect(helper.selected_tags).to eq([1, 2])
    end
  end

  describe "#trending_domains" do
    let(:rate_limit) { double(:rate_limit) }
    let(:allowed_domains_list) { [/\Afoo.com\z/] }
    let(:now) { Time.current.beginning_of_minute }

    let(:domains) do
      { "foo.com" => 2, "bar.com" => 1 }
    end

    before do
      expect(Signature).to receive(:trending_domains).with(args).and_return(domains)
      expect(RateLimit).to receive(:first_or_create!).and_return(rate_limit)
      expect(rate_limit).to receive(:allowed_domains_list).and_return(allowed_domains_list)
    end

    around do |example|
      travel_to(now) { example.run }
    end

    context "with the default arguments" do
      let(:args) do
        { since: 1.hour.ago, limit: 40 }
      end

      subject do
        helper.trending_domains
      end

      it "returns non-allowed trending domains" do
        expect(subject).to eq([["bar.com", 1]])
      end
    end

    context "when overriding the since argument" do
      let(:args) do
        { since: 2.hours.ago, limit: 40 }
      end

      subject do
        helper.trending_domains(since: 2.hours.ago)
      end

      it "returns non-allowed trending domains" do
        expect(subject).to eq([["bar.com", 1]])
      end
    end

    context "when overriding the limit argument" do
      let(:args) do
        { since: 1.hour.ago, limit: 50 }
      end

      subject do
        helper.trending_domains(limit: 20)
      end

      it "returns non-allowed trending domains" do
        expect(subject).to eq([["bar.com", 1]])
      end
    end
  end

  describe "#trending_domains?" do
    let(:rate_limit) { double(:rate_limit) }
    let(:allowed_domains_list) { [/\Afoo.com\z/] }

    before do
      expect(Signature).to receive(:trending_domains).and_return(domains)
      expect(RateLimit).to receive(:first_or_create!).and_return(rate_limit)
      expect(rate_limit).to receive(:allowed_domains_list).and_return(allowed_domains_list)
    end

    context "when there are non-allowed trending domains" do
      let(:domains) do
        { "foo.com" => 2, "bar.com" => 1 }
      end

      subject do
        helper.trending_domains?
      end

      it "returns true" do
        expect(subject).to eq(true)
      end
    end

    context "when there aren't any non-allowed trending domains" do
      let(:domains) do
        { "foo.com" => 2 }
      end

      subject do
        helper.trending_domains?
      end

      it "returns false" do
        expect(subject).to eq(false)
      end
    end
  end

  describe "#trending_ips" do
    let(:rate_limit) { double(:rate_limit) }
    let(:allowed_ips_list) { [IPAddr.new("192.168.1.1")] }
    let(:now) { Time.current.beginning_of_minute }

    let(:ips) do
      { "192.168.1.1" => 2, "10.0.1.1" => 1 }
    end

    before do
      expect(Signature).to receive(:trending_ips).with(args).and_return(ips)
      expect(RateLimit).to receive(:first_or_create!).and_return(rate_limit)
      expect(rate_limit).to receive(:allowed_ips_list).and_return(allowed_ips_list)
    end

    around do |example|
      travel_to(now) { example.run }
    end

    context "with the default arguments" do
      let(:args) do
        { since: 1.hour.ago, limit: 40 }
      end

      subject do
        helper.trending_ips
      end

      it "returns non-allowed trending IP addresses" do
        expect(subject).to eq([["10.0.1.1", 1]])
      end
    end

    context "when overriding the since argument" do
      let(:args) do
        { since: 2.hours.ago, limit: 40 }
      end

      subject do
        helper.trending_ips(since: 2.hours.ago)
      end

      it "returns non-allowed trending IP addresses" do
        expect(subject).to eq([["10.0.1.1", 1]])
      end
    end

    context "when overriding the limit argument" do
      let(:args) do
        { since: 1.hour.ago, limit: 50 }
      end

      subject do
        helper.trending_ips(limit: 20)
      end

      it "returns non-allowed trending IP addresses" do
        expect(subject).to eq([["10.0.1.1", 1]])
      end
    end
  end

  describe "#trending_ips?" do
    let(:rate_limit) { double(:rate_limit) }
    let(:allowed_ips_list) { [IPAddr.new("192.168.1.1")] }

    before do
      expect(Signature).to receive(:trending_ips).and_return(ips)
      expect(RateLimit).to receive(:first_or_create!).and_return(rate_limit)
      expect(rate_limit).to receive(:allowed_ips_list).and_return(allowed_ips_list)
    end

    context "when there are non-allowed trending IP addresses" do
      let(:ips) do
        { "192.168.1.1" => 2, "10.0.1.1" => 1 }
      end

      subject do
        helper.trending_ips?
      end

      it "returns true" do
        expect(subject).to eq(true)
      end
    end

    context "when there aren't any non-allowed trending IP addresses" do
      let(:ips) do
        { "192.168.1.1" => 2 }
      end

      subject do
        helper.trending_ips?
      end

      it "returns false" do
        expect(subject).to eq(false)
      end
    end
  end
end
