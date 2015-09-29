require 'rails_helper'

RSpec.describe Petition, type: :model do
  context "defaults" do
    it "has pending as default state" do
      p = Petition.new
      expect(p.state).to eq("pending")
    end

    it "generates sponsor token" do
      p = FactoryGirl.create(:petition, :sponsor_token => nil)
      expect(p.sponsor_token).not_to be_nil
    end
  end

  describe "associations" do
    it { is_expected.to have_one(:debate_outcome).dependent(:destroy) }
    it { is_expected.to have_one(:government_response).dependent(:destroy) }

    it { is_expected.to have_many(:emails).dependent(:destroy) }
  end

  describe "callbacks" do
    context "when creating a petition" do
      let(:now) { Time.current }

      before do
        Site.update_all(last_petition_created_at: nil)
      end

      it "updates the site's last_petition_created_at column" do
        expect {
          FactoryGirl.create(:petition)
        }.to change {
          Site.last_petition_created_at
        }.from(nil).to(be_within(1.second).of(now))
      end
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:action).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:background).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:creator_signature).with_message(/must be completed/) }

    it { is_expected.to have_db_column(:action).of_type(:string).with_options(limit: 255, null: false) }
    it { is_expected.to have_db_column(:background).of_type(:string).with_options(limit: 300, null: true) }
    it { is_expected.to have_db_column(:additional_details).of_type(:text).with_options(null: true) }

    it "should validate the length of :action to within 80 characters" do
      expect(FactoryGirl.build(:petition, :action => 'x' * 80)).to be_valid
      expect(FactoryGirl.build(:petition, :action => 'x' * 81)).not_to be_valid
    end

    it "should validate the length of :background to within 300 characters" do
      expect(FactoryGirl.build(:petition, :background => 'x' * 300)).to be_valid
      expect(FactoryGirl.build(:petition, :background => 'x' * 301)).not_to be_valid
    end

    it "should validate the length of :additional_details to within 800 characters" do
      expect(FactoryGirl.build(:petition, :additional_details => 'x' * 800)).to be_valid
      expect(FactoryGirl.build(:petition, :additional_details => 'x' * 801)).not_to be_valid
    end

    it "does not allow a blank state" do
      petition = FactoryGirl.build(:petition, state: '')

      expect(petition).not_to be_valid
      expect(petition.errors[:state]).not_to be_empty
    end

    it "does not allow an unknown state" do
      petition = FactoryGirl.build(:petition, state: 'unknown')

      expect(petition).not_to be_valid
      expect(petition.errors[:state]).not_to be_empty
    end

    %w(pending validated sponsored flagged open rejected hidden).each do |state|
      it "allows state: #{state}" do
        petition = FactoryGirl.build(:"#{state}_petition")

        expect(petition).to be_valid
        expect(petition.state).to eq(state)
        expect(petition.errors[:state]).to be_empty
      end
    end

    context "when state is open" do
      let(:petition) { FactoryGirl.build(:open_petition, open_at: nil, closed_at: nil) }

      it "checks petition is invalid if no open_at date" do
        expect(petition).not_to be_valid
        expect(petition.errors[:open_at]).not_to be_empty
      end

      it "checks petition is valid if there is an open_at date" do
        petition.open_at = Time.current
        expect(petition).to be_valid
      end
    end
  end

  context "scopes" do
    describe "trending" do
      before(:each) do
        11.times do |count|
          petition = FactoryGirl.create(:open_petition, action: "petition ##{count+1}", last_signed_at: Time.current)
          count.times { FactoryGirl.create(:validated_signature, petition: petition) }
        end

        @petition_with_old_signatures = FactoryGirl.create(:open_petition, action: "petition out of range", last_signed_at: 2.hours.ago)
        @petition_with_old_signatures.signatures.first.update_attribute(:validated_at, 2.hours.ago)
      end

      it "returns petitions trending for the last hour" do
        expect(Petition.trending.map(&:id).include?(@petition_with_old_signatures.id)).to be_falsey
      end

      it "returns the signature count for the last hour as an additional attribute" do
        expect(Petition.trending.first.signature_count_in_period).to eq(11)
        expect(Petition.trending.last.signature_count_in_period).to eq(9)
      end

      it "limits the result to 3 petitions" do
        # 13 petitions signed in the last hour
        2.times do |count|
          petition = FactoryGirl.create(:open_petition, action: "petition ##{count+1}", last_signed_at: Time.current)
          count.times { FactoryGirl.create(:validated_signature, petition: petition) }
        end

        expect(Petition.trending.to_a.size).to eq(3)
      end

      it "excludes petitions that are not open" do
        petition = FactoryGirl.create(:validated_petition)
        20.times{ FactoryGirl.create(:validated_signature, petition: petition) }

        expect(Petition.trending.to_a).not_to include(petition)
      end
    end

    context "threshold" do
      before :each do
        @p1 = FactoryGirl.create(:open_petition)
        @p1.update_attribute(:signature_count, 100000)
        @p2 = FactoryGirl.create(:open_petition)
        @p2.update_attribute(:signature_count, 100001)
        @p3 = FactoryGirl.create(:open_petition)
        @p3.update_attribute(:signature_count, 99999)
        @p4 = FactoryGirl.create(:open_petition)
        @p4.update_attribute(:signature_count, 200000)
      end

      it "returns 4 petitions over the threshold" do
        petitions = Petition.threshold
        expect(petitions.size).to eq(3)
        expect(petitions).to include(@p1, @p2, @p4)
      end
    end

    context "for_state" do
      before :each do
        @p1 = FactoryGirl.create(:petition, :state => Petition::PENDING_STATE)
        @p2 = FactoryGirl.create(:petition, :state => Petition::VALIDATED_STATE)
        @p3 = FactoryGirl.create(:petition, :state => Petition::PENDING_STATE)
        @p4 = FactoryGirl.create(:open_petition, :closed_at => 1.day.from_now)
        @p5 = FactoryGirl.create(:petition, :state => Petition::HIDDEN_STATE)
        @p6 = FactoryGirl.create(:closed_petition, :closed_at => 1.day.ago)
        @p7 = FactoryGirl.create(:petition, :state => Petition::SPONSORED_STATE)
        @p8 = FactoryGirl.create(:petition, :state => Petition::FLAGGED_STATE)
      end

      it "returns 2 pending petitions" do
        petitions = Petition.for_state(Petition::PENDING_STATE)
        expect(petitions.size).to eq(2)
        expect(petitions).to include(@p1, @p3)
      end

      it "returns 1 validated, sponsored, flagged, open, closed and hidden petitions" do
        [[Petition::VALIDATED_STATE, @p2], [Petition::OPEN_STATE, @p4],
         [Petition::HIDDEN_STATE, @p5], [Petition::CLOSED_STATE, @p6],
         [Petition::SPONSORED_STATE, @p7], [Petition::FLAGGED_STATE, @p8]].each do |state_and_petition|
          petitions = Petition.for_state(state_and_petition[0])
          expect(petitions.size).to eq(1)
          expect(petitions).to eq([state_and_petition[1]])
        end
      end
    end

    context "visible" do
      before :each do
        @hidden_petition_1 = FactoryGirl.create(:petition, :state => Petition::PENDING_STATE)
        @hidden_petition_2 = FactoryGirl.create(:petition, :state => Petition::VALIDATED_STATE)
        @hidden_petition_3 = FactoryGirl.create(:petition, :state => Petition::HIDDEN_STATE)
        @hidden_petition_4 = FactoryGirl.create(:petition, :state => Petition::SPONSORED_STATE)
        @hidden_petition_5 = FactoryGirl.create(:petition, :state => Petition::FLAGGED_STATE)
        @visible_petition_1 = FactoryGirl.create(:open_petition)
        @visible_petition_2 = FactoryGirl.create(:rejected_petition)
        @visible_petition_3 = FactoryGirl.create(:open_petition, :closed_at => 1.day.ago)
      end

      it "returns only visible petitions" do
        expect(Petition.visible.size).to eq(3)
        expect(Petition.visible).to include(@visible_petition_1, @visible_petition_2, @visible_petition_3)
      end
    end

    context "not_hidden" do
      let!(:petition) { FactoryGirl.create(:hidden_petition) }

      it "returns only petitions that are not hidden" do
        expect(Petition.not_hidden).not_to include(petition)
      end
    end

    context "awaiting_response" do
      context "when the petition has not reached the response threshold" do
        let(:petition) { FactoryGirl.create(:open_petition) }

        it "is not included in the list" do
          expect(Petition.awaiting_response).not_to include(petition)
        end
      end

      context "when a petition has reached the response threshold" do
        let(:petition) { FactoryGirl.create(:awaiting_petition) }

        it "is included in the list" do
          expect(Petition.awaiting_response).to include(petition)
        end
      end

      context "when a petition has a response" do
        let(:petition) { FactoryGirl.create(:responded_petition) }

        it "is not included in the list" do
          expect(Petition.awaiting_response).not_to include(petition)
        end
      end
    end

    context "with_response" do
      before do
        @p1 = FactoryGirl.create(:responded_petition)
        @p2 = FactoryGirl.create(:open_petition)
        @p3 = FactoryGirl.create(:responded_petition)
        @p4 = FactoryGirl.create(:open_petition)
      end

      it "returns only the petitions have a government response timestamp" do
        expect(Petition.with_response).to match_array([@p1, @p3])
      end
    end

    context "with_debate_outcome" do
      before do
        @p1 = FactoryGirl.create(:debated_petition)
        @p2 = FactoryGirl.create(:open_petition)
        @p3 = FactoryGirl.create(:debated_petition)
        @p4 = FactoryGirl.create(:closed_petition)
        @p5 = FactoryGirl.create(:rejected_petition)
        @p6 = FactoryGirl.create(:sponsored_petition)
        @p7 = FactoryGirl.create(:pending_petition)
        @p8 = FactoryGirl.create(:validated_petition)
      end

      it "returns only the petitions which have a debate outcome" do
        expect(Petition.with_debate_outcome).to match_array([@p1, @p3])
      end
    end

    context "awaiting_debate" do
      before do
        @p1 = FactoryGirl.create(:open_petition)
        @p2 = FactoryGirl.create(:awaiting_debate_petition)
        @p3 = FactoryGirl.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.from_now)
        @p4 = FactoryGirl.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.ago)
      end

      it "doesn't return petitions that have aren't eligible" do
        expect(Petition.awaiting_debate).not_to include(@p1)
      end

      it "returns petitions that have reached the debate threshold" do
        expect(Petition.awaiting_debate).to include(@p2)
      end

      it "returns petitions that have a scheduled debate date in the future" do
        expect(Petition.awaiting_debate).to include(@p3)
      end

      it "doesn't return petitions that have been debated" do
        expect(Petition.awaiting_debate).not_to include(@p4)
      end
    end

    context "by_most_relevant_debate_date" do
      before do
        @p1 = FactoryGirl.create(:awaiting_debate_petition, debate_threshold_reached_at: 2.weeks.ago)
        @p2 = FactoryGirl.create(:awaiting_debate_petition, debate_threshold_reached_at: 4.weeks.ago)
        @p3 = FactoryGirl.create(:awaiting_debate_petition, scheduled_debate_date: 4.days.from_now)
        @p4 = FactoryGirl.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.from_now)
      end

      it "returns the petitions in the correct order" do
        expect(Petition.by_most_relevant_debate_date.to_a).to eq([@p4, @p3, @p2, @p1])
      end
    end

    context "debated" do
      before do
        @p1 = FactoryGirl.create(:open_petition)
        @p2 = FactoryGirl.create(:open_petition, scheduled_debate_date: 2.days.from_now)
        @p3 = FactoryGirl.create(:awaiting_debate_petition)
        @p4 = FactoryGirl.create(:not_debated_petition)
        @p5 = FactoryGirl.create(:debated_petition)
      end

      it "doesn't return petitions that have aren't eligible" do
        expect(Petition.debated).not_to include(@p1)
      end

      it "doesn't return petitions that have a scheduled debate date" do
        expect(Petition.debated).not_to include(@p2)
      end

      it "doesn't return petitions that have reached the debate threshold" do
        expect(Petition.debated).not_to include(@p3)
      end

      it "doesn't return petitions that have been rejected for a debate" do
        expect(Petition.debated).not_to include(@p4)
      end

      it "returns petitions that have been debated" do
        expect(Petition.debated).to include(@p5)
      end
    end

    context "not_debated" do
      before do
        @p1 = FactoryGirl.create(:open_petition)
        @p2 = FactoryGirl.create(:awaiting_debate_petition)
        @p3 = FactoryGirl.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.from_now)
        @p4 = FactoryGirl.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.ago)
        @p5 = FactoryGirl.create(:not_debated_petition)
      end

      it "doesn't return petitions that have aren't eligible" do
        expect(Petition.not_debated).not_to include(@p1)
      end

      it "doesn't return petitions that have reached the debate threshold" do
        expect(Petition.not_debated).not_to include(@p2)
      end

      it "doesn't return petitions that have a scheduled debate date in the future" do
        expect(Petition.not_debated).not_to include(@p3)
      end

      it "doesn't return petitions that have been debated" do
        expect(Petition.not_debated).not_to include(@p4)
      end

      it "returns petitions that have been rejected for a debate" do
        expect(Petition.not_debated).to include(@p5)
      end
    end

    context "awaiting_debate_date" do
      before do
        @p1 = FactoryGirl.create(:open_petition)
        @p2 = FactoryGirl.create(:awaiting_debate_petition)
        @p3 = FactoryGirl.create(:debated_petition)
      end

      it "returns only petitions that reached the debate threshold" do
        expect(Petition.awaiting_debate_date).to include(@p2)
      end

      it "doesn't include petitions that has the debate date" do
        expect(Petition.awaiting_debate_date).not_to include(@p3)
      end
    end

    context "selectable" do
      before :each do
        @non_selectable_petition_1 = FactoryGirl.create(:petition, :state => Petition::PENDING_STATE)
        @non_selectable_petition_2 = FactoryGirl.create(:petition, :state => Petition::VALIDATED_STATE)
        @non_selectable_petition_3 = FactoryGirl.create(:petition, :state => Petition::SPONSORED_STATE)

        @selectable_petition_1 = FactoryGirl.create(:open_petition)
        @selectable_petition_2 = FactoryGirl.create(:rejected_petition)
        @selectable_petition_3 = FactoryGirl.create(:closed_petition, :closed_at => 1.day.ago)
        @selectable_petition_4 = FactoryGirl.create(:petition, :state => Petition::HIDDEN_STATE)
      end

      it "returns only selectable petitions" do
        expect(Petition.selectable.size).to eq(4)
        expect(Petition.selectable).to include(@selectable_petition_1, @selectable_petition_2, @selectable_petition_3, @selectable_petition_4)
      end
    end

    context 'in_debate_queue' do
      let!(:petition_1) { FactoryGirl.create(:open_petition, debate_threshold_reached_at: 1.day.ago) }
      let!(:petition_2) { FactoryGirl.create(:open_petition, debate_threshold_reached_at: nil) }
      let!(:petition_3) { FactoryGirl.create(:open_petition, debate_threshold_reached_at: nil, scheduled_debate_date: 3.days.from_now) }
      let!(:petition_4) { FactoryGirl.create(:open_petition, debate_threshold_reached_at: nil, scheduled_debate_date: nil) }

      subject { described_class.in_debate_queue }

      it 'includes petitions that have reached the debate threshold' do
        expect(subject).to include(petition_1)
        expect(subject).not_to include(petition_2)
      end

      it 'includes petitions that have not reached the debate threshold if they have been scheduled for debate' do
        expect(subject).to include(petition_3)
        expect(subject).not_to include(petition_4)
      end
    end

    describe '.popular_in_constituency' do
      let!(:petition_1) { FactoryGirl.create(:open_petition, signature_count: 10) }
      let!(:petition_2) { FactoryGirl.create(:open_petition, signature_count: 20) }
      let!(:petition_3) { FactoryGirl.create(:open_petition, signature_count: 30) }
      let!(:petition_4) { FactoryGirl.create(:open_petition, signature_count: 40) }

      let!(:constituency_1) { FactoryGirl.generate(:constituency_id) }
      let!(:constituency_2) { FactoryGirl.generate(:constituency_id) }

      let!(:petition_1_journal_1) { FactoryGirl.create(:constituency_petition_journal, petition: petition_1, constituency_id: constituency_1, signature_count: 6) }
      let!(:petition_1_journal_2) { FactoryGirl.create(:constituency_petition_journal, petition: petition_1, constituency_id: constituency_2, signature_count: 4) }
      let!(:petition_2_journal_2) { FactoryGirl.create(:constituency_petition_journal, petition: petition_2, constituency_id: constituency_2, signature_count: 20) }
      let!(:petition_3_journal_1) { FactoryGirl.create(:constituency_petition_journal, petition: petition_3, constituency_id: constituency_1, signature_count: 30) }
      let!(:petition_4_journal_1) { FactoryGirl.create(:constituency_petition_journal, petition: petition_4, constituency_id: constituency_1, signature_count: 0) }
      let!(:petition_4_journal_2) { FactoryGirl.create(:constituency_petition_journal, petition: petition_4, constituency_id: constituency_2, signature_count: 40) }

      it 'excludes petitions that have no journal for the supplied constituency_id' do
        popular = Petition.popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_2)
      end

      it 'excludes petitions that have a journal with 0 votes for the supplied constituency_id' do
        popular = Petition.popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_4)
      end

      it 'excludes closed petitions with signatures from the supplied constituency_id' do
        petition_1.update_columns(state: 'closed', closed_at: 3.days.ago)
        popular = Petition.popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'excludes rejected petitions with signatures from the supplied constituency_id' do
        petition_1.update_column(:state, Petition::REJECTED_STATE)
        popular = Petition.popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'excludes hidden petitions with signatures from the supplied constituency_id' do
        petition_1.update_column(:state, Petition::HIDDEN_STATE)
        popular = Petition.popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'includes open petitions with signatures from the supplied constituency_id ordered by the count of signatures' do
        popular = Petition.popular_in_constituency(constituency_1, 2)
        expect(popular).to eq [petition_3, petition_1]
      end

      it 'adds the constituency_signature_count attribute to the retrieved petitions' do
        most_popular = Petition.popular_in_constituency(constituency_1, 1).first
        expect(most_popular).to respond_to :constituency_signature_count
        expect(most_popular.constituency_signature_count).to eq 30
      end

      it 'returns an array, not a scope' do
        expect(Petition.popular_in_constituency(constituency_1, 1)).to be_an Array
      end
    end

    describe 'tagged_with' do
      let!(:petition_1) { FactoryGirl.create(:petition, admin_notes: '[foo]') }
      let!(:petition_2) { FactoryGirl.create(:petition, admin_notes: 'foo') }
      let!(:petition_3) { FactoryGirl.create(:petition, admin_notes: '[bar]') }
      let!(:petition_4) { FactoryGirl.create(:petition, admin_notes: '[bar] [foo]') }
      let!(:petition_5) { FactoryGirl.create(:petition, action: 'foo', background: 'foo', additional_details: 'foo') }
      let!(:petition_6) { FactoryGirl.create(:petition, action: '[foo]', background: '[foo]', additional_details: '[foo]') }
      let!(:petition_7) { FactoryGirl.create(:petition, admin_notes: '[bar foo]') }

      it 'fetches petitions with the supplied tag in their notes field wrapped in []' do
        expect(Petition.tagged_with('foo')).to include(petition_1)
      end

      it 'ignores petitions with the supplied tag in their notes field but not wrapped in []' do
        expect(Petition.tagged_with('foo')).not_to include(petition_2)
      end

      it 'ignores petitions with different []-wrapped tags in their notes field' do
        expect(Petition.tagged_with('foo')).not_to include(petition_3)
      end

      it 'fetches petitions with multiple tags in their notes field if one matches' do
        expect(Petition.tagged_with('foo')).to include(petition_4)
      end

      it 'ignores petitions with tag matches in other fields, even if they are []-wrapped' do
        expect(Petition.tagged_with('foo')).not_to include(petition_5, petition_6)
      end

      it 'sanitizes the supplied tag to strip [] and %' do
        expect(Petition.tagged_with('f%')).to be_empty
        expect(Petition.tagged_with('[%]')).to be_empty
        expect(Petition.tagged_with('f[%]oo')).to eq (Petition.tagged_with('foo'))
      end

      it 'assumes spaces are a single tag with a space in it, not searches for multiple tags' do
        bar_foo_tagged = Petition.tagged_with('bar foo')
        expect(bar_foo_tagged).to include petition_7
        expect(bar_foo_tagged).not_to include petition_4
      end
    end
  end

  describe "signature count" do
    let(:petition) { FactoryGirl.create(:pending_petition) }
    let(:signature) { FactoryGirl.create(:pending_signature, petition: petition) }

    before do
      petition.validate_creator_signature!
    end

    it "returns 1 (the creator) for a new petition" do
      expect(petition.signature_count).to eq(1)
    end

    it "still returns 1 with a new signature" do
      signature && petition.reload
      expect(petition.signature_count).to eq(1)
    end

    it "returns 2 when signature is validated" do
      signature.validate! && petition.reload
      expect(petition.signature_count).to eq(2)
    end
  end

  describe 'can_have_debate_added?' do
    it "is true if the petition is OPEN and the closed_at date is in the future" do
      petition = FactoryGirl.build(:open_petition, :closed_at => 1.year.from_now)
      expect(petition.can_have_debate_added?).to be_truthy
    end

    it "is true if the petition is OPEN and the closed_at date is in the past" do
      petition = FactoryGirl.build(:open_petition, :closed_at => 2.minutes.ago)
      expect(petition.can_have_debate_added?).to be_truthy
    end

    it "is false otherwise" do
      expect(FactoryGirl.build(:open_petition, state: Petition::PENDING_STATE).can_have_debate_added?).to be_falsey
      expect(FactoryGirl.build(:open_petition, state: Petition::HIDDEN_STATE).can_have_debate_added?).to be_falsey
      expect(FactoryGirl.build(:open_petition, state: Petition::REJECTED_STATE).can_have_debate_added?).to be_falsey
      expect(FactoryGirl.build(:open_petition, state: Petition::VALIDATED_STATE).can_have_debate_added?).to be_falsey
      expect(FactoryGirl.build(:open_petition, state: Petition::SPONSORED_STATE).can_have_debate_added?).to be_falsey
    end
  end

  describe "updating the scheduled debate date" do
    context "when the petition is open" do
      context "and the debate date is changed to nil" do
        subject(:petition) {
          FactoryGirl.create(:open_petition,
            scheduled_debate_date: 2.days.from_now,
            debate_state: "awaiting"
          )
        }

        it "sets the debate state to 'pending'" do
          expect {
            petition.update(scheduled_debate_date: nil)
          }.to change {
            petition.debate_state
          }.from("awaiting").to("pending")
        end
      end

      context "when the debate date is in the future" do
        subject(:petition) {
          FactoryGirl.create(:open_petition,
            scheduled_debate_date: nil,
            debate_state: "pending"
          )
        }

        it "sets the debate state to 'awaiting'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.from_now)
          }.to change {
            petition.debate_state
          }.from("pending").to("awaiting")
        end
      end

      context "when the debate date is in the past" do
        subject(:petition) {
          FactoryGirl.create(:open_petition,
            scheduled_debate_date: nil,
            debate_state: "pending"
          )
        }

        it "sets the debate state to 'debated'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.ago)
          }.to change {
            petition.debate_state
          }.from("pending").to("debated")
        end
      end

      context "when the debate date is not changed" do
        subject(:petition) {
          FactoryGirl.create(:open_petition,
            scheduled_debate_date: Date.yesterday,
            debate_state: "awaiting"
          )
        }

        it "does not change the debate state" do
          expect {
            petition.update(open_at: 5.days.ago)
          }.not_to change {
            petition.debate_state
          }
        end
      end
    end

    context "when the petition is closed" do
      context "and the debate date is changed to nil" do
        subject(:petition) {
          FactoryGirl.create(:closed_petition,
            scheduled_debate_date: 2.days.from_now,
            debate_state: "awaiting"
          )
        }

        it "sets the debate state to 'closed'" do
          expect {
            petition.update(scheduled_debate_date: nil)
          }.to change {
            petition.debate_state
          }.from("awaiting").to("closed")
        end
      end

      context "when the debate date is in the future" do
        subject(:petition) {
          FactoryGirl.create(:closed_petition,
            scheduled_debate_date: nil,
            debate_state: "closed"
          )
        }

        it "sets the debate state to 'awaiting'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.from_now)
          }.to change {
            petition.debate_state
          }.from("closed").to("awaiting")
        end
      end

      context "when the debate date is in the past" do
        subject(:petition) {
          FactoryGirl.create(:closed_petition,
            scheduled_debate_date: nil,
            debate_state: "pending"
          )
        }

        it "sets the debate state to 'debated'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.ago)
          }.to change {
            petition.debate_state
          }.from("pending").to("debated")
        end
      end

      context "when the debate date is not changed" do
        subject(:petition) {
          FactoryGirl.create(:closed_petition,
            scheduled_debate_date: Date.yesterday,
            debate_state: "awaiting"
          )
        }

        it "does not change the debate state" do
          expect {
            petition.update(open_at: 5.days.ago)
          }.not_to change {
            petition.debate_state
          }
        end
      end
    end
  end

  describe "#can_be_signed?" do
    context "when the petition is in the open state" do
      let(:petition) { FactoryGirl.build(:petition, state: Petition::OPEN_STATE) }

      it "is true" do
        expect(petition.can_be_signed?).to be_truthy
      end
    end

    (Petition::STATES - [Petition::OPEN_STATE]).each do |state|
      context "when the petition is in the #{state} state" do
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is false" do
          expect(petition.can_be_signed?).to be_falsey
        end
      end
    end
  end

  describe "open?" do
    context "when the state is open" do
      let(:petition) { FactoryGirl.build(:petition, state: Petition::OPEN_STATE) }

      it "returns true" do
        expect(petition.open?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::OPEN_STATE]).each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is not open when state is #{state}" do
          expect(petition.open?).to be_falsey
        end
      end
    end
  end

  describe "#closed?" do
    context "when the state is closed" do
      let(:petition) { FactoryGirl.build(:petition, state: Petition::CLOSED_STATE) }

      it "returns true" do
        expect(petition.closed?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::CLOSED_STATE]).each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is not open when state is #{state}" do
          expect(petition.open?).to be_falsey
        end
      end
    end
  end

  describe "rejected?" do
    context "when the state is rejected" do
      let(:petition) { FactoryGirl.build(:petition, state: Petition::REJECTED_STATE) }

      it "returns true" do
        expect(petition.rejected?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::REJECTED_STATE]).each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is not rejected when state is #{state}" do
          expect(petition.rejected?).to be_falsey
        end
      end
    end
  end

  describe "hidden?" do
    context "when the state is hidden" do
      it "returns true" do
        expect(FactoryGirl.build(:petition, :state => Petition::HIDDEN_STATE).hidden?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::HIDDEN_STATE]).each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is not hidden when state is #{state}" do
          expect(petition.hidden?).to be_falsey
        end
      end
    end
  end

  describe "flagged?" do
    context "when the state is flagged" do
      let(:petition) { FactoryGirl.build(:petition, state: Petition::FLAGGED_STATE) }

      it "returns true" do
        expect(petition.flagged?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::FLAGGED_STATE]).each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is not open when state is #{state}" do
          expect(petition.flagged?).to be_falsey
        end
      end
    end
  end

  describe "#in_moderation?" do
    context "for in moderation states" do
      Petition::IN_MODERATION_STATES.each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is in moderation when state is #{state}" do
          expect(petition.in_moderation?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::IN_MODERATION_STATES).each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is not in moderation when state is #{state}" do
          expect(petition.in_moderation?).to be_falsey
        end
      end
    end
  end

  describe "#moderated?" do
    context "for moderated states" do
      Petition::MODERATED_STATES.each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is moderated when state is #{state}" do
          expect(petition.moderated?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::MODERATED_STATES).each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is not moderated when state is #{state}" do
          expect(petition.moderated?).to be_falsey
        end
      end
    end
  end

  describe "#in_todo_list?" do
    context "for todo list states" do
      Petition::TODO_LIST_STATES.each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is in todo list when the state is #{state}" do
          expect(petition.in_todo_list?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::TODO_LIST_STATES).each do |state|
        let(:petition) { FactoryGirl.build(:petition, state: state) }

        it "is not in todo list when the state is #{state}" do
          expect(petition.in_todo_list?).to be_falsey
        end
      end
    end
  end

  describe "counting validated signatures" do
    let(:petition) { FactoryGirl.build(:petition) }

    it "only counts validated signtatures" do
      expect(petition.signatures).to receive(:validated).and_return(double(:valid_signatures, :count => 123))
      expect(petition.count_validated_signatures).to eq(123)
    end
  end

  describe ".close_petitions!" do
    context "when a petition is in the open state and the closing date has not passed" do
      let(:open_at) { Site.opened_at_for_closing(1.day.from_now) }
      let!(:petition) { FactoryGirl.create(:open_petition, open_at: open_at) }

      it "does not close the petition" do
        expect{
          described_class.close_petitions!
        }.not_to change{ petition.reload.state }
      end
    end

    context "when a petition is in the open state and closed_at has passed" do
      let(:open_at) { Site.opened_at_for_closing(1.day.ago) }
      let!(:petition) { FactoryGirl.create(:open_petition, open_at: open_at) }

      it "does close the petition" do
        expect{
          described_class.close_petitions!
        }.to change{ petition.reload.state }.from('open').to('closed')
      end
    end
  end

  describe ".in_need_of_closing" do
    context "when a petition is in the closed state" do
      let!(:petition) { FactoryGirl.create(:closed_petition) }

      it "does not find the petition" do
        expect(described_class.in_need_of_closing.to_a).not_to include(petition)
      end
    end

    context "when a petition is in the open state and the closing date has not passed" do
      let(:open_at) { Site.opened_at_for_closing(1.day.from_now) }
      let!(:petition) { FactoryGirl.create(:open_petition, open_at: open_at) }

      it "does not find the petition" do
        expect(described_class.in_need_of_closing.to_a).not_to include(petition)
      end
    end

    context "when a petition is in the open state and the closing date has passed" do
      let(:open_at) { Site.opened_at_for_closing(1.day.ago) }
      let!(:petition) { FactoryGirl.create(:open_petition, open_at: open_at) }

      it "finds the petition" do
        expect(described_class.in_need_of_closing.to_a).to include(petition)
      end
    end
  end

  describe ".in_need_of_marking_as_debated" do
    context "when a petition is not in the the 'awaiting' debate state" do
      let!(:petition) { FactoryGirl.create(:open_petition) }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end

    context "when a petition is awaiting a debate date" do
      let!(:petition) {
        FactoryGirl.create(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: nil
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end

    context "when a petition is awaiting a debate" do
      let!(:petition) {
        FactoryGirl.create(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: 2.days.from_now
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end

    context "when a petition debate date has passed but is still marked as 'awaiting'" do
      let(:petition) {
        FactoryGirl.build(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        travel_to(2.days.ago) do
          petition.save
        end
      end

      it "finds the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).to include(petition)
      end
    end

    context "when a petition debate date has passed and it marked as 'debated'" do
      let!(:petition) {
        FactoryGirl.create(:open_petition,
          debate_state: 'debated',
          scheduled_debate_date: 2.days.ago
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end
  end

  describe ".mark_petitions_as_debated!" do
    context "when a petition is in the awaiting debate state and the debate date has passed" do
      let(:petition) {
        FactoryGirl.build(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        travel_to(2.days.ago) do
          petition.save
        end
      end

      it "marks the petition as debated" do
        expect{
          described_class.mark_petitions_as_debated!
        }.to change{ petition.reload.debate_state }.from('awaiting').to('debated')
      end
    end

    context "when a petition is in the awaiting debate state and the debate date has not passed" do
      let(:petition) {
        FactoryGirl.build(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        petition.save
      end

      it "does not mark the petition as debated" do
        expect{
          described_class.mark_petitions_as_debated!
        }.not_to change{ petition.reload.debate_state }
      end
    end
  end

  describe ".with_invalid_signature_counts" do
    let!(:petition) { FactoryGirl.create(:open_petition, attributes) }

    context "when there are no petitions with invalid signature counts" do
      let(:attributes) { { created_at: 2.days.ago, updated_at: 2.days.ago } }

      it "doesn't return any petitions" do
        expect(described_class.with_invalid_signature_counts).to eq([])
      end
    end

    context "when there are petitions with invalid signature counts" do
      let(:attributes) { { created_at: 2.days.ago, updated_at: 2.days.ago, signature_count: 100 } }

      it "returns the petitions" do
        expect(described_class.with_invalid_signature_counts).to eq([petition])
      end
    end
  end

  describe "#update_signature_count!" do
    let!(:petition) { FactoryGirl.create(:open_petition, attributes) }

    context "when there are petitions with invalid signature counts" do
      let(:attributes) { { created_at: 2.days.ago, updated_at: 2.days.ago, signature_count: 100 } }

      it "updates the signature count" do
        expect{
          petition.update_signature_count!
        }.to change{ petition.reload.signature_count }.from(100).to(1)
      end

      it "updates the updated_at timestamp" do
        expect{
          petition.update_signature_count!
        }.to change{ petition.reload.updated_at }.to(be_within(1.second).of(Time.current))
      end
    end
  end

  describe "#increment_signature_count!" do
    let(:signature_count) { 8 }
    let(:petition) do
      FactoryGirl.create(:open_petition, {
        signature_count: signature_count,
        last_signed_at: 2.days.ago,
        updated_at: 2.days.ago
      })
    end

    it "increases the signature count by 1" do
      expect{
        petition.increment_signature_count!
      }.to change{ petition.signature_count }.by(1)
    end

    it "updates the last_signed_at timestamp" do
      petition.increment_signature_count!
      expect(petition.last_signed_at).to be_within(1.second).of(Time.current)
    end

    it "updates the updated_at timestamp" do
      petition.increment_signature_count!
      expect(petition.updated_at).to be_within(1.second).of(Time.current)
    end

    context "when the petition is first sponsored" do
      let(:petition) do
        FactoryGirl.create(:pending_petition, {
          signature_count: 0,
          last_signed_at: nil,
          updated_at: 2.days.ago
        })
      end

      it "records changes the state from 'pending' to 'validated'" do
        expect {
          petition.increment_signature_count!
        }.to change{
          petition.state
        }.from(Petition::PENDING_STATE).to(Petition::VALIDATED_STATE)
      end
    end

    context "when the signature count crosses the threshold for moderation" do
      let(:signature_count) { 5 }

      let(:petition) do
        FactoryGirl.create(:validated_petition, {
          signature_count: signature_count,
          last_signed_at: 2.days.ago,
          updated_at: 2.days.ago
        })
      end

      before do
        expect(Site).to receive(:threshold_for_response).and_return(5)
      end

      it "records the time it happened" do
        petition.increment_signature_count!
        expect(petition.moderation_threshold_reached_at).to be_within(1.second).of(Time.current)
      end

      it "records changes the state from 'validated' to 'sponsored'" do
        expect {
          petition.increment_signature_count!
        }.to change{
          petition.state
        }.from(Petition::VALIDATED_STATE).to(Petition::SPONSORED_STATE)
      end
    end

    context "when the signature count is higher than the threshold for moderation" do
      let(:signature_count) { 100 }

      context "and moderation_threshold_reached_at is nil" do
        let(:petition) do
          FactoryGirl.create(:open_petition, {
            signature_count: signature_count,
            last_signed_at: 2.days.ago,
            updated_at: 2.days.ago,
            moderation_threshold_reached_at: nil
          })
        end

        it "doesn't change the state to sponsored" do
          expect {
            petition.increment_signature_count!
          }.not_to change{ petition.state }
        end

        it "doesn't update the moderation_threshold_reached_at column" do
          expect {
            petition.increment_signature_count!
          }.not_to change{ petition.moderation_threshold_reached_at }
        end
      end
    end

    context "when the signature count crosses the threshold for a response" do
      let(:signature_count) { 9 }

      before do
        expect(Site).to receive(:threshold_for_response).and_return(10)
      end

      it "records the time it happened" do
        petition.increment_signature_count!
        expect(petition.response_threshold_reached_at).to be_within(1.second).of(Time.current)
      end
    end

    context "when the signature count crosses the threshold for a debate" do
      let(:signature_count) { 99 }

      before do
        expect(Site).to receive(:threshold_for_debate).and_return(100)
      end

      it "records the time it happened" do
        petition.increment_signature_count!
        expect(petition.debate_threshold_reached_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "at_threshold_for_moderation?" do
    context "when moderation_threshold_reached_at is not present" do
      let(:petition) { FactoryGirl.create(:validated_petition, signature_count: signature_count) }

      before do
        expect(Site).to receive(:threshold_for_moderation).and_return(5)
      end

      context "and the signature count is less than the threshold" do
        let(:signature_count) { 4 }

        it "is falsey" do
          expect(petition.at_threshold_for_moderation?).to be_falsey
        end
      end

      context "and the signature count is equal than the threshold" do
        let(:signature_count) { 5 }

        it "is truthy" do
          expect(petition.at_threshold_for_moderation?).to be_truthy
        end
      end

      context "and the signature count is more than the threshold" do
        let(:signature_count) { 6 }

        it "is truthy" do
          expect(petition.at_threshold_for_moderation?).to be_truthy
        end
      end
    end

    context "when moderation_threshold_reached_at is present" do
      let(:petition) { FactoryGirl.create(:sponsored_petition) }

      before do
        expect(Site).not_to receive(:threshold_for_response)
      end

      it "is falsey" do
        expect(petition.at_threshold_for_moderation?).to be_falsey
      end
    end
  end

  describe "at_threshold_for_response?" do
    context "when response_threshold_reached_at is not present" do
      let(:petition) { FactoryGirl.create(:open_petition, signature_count: signature_count) }

      before do
        expect(Site).to receive(:threshold_for_response).and_return(10)
      end

      context "and the signature count is 2 or more less than the threshold" do
        let(:signature_count) { 8 }

        it "is falsey" do
          expect(petition.at_threshold_for_response?).to be_falsey
        end
      end

      context "and the signature count is 1 less than the threshold" do
        let(:signature_count) { 9 }

        it "is truthy" do
          expect(petition.at_threshold_for_response?).to be_truthy
        end
      end

      context "and the signature count equal to the threshold" do
        let(:signature_count) { 10 }

        it "is truthy" do
          expect(petition.at_threshold_for_response?).to be_truthy
        end
      end

      context "and the signature count is more than the threshold" do
        let(:signature_count) { 10 }

        it "is truthy" do
          expect(petition.at_threshold_for_response?).to be_truthy
        end
      end
    end

    context "when response_threshold_reached_at is present" do
      let(:petition) { FactoryGirl.create(:awaiting_petition) }

      before do
        expect(Site).not_to receive(:threshold_for_response)
      end

      it "is falsey" do
        expect(petition.at_threshold_for_response?).to be_falsey
      end
    end
  end

  describe 'at_threshold_for_debate?' do
    let(:petition) { FactoryGirl.create(:petition, signature_count: signature_count) }

    context 'when signature count is 1 less than the threshold' do
      let(:signature_count) { Site.threshold_for_debate - 1 }

      it 'is truthy' do
        expect(petition.at_threshold_for_debate?).to be_truthy
      end
    end

    context 'when signature count is equal to the threshold' do
      let(:signature_count) { Site.threshold_for_debate }

      it 'is truthy' do
        expect(petition.at_threshold_for_debate?).to be_truthy
      end
    end

    context 'when signature count is 1 or more than the threshold' do
      let(:signature_count) { Site.threshold_for_debate + 1 }

      it 'is truthy' do
        expect(petition.at_threshold_for_debate?).to be_truthy
      end
    end

    context 'when signature count is 2 or more less than the threshold' do
      let(:signature_count) { Site.threshold_for_debate - 2 }

      it 'is falsey' do
        expect(petition.at_threshold_for_debate?).to be_falsey
      end
    end

    context 'when the debate_threshold_reached_at is present' do
      let(:petition) { FactoryGirl.create(:awaiting_debate_petition) }

      it 'is falsey' do
        expect(petition.at_threshold_for_debate?).to be_falsey
      end
    end
  end

  describe '#publish' do
    subject(:petition) { FactoryGirl.create(:petition) }
    let(:now) { Time.current }
    let(:duration) { Site.petition_duration.months }
    let(:closing_date) { (now + duration).end_of_day }

    before do
      petition.publish
    end

    it "sets the state to OPEN" do
      expect(petition.state).to eq(Petition::OPEN_STATE)
    end

    it "sets the open date to now" do
      expect(petition.open_at).to be_within(1.second).of(now)
    end
  end

  describe "#reject" do
    subject(:petition) { FactoryGirl.create(:petition) }

    (Rejection::CODES - Rejection::HIDDEN_CODES).each do |rejection_code|
      context "when the reason for rejection is #{rejection_code}" do
        before do
          petition.reject(code: rejection_code)
          petition.reload
        end

        it "sets rejection.code to '#{rejection_code}'" do
          expect(petition.rejection.code).to eq(rejection_code)
        end

        it "sets Petition#state to 'rejected'" do
          expect(petition.state).to eq("rejected")
        end
      end
    end

    Rejection::HIDDEN_CODES.each do |rejection_code|
      context "when the reason for rejection is #{rejection_code}" do
        before do
          petition.reject(code: rejection_code)
          petition.reload
        end

        it "sets rejection.code to '#{rejection_code}'" do
          expect(petition.rejection.code).to eq(rejection_code)
        end

        it "sets Petition#state to 'hidden'" do
          expect(petition.state).to eq("hidden")
        end
      end
    end
  end

  describe '#close!' do
    subject(:petition) { FactoryGirl.create(:petition, debate_state: debate_state) }
    let(:now) { Time.current }
    let(:duration) { Site.petition_duration.months }
    let(:closing_date) { (now + duration).end_of_day }
    let(:debate_state) { 'pending' }

    before do
      petition.close!
    end

    it "sets the state to CLOSED" do
      expect(petition.state).to eq(Petition::CLOSED_STATE)
    end

    it "sets the closing date to now" do
      expect(petition.closed_at).to be_within(1.second).of(now)
    end

    context "when the debate state is 'pending'" do
      it "sets the debate state to 'closed'" do
        expect(petition.debate_state).to eq("closed")
      end
    end

    %w[awaiting debated none].each do |state|
      context "when the debate state is '#{state}'" do
        let(:debate_state) { state }

        it "doesn't change the debate state" do
          expect(petition.debate_state).to eq(state)
        end
      end
    end
  end

  describe '#flag' do
    subject(:petition) { FactoryGirl.create(:petition) }

    before do
      petition.flag
    end

    it "sets the state to FLAGGED" do
      expect(petition.state).to eq(Petition::FLAGGED_STATE)
    end
  end

  describe '#deadline' do
    let(:now) { Time.current }

    context 'for closed petitions' do
      let(:closed_at) { now + 1.day }
      subject(:petition) { FactoryGirl.build(:closed_petition, closed_at: closed_at) }

      it 'returns the closed_at timestamp' do
        expect(petition.closed_at).to eq closed_at
        expect(petition.deadline).to eq petition.closed_at
      end
    end

    context 'for open petitions' do
      subject(:petition) { FactoryGirl.build(:open_petition, open_at: now) }
      let(:duration) { Site.petition_duration.months }
      let(:closing_date) { (now + duration).end_of_day }

      it "returns the end of the day, #{Site.petition_duration.months} months after the open_at" do
        expect(petition.open_at).to eq now
        expect(petition.deadline).to eq closing_date
      end

      it "prefers any closed_at stamp that has been set" do
        petition.closed_at = now + 1.day
        expect(petition.deadline).not_to eq closing_date
        expect(petition.deadline).to eq petition.closed_at
      end
    end

    context 'for petitions in other states without an open_at' do
      subject(:petition) { FactoryGirl.build(:petition, open_at: nil) }
      it 'is nil' do
        expect(petition.deadline).to be_nil
      end
    end
  end

  describe "#validate_creator_signature!" do
    let(:petition) { FactoryGirl.create(:pending_petition, attributes) }
    let(:signature) { petition.creator_signature }

    let(:attributes) do
      { created_at: 2.days.ago, updated_at: 2.days.ago }
    end

    it "changes creator signature state to validated" do
      expect {
        petition.validate_creator_signature!
      }.to change { signature.reload.validated? }.from(false).to(true)
    end

    it "increments the signature count" do
      expect {
        petition.validate_creator_signature!
      }.to change { petition.signature_count }.by(1)
    end

    it "timestamps the petition to say it was updated just now" do
      petition.validate_creator_signature!
      expect(petition.updated_at).to be_within(1.second).of(Time.current)
    end

    it "timestamps the petition to say it was last signed at just now" do
      petition.validate_creator_signature!
      expect(petition.last_signed_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#id" do
    let(:petition){ FactoryGirl.create(:petition) }

    it "is greater than 100000" do
      expect(petition.id).to be >= 100000
    end
  end

  describe '#has_maximum_sponsors?' do
    it 'is true when flagged petition has reached maximum amount of sponsors' do
      flagged_petition = FactoryGirl.create(:flagged_petition, sponsor_count: Site.maximum_number_of_sponsors)
      expect(flagged_petition.has_maximum_sponsors?).to be_truthy
    end

    it 'is true when sponsored petition has reached maximum amount of sponsors' do
      sponsored_petition = FactoryGirl.create(:sponsored_petition, sponsor_count: Site.maximum_number_of_sponsors)
      expect(sponsored_petition.has_maximum_sponsors?).to be_truthy
    end

    it 'is true when validated petition has reached maximum amount of sponsors' do
      validated_petition = FactoryGirl.create(:validated_petition, sponsor_count: Site.maximum_number_of_sponsors)
      expect(validated_petition.has_maximum_sponsors?).to be_truthy
    end

    it 'is true when pending petition has reached maximum amount of sponsors' do
      pending_petition = FactoryGirl.create(:pending_petition, sponsor_count: Site.maximum_number_of_sponsors)
      expect(pending_petition.has_maximum_sponsors?).to be_truthy
    end

    it 'is false when flagged petition has not reached maximum amount of sponsors' do
      flagged_petition = FactoryGirl.create(:flagged_petition, sponsor_count: Site.maximum_number_of_sponsors - 1)
      expect(flagged_petition.has_maximum_sponsors?).to be_falsey
    end

    it 'is false when sponsored petition has not reached maximum amount of sponsors' do
      sponsored_petition = FactoryGirl.create(:sponsored_petition, sponsor_count: Site.maximum_number_of_sponsors - 1)
      expect(sponsored_petition.has_maximum_sponsors?).to be_falsey
    end

    it 'is false when validated petition has not reached maximum amount of sponsors' do
      validated_petition = FactoryGirl.create(:validated_petition, sponsor_count: Site.maximum_number_of_sponsors - 1)
      expect(validated_petition.has_maximum_sponsors?).to be_falsey
    end

    it 'is false when validated petition has not reached maximum amount of sponsors' do
      pending_petition = FactoryGirl.create(:pending_petition, sponsor_count: Site.maximum_number_of_sponsors - 1)
      expect(pending_petition.has_maximum_sponsors?).to be_falsey
    end
  end

  describe 'email requested receipts' do
    it { is_expected.to have_one(:email_requested_receipt).dependent(:destroy) }

    describe '#email_requested_receipt!' do
      let(:petition) { FactoryGirl.create(:petition) }

      it 'returns the existing db object if one exists' do
        existing = petition.create_email_requested_receipt
        expect(petition.email_requested_receipt!).to eq existing
      end

      it 'returns a newly created instance if does not already exist' do
        instance = petition.email_requested_receipt!
        expect(instance).to be_present
        expect(instance).to be_a(EmailRequestedReceipt)
        expect(instance.petition).to eq petition
        expect(instance.petition).to be_persisted
      end
    end

    describe '#get_email_requested_at_for' do
      let(:petition) { FactoryGirl.create(:open_petition) }
      let(:receipt) { petition.email_requested_receipt! }
      let(:the_stored_time) { 6.days.ago }

      it 'returns nil when nothing has been stamped for the supplied name' do
        expect(petition.get_email_requested_at_for('government_response')).to be_nil
      end

      it 'returns the stored timestamp for the supplied name' do
        receipt.update_column('government_response', the_stored_time)
        expect(petition.get_email_requested_at_for('government_response')).to eq the_stored_time
      end
    end

    describe '#set_email_requested_at_for' do
      let(:petition) { FactoryGirl.create(:open_petition) }
      let(:receipt) { petition.email_requested_receipt! }
      let(:the_stored_time) { 6.days.ago }

      it 'sets the stored timestamp for the supplied name to the supplied time' do
        petition.set_email_requested_at_for('government_response', to: the_stored_time)
        expect(receipt.government_response).to eq the_stored_time
      end

      it 'sets the stored timestamp for the supplied name to the current time if none is supplied' do
        travel_to the_stored_time do
          petition.set_email_requested_at_for('government_response')
          expect(receipt.government_response).to eq Time.current
        end
      end
    end

    describe "#signatures_to_email_for" do
      let!(:petition) { FactoryGirl.create(:petition) }
      let!(:creator_signature) { petition.creator_signature }
      let!(:other_signature) { FactoryGirl.create(:validated_signature, petition: petition) }
      let(:petition_timestamp) { 5.days.ago }

      before { petition.set_email_requested_at_for('government_response', to: petition_timestamp) }

      it 'raises an error if the petition does not have an email requested receipt' do
        petition.email_requested_receipt.destroy && petition.reload
        expect { petition.signatures_to_email_for('government_response') }.to raise_error ArgumentError
      end

      it 'raises an error if the petition does not have the requested timestamp in its email requested receipt' do
        petition.email_requested_receipt.update_column('government_response', nil)
        expect { petition.signatures_to_email_for('government_response') }.to raise_error ArgumentError
      end

      it "does not return those that do not want to be emailed" do
        petition.creator_signature.update_attribute(:notify_by_email, false)
        expect(petition.signatures_to_email_for('government_response')).not_to include creator_signature
      end

      it 'does not return unvalidated signatures' do
        other_signature.update_column(:state, Signature::PENDING_STATE)
        expect(petition.signatures_to_email_for('government_response')).not_to include other_signature
      end

      it 'does not return signatures that have a sent receipt newer than the petitions requested receipt' do
        other_signature.set_email_sent_at_for('government_response', to: petition_timestamp + 1.day)
        expect(petition.signatures_to_email_for('government_response')).not_to include other_signature
      end

      it 'does not return signatures that have a sent receipt equal to the petitions requested receipt' do
        other_signature.set_email_sent_at_for('government_response', to: petition_timestamp)
        expect(petition.signatures_to_email_for('government_response')).not_to include other_signature
      end

      it 'does return signatures that have a sent receipt older than the petitions requested receipt' do
        other_signature.set_email_sent_at_for('government_response', to: petition_timestamp - 1.day)
        expect(petition.signatures_to_email_for('government_response')).to include other_signature
      end

      it 'returns signatures that have no sent receipt, or null for the requested timestamp in their receipt' do
        other_signature.email_sent_receipt!.destroy && other_signature.reload
        creator_signature.email_sent_receipt!.update_column('government_response', nil)
        expect(petition.signatures_to_email_for('government_response')).to match_array [creator_signature, other_signature]
      end
    end
  end
end
