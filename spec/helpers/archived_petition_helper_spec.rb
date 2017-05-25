require 'rails_helper'

RSpec.describe ArchivedPetitionHelper, type: :helper do
  let(:parliament) { FactoryGirl.create(:parliament, threshold_for_response: 500, threshold_for_debate: 5000) }
  let(:petition) { FactoryGirl.create(:archived_petition, parliament: parliament, response: response, signature_count: signature_count) }
  let(:response) { nil }

  describe "#archived_threshold" do
    context "when the response threshold has never been reached" do
      let(:signature_count) { 50 }

      it "returns the response threshold" do
        expect(helper.archived_threshold(petition)).to eq(500)
      end
    end

    context "when the response threshold was reached but the government never responded" do
      let(:signature_count) { 550 }

      it "returns the debate threshold" do
        expect(helper.archived_threshold(petition)).to eq(5000)
      end
    end

    context "when the response threshold was reached and the government responded" do
      let(:signature_count) { 550 }
      let(:response) { "Petition response" }

      it "returns the debate threshold" do
        expect(helper.archived_threshold(petition)).to eq(5000)
      end
    end

    context "when the response threshold was not reached but the government has responded" do
      let(:signature_count) { 50 }
      let(:response) { "Petition response" }

      it "returns the debate threshold" do
        expect(helper.archived_threshold(petition)).to eq(5000)
      end
    end

    context "when the debate threshold was reached but the government never responded" do
      let(:signature_count) { 5500 }

      it "returns the debate threshold" do
        expect(helper.archived_threshold(petition)).to eq(5000)
      end
    end

    context "when the debate threshold was reached and the government responded" do
      let(:signature_count) { 5500 }
      let(:response) { "Petition response" }

      it "returns the debate threshold" do
        expect(helper.archived_threshold(petition)).to eq(5000)
      end
    end
  end

  describe "#archived_threshold_percentage" do
    context "when the signature count is less than the response threshold" do
      let(:signature_count) { 18 }

      it "returns a percentage relative to the response threshold" do
        expect(helper.archived_threshold_percentage(petition)).to eq("3.60%")
      end
    end

    context "when the signature count is greater than the response threshold and less than the debate threshold" do
      let(:signature_count) { 625 }

      it "returns a percentage relative to the debate threshold" do
        expect(helper.archived_threshold_percentage(petition)).to eq("12.50%")
      end
    end

    context "when the signature count is greater than the debate threshold" do
      let(:signature_count) { 5500 }

      it "returns 100 percent" do
        expect(helper.archived_threshold_percentage(petition)).to eq("100.00%")
      end
    end

    context "when the response threshold was not reached but government has responded" do
      let(:signature_count) { 275 }
      let(:response) { "Petition response" }

      it "returns a percentage relative to the debate threshold" do
        expect(helper.archived_threshold_percentage(petition)).to eq("5.50%")
      end
    end

    context "when the actual percentage is less than 1" do
      let(:signature_count) { 2 }

      it "returns 1%" do
        expect(helper.archived_threshold_percentage(petition)).to eq("1.00%")
      end
    end
  end

  describe "#archived_parliaments" do
    let!(:parliament) { FactoryGirl.create(:parliament) }
    let!(:archived_parliament) { FactoryGirl.create(:parliament, :archived) }
    let!(:dissolved_parliament) { FactoryGirl.create(:parliament, :dissolved) }

    it "includes archived parliaments" do
      expect(helper.archived_parliaments).to include(archived_parliament)
    end

    it "excludes parliaments that are current" do
      expect(helper.archived_parliaments).not_to include(parliament)
    end

    it "excludes parliaments that are dissolved" do
      expect(helper.archived_parliaments).not_to include(parliament)
    end
  end

  describe "#archived_petition_facets_with_counts" do
    let(:archived_petition_facets) do
      Module.new do
        def archived_petition_facets
          [:all, :published, :rejected]
        end
      end
    end

    let(:petitions) { ArchivedPetition.search({}) }

    subject { helper.archived_petition_facets_with_counts(petitions) }

    before do
      FactoryGirl.create(:archived_petition, :closed)
      FactoryGirl.create(:archived_petition, :rejected)

      helper.extend(archived_petition_facets)
    end

    it "returns each facet with its count" do
      expect(subject).to eq(all: 2, published: 1, rejected: 1)
    end

    context "when a facet is not defined" do
      let(:archived_petition_facets) do
        Module.new do
          def archived_petition_facets
            [:all, :published, :rejected, :unknown]
          end
        end
      end

      it "does not expose the facet" do
        expect(subject.key?(:unknown)).to eq(false)
      end
    end
  end
end
