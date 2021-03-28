require 'rails_helper'

RSpec.describe HomeHelper, type: :helper do
  describe "#no_petitions_yet?" do
    let(:connection) { Petition.connection }
    let(:sql) { /^SELECT 1 AS one FROM/ }

    it "performs an exists query" do
      expect(connection).to receive(:select).with(sql, any_args).and_call_original
      expect(helper.no_petitions_yet?).to be true
    end

    it "it caches the result" do
      expect(connection).to receive(:select).once.with(sql, any_args).and_call_original
      expect(helper.no_petitions_yet?).to be true
      expect(helper.no_petitions_yet?).to be true
    end

    context "when there are no published petitions" do
      before do
        FactoryBot.create(:pending_petition)
      end

      it "returns true" do
        expect(helper.no_petitions_yet?).to be true
      end
    end

    Petition::VISIBLE_STATES.each do |state|
      context "when there is a #{state} petition" do
        before do
          FactoryBot.create(:"#{state}_petition")
        end

        it "returns false" do
          expect(helper.no_petitions_yet?).to be false
        end
      end
    end
  end

  describe "#petition_count" do
    describe "for counting referred petitions" do
      it "returns a HTML-safe string" do
        expect(helper.petition_count(:referred, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the petition count is 1" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:referred, 1)).to eq("<span class=\"count\">1</span> petition was referred to the Petitions Committee")
        end
      end

      context "when the petition count is 100" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:referred, 100)).to eq("<span class=\"count\">100</span> petitions were referred to the Petitions Committee")
        end
      end

      context "when the petition count is 1000" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:referred, 1000)).to eq("<span class=\"count\">1,000</span> petitions were referred to the Petitions Committee")
        end
      end
    end

    describe "for counting debated petitions" do
      it "returns a HTML-safe string" do
        expect(helper.petition_count(:with_debated_outcome, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the petition count is 1" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_debated_outcome, 1)).to eq("<span class=\"count\">1</span> petition was debated by the Senedd")
        end
      end

      context "when the petition count is 100" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_debated_outcome, 100)).to eq("<span class=\"count\">100</span> petitions were debated by the Senedd")
        end
      end

      context "when the petition count is 1000" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_debated_outcome, 1000)).to eq("<span class=\"count\">1,000</span> petitions were debated by the Senedd")
        end
      end
    end
  end

  describe "#any_actioned_petitions?" do
    let!(:pending_petition) { FactoryBot.create :pending_petition }
    let!(:hidden_petition) { FactoryBot.create :hidden_petition }
    let!(:open_petition) { FactoryBot.create :open_petition }

    describe "when there is an actioned petition" do
      let!(:referred_petition) { FactoryBot.create :referred_petition }

      it "returns true" do
        expect(helper.any_actioned_petitions?).to eq true
      end
    end

    describe "when there are no actioned petitions" do
      it "returns false" do
        expect(helper.any_actioned_petitions?).to eq false
      end
    end
  end

  describe "#trending_petitions" do
    let(:trending) { double(Petition) }
    let(:now) { (Time.now.to_i / 300) * 300 }

    before do
      allow(Petition).to receive(:trending).and_return(trending)
      allow(trending).to receive(:pluck).and_return(petitions)
    end

    around do |example|
      without_cache([:trending_petitions, I18n.locale, now], expires_in: 500) { example.run }
    end

    context "when trending petitions is disabled" do
      let(:petitions) { [[1, "Petition Action", 1000]] }

      before do
        allow(Site).to receive(:disable_trending_petitions?).and_return(true)
      end

      it "doesn't yield" do
        expect { |b| helper.trending_petitions(&b) }.not_to yield_control
      end
    end

    context "when trending petitions is enabled" do
      before do
        allow(Site).to receive(:disable_trending_petitions?).and_return(false)
      end

      context "and there are no trending petitions" do
        let(:petitions) { [] }

        it "doesn't yield" do
          expect { |b| helper.trending_petitions(&b) }.not_to yield_control
        end
      end

      context "and there are trending petitions" do
        let(:petitions) { [[1, "Petition Action", 1000]] }

        it "yields the trending petitions" do
          expect { |b| helper.trending_petitions(&b) }.to yield_with_args([[1, "Petition Action", 1000]])
        end
      end
    end
  end
end
