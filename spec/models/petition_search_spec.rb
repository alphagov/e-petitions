require 'rails_helper'

RSpec.describe PetitionSearch, type: :model do
  describe "legacy search mapping" do
    let(:params) { ActionController::Parameters.new(state: state) }
    let(:search) { described_class.new(params) }

    context "when the state is 'all'" do
      let(:state) { "all" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: [], response: [], debate: [], sort: "default")
      end
    end

    context "when the state is 'open'" do
      let(:state) { "open" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: ["open"], response: [], debate: [], sort: "default")
      end
    end

    context "when the state is 'recent'" do
      let(:state) { "recent" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: ["open"], response: [], debate: [], sort: "recent")
      end
    end

    context "when the state is 'closed'" do
      let(:state) { "closed" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: ["closed"], response: [], debate: [], sort: "default")
      end
    end

    context "when the state is 'rejected'" do
      let(:state) { "rejected" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: ["rejected"], response: [], debate: [], sort: "recent")
      end
    end

    context "when the state is 'rejected'" do
      let(:state) { "rejected" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: ["rejected"], response: [], debate: [], sort: "recent")
      end
    end

    context "when the state is 'awaiting_response'" do
      let(:state) { "awaiting_response" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: ["open", "closed"], response: ["awaiting"], debate: [], sort: "waiting_longest")
      end
    end

    context "when the state is 'with_response'" do
      let(:state) { "with_response" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: ["open", "closed"], response: ["responded"], debate: [], sort: "latest_response")
      end
    end

    context "when the state is 'awaiting_debate'" do
      let(:state) { "awaiting_debate" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: ["open", "closed"], response: [], debate: ["awaiting", "scheduled"], sort: "upcoming_debates")
      end
    end

    context "when the state is 'debated'" do
      let(:state) { "debated" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: ["open", "closed"], response: [], debate: ["debated"], sort: "latest_debate")
      end
    end

    context "when the state is 'not_debated'" do
      let(:state) { "not_debated" }

      it "configures the search correctly" do
        expect(search).to have_attributes(status: ["open", "closed"], response: [], debate: ["not_debated"], sort: "latest_debate")
      end
    end
  end
end
