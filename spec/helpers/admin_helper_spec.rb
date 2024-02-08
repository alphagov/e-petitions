require 'rails_helper'

RSpec.describe AdminHelper, type: :helper do
  describe "#admin_petition_facets_for_select" do
    let(:selected) { "open" }

    let(:facets) do
      {
        all: 1, collecting_sponsors: 2, flagged: 3, dormant: 4, in_moderation: 5,
        recently_in_moderation: 6, nearly_overdue_in_moderation: 7,
        overdue_in_moderation: 8, tagged_in_moderation: 9, untagged_in_moderation: 10,
        open: 11, closed: 12, rejected: 13, hidden: 14, stopped: 15,
        awaiting_response: 16, with_response: 17, awaiting_debate: 18,
        debated: 19
      }
    end

    subject { helper.admin_petition_facets_for_select(facets, selected) }

    it "generates the correct number of options" do
      expect(subject).to have_css("option", count: 19)
    end

    it "generates the correct option for 'all'" do
      expect(subject).to have_css("option:nth-of-type(1)[value='all']", text: "All petitions (1)")
    end

    it "generates the correct option for 'collecting_sponsors'" do
      expect(subject).to have_css("option:nth-of-type(2)[value='collecting_sponsors']", text: "Collecting sponsors (2)")
    end

    it "generates the correct option for 'flagged'" do
      expect(subject).to have_css("option:nth-of-type(3)[value='flagged']", text: "Flagged (3)")
    end

    it "generates the correct option for 'dormant'" do
      expect(subject).to have_css("option:nth-of-type(4)[value='dormant']", text: "Dormant (4)")
    end

    it "generates the correct option for 'in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(5)[value='in_moderation']", text: "Awaiting moderation (5)")
    end

    it "generates the correct option for 'recently_in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(6)[value='recently_in_moderation']", text: "Awaiting moderation - recent (6)")
    end

    it "generates the correct option for 'nearly_overdue_in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(7)[value='nearly_overdue_in_moderation']", text: "Awaiting moderation - nearly overdue (7)")
    end

    it "generates the correct option for 'overdue_in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(8)[value='overdue_in_moderation']", text: "Awaiting moderation - overdue (8)")
    end

    it "generates the correct option for 'tagged_in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(9)[value='tagged_in_moderation']", text: "Awaiting moderation - tagged (9)")
    end

    it "generates the correct option for 'untagged_in_moderation'" do
      expect(subject).to have_css("option:nth-of-type(10)[value='untagged_in_moderation']", text: "Awaiting moderation - untagged (10)")
    end

    it "generates the correct option for 'open'" do
      expect(subject).to have_css("option:nth-of-type(11)[value='open']", text: "Open (11)")
    end

    it "generates the correct option for 'closed'" do
      expect(subject).to have_css("option:nth-of-type(12)[value='closed']", text: "Closed (12)")
    end

    it "generates the correct option for 'rejected'" do
      expect(subject).to have_css("option:nth-of-type(13)[value='rejected']", text: "Rejected (13)")
    end

    it "generates the correct option for 'hidden'" do
      expect(subject).to have_css("option:nth-of-type(14)[value='hidden']", text: "Hidden (14)")
    end

    it "generates the correct option for 'hidden'" do
      expect(subject).to have_css("option:nth-of-type(15)[value='stopped']", text: "Stopped (15)")
    end

    it "generates the correct option for 'awaiting_response'" do
      expect(subject).to have_css("option:nth-of-type(16)[value='awaiting_response']", text: "Awaiting a government response (16)")
    end

    it "generates the correct option for 'with_response'" do
      expect(subject).to have_css("option:nth-of-type(17)[value='with_response']", text: "With a government response (17)")
    end

    it "generates the correct option for 'awaiting_debate'" do
      expect(subject).to have_css("option:nth-of-type(18)[value='awaiting_debate']", text: "Awaiting a debate in parliament (18)")
    end

    it "generates the correct option for 'debated'" do
      expect(subject).to have_css("option:nth-of-type(19)[value='debated']", text: "Has been debated in parliament (19)")
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

  describe "#selected_depts" do
    before do
      params[:depts] = ["foo", nil, "0", "1", 2]
    end

    it "sanitizes the depts param" do
      expect(helper.selected_depts).to eq([1, 2])
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
