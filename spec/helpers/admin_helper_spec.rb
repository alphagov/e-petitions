require 'rails_helper'

RSpec.describe AdminHelper, type: :helper do
  describe "#admin_petition_facets_for_select" do
    let(:selected) { "open" }

    let(:facets) do
      {
        all: 1, collecting_sponsors: 2, in_moderation: 3, open: 4,
        closed: 5, rejected: 6, hidden: 7, awaiting_response: 8,
        with_response: 9, awaiting_debate_date: 10,
        with_debate_outcome: 11, in_debate_queue: 12
      }
    end

    subject { helper.admin_petition_facets_for_select(facets, selected) }

    it "generates the correct number of options" do
      expect(subject).to have_css("option", count: 12)
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

    it "generates the correct option for 'open'" do
      expect(subject).to have_css("option:nth-of-type(4)[value='open']", text: "Open (4)")
    end

    it "generates the correct option for 'closed'" do
      expect(subject).to have_css("option:nth-of-type(5)[value='closed']", text: "Closed (5)")
    end

    it "generates the correct option for 'rejected'" do
      expect(subject).to have_css("option:nth-of-type(6)[value='rejected']", text: "Rejected (6)")
    end

    it "generates the correct option for 'hidden'" do
      expect(subject).to have_css("option:nth-of-type(7)[value='hidden']", text: "Hidden (7)")
    end

    it "generates the correct option for 'awaiting_response'" do
      expect(subject).to have_css("option:nth-of-type(8)[value='awaiting_response']", text: "Awaiting a government response (8)")
    end

    it "generates the correct option for 'with_response'" do
      expect(subject).to have_css("option:nth-of-type(9)[value='with_response']", text: "With a government response (9)")
    end

    it "generates the correct option for 'awaiting_debate_date'" do
      expect(subject).to have_css("option:nth-of-type(10)[value='awaiting_debate_date']", text: "Awaiting a debate in parliament (10)")
    end

    it "generates the correct option for 'with_debate_outcome'" do
      expect(subject).to have_css("option:nth-of-type(11)[value='with_debate_outcome']", text: "Has been debated in parliament (11)")
    end

    it "generates the correct option for 'in_debate_queue'" do
      expect(subject).to have_css("option:nth-of-type(12)[value='in_debate_queue']", text: "In debate queue (12)")
    end

    it "marks the correct option as selected" do
      expect(subject).to have_css("option[value='open'][selected]")
    end
  end
end
