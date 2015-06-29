require 'rails_helper'

RSpec.describe Petition, type: :model do
  include ActiveJob::TestHelper

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

  context "callbacks" do
    context "stamp_government_response_at" do
      it "does not stamp the timestamp if no response and no response_summary is present" do
        petition = FactoryGirl.create(:open_petition)
        expect(petition.government_response_at).to be_nil
      end
      it "does not stamp the timestamp if either response_summary or response is missing" do
        petition = FactoryGirl.create(:open_petition, response: 'YEAH lets do it!')
        expect(petition.government_response_at).to be_nil
        petition = FactoryGirl.create(:open_petition, response_summary: 'Summary')
        expect(petition.government_response_at).to be_nil
      end
      it "stamps the timestamp if setting the response for the first time" do
        petition = FactoryGirl.create(:open_petition, response_summary: 'Summary', response: 'YEAH lets do it!')
        expect(petition.government_response_at).not_to be_nil
      end

      it "does not change the timestamp with subsequent response updates" do
        petition = FactoryGirl.create(:open_petition, response_summary: 'Summary', response: 'YEAH lets do it!')
        expect { petition.update(response: 'Sorry, promised too much') }.to_not change { petition.government_response_at }
      end
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:action).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:background).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:creator_signature).with_message(/must be completed/) }

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

    it "validates the length of :response_summary to within 500 characters" do
      expect(FactoryGirl.build(:petition, :response_summary => 'x' * 500)).to be_valid
      expect(FactoryGirl.build(:petition, :response_summary => 'x' * 501)).not_to be_valid
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

    %w(pending validated open rejected hidden).each do |state|
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

      it "checks petition is invalid if no closed_at date" do
        expect(petition).not_to be_valid
        expect(petition.errors[:closed_at]).not_to be_empty
      end

      it "checks petition is valid if there is a open_at and closed_at date" do
        petition.open_at = Time.current
        petition.closed_at = Time.current
        expect(petition).to be_valid
      end
    end

    context "when state is rejected" do
      let(:petition) { FactoryGirl.build(:petition, state: Petition::REJECTED_STATE) }

      it "checks petition is invalid if no rejection code" do
        expect(petition).not_to be_valid
        expect(petition.errors[:rejection_code]).not_to be_empty
      end

      it "checks there is a rejection code" do
        petition.rejection_code = 'libellous'
        expect(petition).to be_valid
      end
    end

    context "response" do
      let(:petition) { FactoryGirl.build(:petition, response: 'Hello', response_summary: 'Hi') }

      it "is valid if response and response_summary are nil" do
        petition.response_summary = nil
        petition.response = nil
        expect(petition).to be_valid
      end

      it "is valid if response is nil" do
        petition.response = nil
        expect(petition).to be_valid
      end

      it "is valid if response_summary are nil" do
        petition.response_summary = nil
        expect(petition).to be_valid
      end

      it "is invalid if response_summary is too long (500 chars)" do
        petition.response_summary = 'a' * 500
        expect(petition).to be_valid
        petition.response_summary += 'a'
        expect(petition).not_to be_valid
        expect(petition.errors[:response_summary]).not_to be_empty
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
        @p6 = FactoryGirl.create(:open_petition, :closed_at => 1.day.ago)
        @p7 = FactoryGirl.create(:petition, :state => Petition::SPONSORED_STATE)
      end

      it "returns 2 pending petitions" do
        petitions = Petition.for_state(Petition::PENDING_STATE)
        expect(petitions.size).to eq(2)
        expect(petitions).to include(@p1, @p3)
      end

      it "returns 1 validated, sponsored, open, closed and hidden petitions" do
        [[Petition::VALIDATED_STATE, @p2], [Petition::OPEN_STATE, @p4],
         [Petition::HIDDEN_STATE, @p5], [Petition::CLOSED_STATE, @p6], [Petition::SPONSORED_STATE, @p7]].each do |state_and_petition|
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
        @p1 = FactoryGirl.create(:open_petition, :closed_at => 1.day.from_now, :response_summary => "summary", :response => "govt response")
        @p2 = FactoryGirl.create(:open_petition, :closed_at => 1.day.ago, :response_summary => "summary", :response => "govt response")
        @p3 = FactoryGirl.create(:open_petition, :closed_at => 1.day.ago, :response => "govt response")
        @p4 = FactoryGirl.create(:open_petition, :closed_at => 1.day.from_now)
      end

      it "returns only the petitions which have governments response; both summary and the whole response" do
        expect(Petition.with_response).to match_array([@p1, @p2])
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

    context 'awaiting_debate_date' do
      before do
        @p1 = FactoryGirl.create(:open_petition)
        @p2 = FactoryGirl.create(:awaiting_debate_petition)
        @p3 = FactoryGirl.create(:debated_petition)
      end

      it 'returns only petitions that reached the debate threshold' do
        expect(Petition.awaiting_debate_date).to include(@p2)
      end

      it 'doesn\'t include petitions that has the debate date' do
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
        @selectable_petition_3 = FactoryGirl.create(:open_petition, :closed_at => 1.day.ago)
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
      petition_1.update_column(:closed_at, 3.days.ago)
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

  describe "can_be_signed?" do
    def petition(state = Petition::OPEN_STATE)
      FactoryGirl.build(:petition, :state => state)
    end

    it "is true if and only if the petition is OPEN and the closed_at date is in the future" do
      petition = FactoryGirl.build(:open_petition, :closed_at => 1.year.from_now)
      expect(petition.can_be_signed?).to be_truthy
    end

    it "is false if the petition is OPEN and the closed_at date is in the past" do
      petition = FactoryGirl.build(:open_petition, :closed_at => 2.minutes.ago)
      expect(petition.can_be_signed?).to be_falsey
    end

    it "is false otherwise" do
      expect(petition(Petition::PENDING_STATE).can_be_signed?).to be_falsey
      expect(petition(Petition::HIDDEN_STATE).can_be_signed?).to be_falsey
      expect(petition(Petition::REJECTED_STATE).can_be_signed?).to be_falsey
      expect(petition(Petition::VALIDATED_STATE).can_be_signed?).to be_falsey
      expect(petition(Petition::SPONSORED_STATE).can_be_signed?).to be_falsey
    end
  end

  describe "open?" do
    it "is open when state is open" do
      expect(FactoryGirl.build(:petition, :state => Petition::OPEN_STATE).open?).to  be_truthy
    end

    it "is not open when state is anything else" do
      [Petition::PENDING_STATE, Petition::VALIDATED_STATE, Petition::SPONSORED_STATE, Petition::REJECTED_STATE, Petition::HIDDEN_STATE].each do |state|
        expect(FactoryGirl.build(:petition, :state => state).open?).to be_falsey
      end
    end
  end

  describe "rejected?" do
    it "is rejected when state is rejected" do
      expect(FactoryGirl.build(:petition, :state => Petition::REJECTED_STATE).rejected?).to be_truthy
    end

    it "is not rejected when state is anything else" do
      [Petition::PENDING_STATE, Petition::VALIDATED_STATE, Petition::SPONSORED_STATE, Petition::OPEN_STATE, Petition::HIDDEN_STATE].each do |state|
        expect(FactoryGirl.build(:petition, :state => state).rejected?).to be_falsey
      end
    end
  end

  describe "hidden?" do
    it "is hidden when state is hidden" do
      expect(FactoryGirl.build(:petition, :state => Petition::HIDDEN_STATE).hidden?).to be_truthy
    end

    it "is not hidden when state is anything else" do
      [Petition::PENDING_STATE, Petition::VALIDATED_STATE, Petition::SPONSORED_STATE, Petition::OPEN_STATE, Petition::REJECTED_STATE].each do |state|
        expect(FactoryGirl.build(:petition, :state => state).hidden?).to be_falsey
      end
    end
  end

  describe "#in_moderation?" do
    it "is in moderation when the state is sponsored" do
      expect(FactoryGirl.build(:petition, :state => Petition::SPONSORED_STATE).in_moderation?).to be_truthy
    end
  end

  describe "#moderated?" do
    context "when the petition is hidden" do
      subject { FactoryGirl.create(:hidden_petition) }

      it "returns true" do
        expect(subject.moderated?).to eq(true)
      end
    end

    context "when the petition is rejected" do
      subject { FactoryGirl.create(:rejected_petition) }

      it "returns true" do
        expect(subject.moderated?).to eq(true)
      end
    end

    context "when the petition is open" do
      subject { FactoryGirl.create(:open_petition) }

      it "returns true" do
        expect(subject.moderated?).to eq(true)
      end
    end

    context "when the petition is closed" do
      subject { FactoryGirl.create(:closed_petition) }

      it "returns true" do
        expect(subject.moderated?).to eq(true)
      end
    end
  end

  describe "#in_todo_list?" do
    it "is in todo list when the state is sponsored" do
      expect(FactoryGirl.build(:petition, :state => Petition::SPONSORED_STATE).in_todo_list?).to be_truthy
    end

    it "is in todo list when the state is validated" do
      expect(FactoryGirl.build(:petition, :state => Petition::VALIDATED_STATE).in_todo_list?).to be_truthy
    end

    it "is in todo list when the state is pending" do
      expect(FactoryGirl.build(:petition, :state => Petition::PENDING_STATE).in_todo_list?).to be_truthy
    end
  end

  describe "rejection_reason" do
    it "gives rejection reason from the locale file" do
      petition = FactoryGirl.build(:rejected_petition, :rejection_code => 'duplicate')
      expect(petition.rejection_reason).to eq('Duplicate of an existing petition')
    end
  end

  describe "rejection_description" do
    it "gives rejection description from the locale file" do
      petition = FactoryGirl.build(:rejected_petition, :rejection_code => 'duplicate')
      expect(petition.rejection_description).to eq('<p>There is already a petition about this issue.</p>')
    end
  end

  describe "counting validated signatures" do
    let(:petition) { FactoryGirl.build(:petition) }

    it "only counts validated signtatures" do
      expect(petition.signatures).to receive(:validated).and_return(double(:valid_signatures, :count => 123))
      expect(petition.count_validated_signatures).to eq(123)
    end
  end

  describe "permissions" do
    let(:petition) { FactoryGirl.build(:petition) }
    let(:user) { AdminUser.new }

    it "is editable by a moderator user" do
      allow(user).to receive_messages(:is_a_moderator? => true)
      expect(petition.editable_by?(user)).to be_truthy
    end

    it "is editable by a sys admin" do
      allow(user).to receive_messages(:is_a_sysadmin? => true)
      expect(petition.editable_by?(user)).to be_truthy
    end

    it 'is editable by a normal admin user' do
      expect(petition.editable_by?(user)).to be_truthy
    end

    it 'is not editable by non admin users' do
      expect(petition.editable_by?(double)).to be_falsey
    end

    it "doesn't allow editing of response generally" do
      expect(petition.response_editable_by?(user)).to be_falsey
    end

    it "allows editing of the response by moderator users" do
      allow(user).to receive_messages(:is_a_moderator? => true)
      expect(petition.response_editable_by?(user)).to be_truthy
    end

    it "allows editing of the response by sysadmins" do
      allow(user).to receive_messages(:is_a_sysadmin? => true)
      expect(petition.response_editable_by?(user)).to be_truthy
    end

    it "doesn't allow editing of response summary generally" do
      expect(petition.response_summary_editable_by?(user)).to be_falsey
    end

    it "allows editing of the response summary by moderator users" do
      allow(user).to receive_messages(:is_a_moderator? => true)
      expect(petition.response_summary_editable_by?(user)).to be_truthy
    end

    it "allows editing of the response summary by sysadmins" do
      allow(user).to receive_messages(:is_a_sysadmin? => true)
      expect(petition.response_summary_editable_by?(user)).to be_truthy
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
      let(:signature_count) { 9 }

      before do
        expect(Site).to receive(:threshold_for_debate).and_return(10)
      end

      it "records the time it happened" do
        petition.increment_signature_count!
        expect(petition.debate_threshold_reached_at).to be_within(1.second).of(Time.current)
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

  describe '#publish!' do
    subject(:petition) { FactoryGirl.create(:petition) }
    let(:now) { Time.current }
    let(:duration) { Site.petition_duration.months }
    let(:closing_date) { (now + duration).end_of_day }

    before do
      petition.publish!
    end

    it "sets the state to OPEN" do
      expect(petition.state).to eq(Petition::OPEN_STATE)
    end

    it "sets the open date to now" do
      expect(petition.open_at).to be_within(1.second).of(now)
    end

    it "sets the closed date to the end of the day on the date #{Site.petition_duration} months from now" do
      expect(petition.closed_at).to be_within(1.second).of(closing_date)
    end
  end

  describe "#reject" do
    subject(:petition) { FactoryGirl.create(:petition) }

    %w[no-action duplicate irrelevant honours].each do |rejection_code|
      context "when the reason for rejection is #{rejection_code}" do
        before do
          petition.reject(rejection_code: rejection_code)
        end

        it "sets Petition#rejection_code to '#{rejection_code}'" do
          expect(petition.rejection_code).to eq(rejection_code)
        end

        it "sets Petition#state to 'rejected'" do
          expect(petition.state).to eq("rejected")
        end
      end
    end

    %w[libellous offensive].each do |rejection_code|
      context "when the reason for rejection is #{rejection_code}" do
        before do
          petition.reject(rejection_code: rejection_code)
        end

        it "sets Petition#rejection_code to '#{rejection_code}'" do
          expect(petition.rejection_code).to eq(rejection_code)
        end

        it "sets Petition#state to 'hidden'" do
          expect(petition.state).to eq("hidden")
        end
      end
    end
  end

  describe "#update_state_after_new_validated_sponsor!" do
    context "with sufficient sponsor count" do
      let(:petition){ FactoryGirl.create(:validated_petition, sponsors_signed: true) }

      it "sets state to sponsored" do
        expect{petition.update_state_after_new_validated_sponsor!}.to change{petition.state}
                                                                       .from(Petition::VALIDATED_STATE)
                                                                       .to(Petition::SPONSORED_STATE)
      end
    end
    context "with insufficient sponsor count" do
      let(:petition){ FactoryGirl.create(:validated_petition) }

      it "leaves state unchanged" do
        expect{petition.update_state_after_new_validated_sponsor!}.to_not change{petition.state}
      end
    end
    context "with first validated sponsor" do
      let(:petition){ FactoryGirl.create(:pending_petition) }
      let(:sponsor){ FactoryGirl.create(:sponsor, :validated, petition: petition) }

      it "changes state to validated" do
        sponsor.reload
        expect{petition.update_state_after_new_validated_sponsor!}.to change{petition.state}
                                                                       .from(Petition::PENDING_STATE)
                                                                       .to(Petition::VALIDATED_STATE)
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

  describe "#validated_creator_signature?" do
    context "when the creator signature is not validated" do
      let(:petition) { FactoryGirl.create(:pending_petition, creator_signature: signature) }
      let(:signature) { FactoryGirl.create(:pending_signature) }

      it "returns false" do
        expect(petition.validated_creator_signature?).to eq(false)
      end
    end

    context "when the creator signature is validated" do
      let(:petition) { FactoryGirl.create(:pending_petition, creator_signature: signature) }
      let(:signature) { FactoryGirl.create(:validated_signature) }

      it "returns false" do
        expect(petition.validated_creator_signature?).to eq(true)
      end
    end
  end

  describe "#notify_creator_about_sponsor_support", immediate_delayed_job_work_off: true do
    subject { FactoryGirl.create(:petition, sponsor_count: Site.threshold_for_moderation) }
    before { ActionMailer::Base.deliveries.clear }

    it 'breaks if the provided sponsor does not belong to the petition' do
      expect {
        subject.notify_creator_about_sponsor_support(FactoryGirl.create(:sponsor))
      }.to raise_error(ArgumentError)
    end

    it 'breaks if the provided sponsor does belong to the petition, but is not a supporting sponsor' do
      expect {
        subject.notify_creator_about_sponsor_support(subject.sponsors.first)
      }.to raise_error(ArgumentError)
    end

    context 'when the petition is below the sponsor moderation threshold' do
      let(:sponsor) { subject.sponsors.first }
      before { sponsor.create_signature!(FactoryGirl.attributes_for(:validated_signature)) }

      it 'sends an email to the petition creator telling them about the sponsor' do
        perform_enqueued_jobs do
          subject.notify_creator_about_sponsor_support(sponsor)
          email = ActionMailer::Base.deliveries.last
          expect(email.from).to eq(["no-reply@test.epetitions.website"])
          expect(email.to).to eq([subject.creator_signature.email])
          expect(email.subject).to match(/has received support from a sponsor/)
        end
      end
    end

    context 'when the petition is on the sponsor moderation threshold' do
      let(:sponsor) { subject.sponsors.first }
      subject { FactoryGirl.create(:validated_petition, sponsors_signed: true) }

      it 'sends an email to the petition creator telling them about the sponsor' do
        perform_enqueued_jobs do
          subject.notify_creator_about_sponsor_support(sponsor)
          email = ActionMailer::Base.deliveries.last
          expect(email.from).to eq(["no-reply@test.epetitions.website"])
          expect(email.to).to eq([subject.creator_signature.email])
          expect(email.subject).to match(/has received support from a sponsor/)
        end
      end

    end

    context 'when the petition is above the sponsor moderation threshold' do
      subject { FactoryGirl.create(:validated_petition, sponsor_count: 6, sponsors_signed: true) }
      let(:sponsor) { subject.sponsors.last }

      it 'does not send an email to the petition creator telling them about the sponsor' do
        subject.notify_creator_about_sponsor_support(sponsor)
        email = ActionMailer::Base.deliveries.last
        expect(email).to be_nil
      end
    end
  end

  describe "#id" do
    let(:petition){ FactoryGirl.create(:petition) }

    it "is greater than 100000" do
      expect(petition.id).to be >= 100000
    end
  end

  describe '#has_maximum_sponsors?' do
    it 'is true when sponsored petition has reached maximum amount of sponsors' do
      sponsored_petition = FactoryGirl.create(:sponsored_petition, sponsor_count: Site.maximum_number_of_sponsors)
      expect(sponsored_petition.has_maximum_sponsors?).to be_truthy
    end

    it 'is true when validated petition has reached maximum amount of sponsors' do
      sponsored_petition = FactoryGirl.create(:validated_petition, sponsor_count: Site.maximum_number_of_sponsors)
      expect(sponsored_petition.has_maximum_sponsors?).to be_truthy
    end

    it 'is true when pending petition has reached maximum amount of sponsors' do
      sponsored_petition = FactoryGirl.create(:pending_petition, sponsor_count: Site.maximum_number_of_sponsors)
      expect(sponsored_petition.has_maximum_sponsors?).to be_truthy
    end

    it 'is false when sponsored petition has not reached maximum amount of sponsors' do
      sponsored_petition = FactoryGirl.create(:sponsored_petition, sponsor_count: Site.maximum_number_of_sponsors - 1)
      expect(sponsored_petition.has_maximum_sponsors?).to be_falsey
    end

    it 'is false when validated petition has not reached maximum amount of sponsors' do
      sponsored_petition = FactoryGirl.create(:validated_petition, sponsor_count: Site.maximum_number_of_sponsors - 1)
      expect(sponsored_petition.has_maximum_sponsors?).to be_falsey
    end

    it 'is false when validated petition has not reached maximum amount of sponsors' do
      sponsored_petition = FactoryGirl.create(:pending_petition, sponsor_count: Site.maximum_number_of_sponsors - 1)
      expect(sponsored_petition.has_maximum_sponsors?).to be_falsey
    end
  end

  describe 'debate outcomes' do
    it { is_expected.to have_one(:debate_outcome).dependent(:destroy) }
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
      include ActiveSupport::Testing::TimeHelpers

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
