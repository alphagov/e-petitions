require 'rails_helper'

describe Petition do
  include ActiveJob::TestHelper

  context "defaults" do
    it "has pending as default state" do
      p = Petition.new
      expect(p.state).to eq("pending")
    end

    it "defaults to false for email signees" do
      p = Petition.new
      expect(p.email_signees).to be_falsey
    end

    it "generates sponsor token" do
      p = FactoryGirl.create(:petition, :sponsor_token => nil)
      expect(p.sponsor_token).not_to be_nil
    end
  end

  context "callbacks" do
    context "stamp_parliament_response_at" do
      it "does not stamp the timestamp if no response and no response_summary is present" do
        petition = FactoryGirl.create(:open_petition)
        expect(petition.parliament_response_at).to be_nil
      end
      it "does not stamp the timestamp if either response_summary or response is missing" do
        petition = FactoryGirl.create(:open_petition, response: 'YEAH lets do it!')
        expect(petition.parliament_response_at).to be_nil
        petition = FactoryGirl.create(:open_petition, response_summary: 'Summary')
        expect(petition.parliament_response_at).to be_nil
      end
      it "stamps the timestamp if setting the response for the first time" do
        petition = FactoryGirl.create(:open_petition, response_summary: 'Summary', response: 'YEAH lets do it!')
        expect(petition.parliament_response_at).not_to be_nil
      end

      it "does not change the timestamp with subsequent response updates" do
        petition = FactoryGirl.create(:open_petition, response_summary: 'Summary', response: 'YEAH lets do it!')
        expect { petition.update(response: 'Sorry, promised too much') }.to_not change { petition.parliament_response_at }
      end
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:title).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:action).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:description).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:creator_signature).with_message(/must be completed/) }

    it "should validate the length of :title to within 80 characters" do
      expect(FactoryGirl.build(:petition, :title => 'x' * 80)).to be_valid
      expect(FactoryGirl.build(:petition, :title => 'x' * 81)).not_to be_valid
    end

    it "should validate the length of :action to within 300 characters" do
      expect(FactoryGirl.build(:petition, :action => 'x' * 300)).to be_valid
      expect(FactoryGirl.build(:petition, :action => 'x' * 301)).not_to be_valid
    end

    it "should validate the length of :description to within 800 characters" do
      expect(FactoryGirl.build(:petition, :description => 'x' * 800)).to be_valid
      expect(FactoryGirl.build(:petition, :description => 'x' * 801)).not_to be_valid
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
      let(:petition) { FactoryGirl.build(:petition, response: 'Hello', response_summary: 'Hi', email_signees: true) }

      it "passes validation if there is a response and response summary when email_signees is true" do
        expect(petition).to be_valid
      end

      it "does not pass validation if there is a response and NO response summary when email_signees is true" do
        petition.response_summary = nil
        expect(petition).to_not be_valid
      end

      it "does not pass validation if there is NO response and a response summary when email_signees is true" do
        petition.response = nil
        expect(petition).to_not be_valid
      end

      it "checks petition is valid if there is a response and response summary when email_signees is true" do
        expect(petition).to be_valid
      end

      it "checks petition is invalid if there is no response when email_signees is true" do
        petition.response = nil
        petition.email_signees = true

        expect(petition).not_to be_valid
        expect(petition.errors[:response]).not_to be_empty
      end

      it "checks petition is invalid if there is no response summary when email_signees is true" do
        petition.response_summary = nil
        petition.email_signees = true

        expect(petition).not_to be_valid
        expect(petition.errors[:response_summary]).not_to be_empty
      end
    end
  end

  context "scopes" do
    describe "last_hour_trending" do
      before(:each) do
        11.times do |count|
          petition = FactoryGirl.create(:open_petition, :title => "petition ##{count+1}")
          count.times { FactoryGirl.create(:validated_signature, :petition => petition) }
        end

        @petition_with_old_signatures = FactoryGirl.create(:open_petition, :title => "petition out of range")
        @petition_with_old_signatures.signatures.first.update_attribute(:updated_at, 2.hours.ago)
      end

      it "returns petitions trending for the last hour" do
        expect(Petition.last_hour_trending.map(&:id).include?(@petition_with_old_signatures.id)).to be_falsey
      end

      it "returns the signature count for the last hour as an additional attribute" do
        expect(Petition.last_hour_trending.first.signatures_in_last_hour).to eq(11)
        expect(Petition.last_hour_trending.last.signatures_in_last_hour).to eq(9)
      end

      it "limits the result to 3 petitions" do
        # 13 petitions signed in the last hour
        2.times do |count|
          petition = FactoryGirl.create(:open_petition, :title => "petition ##{count+1}")
          count.times { FactoryGirl.create(:validated_signature, :petition => petition) }
        end

        expect(Petition.last_hour_trending.to_a.size).to eq(3)
      end

      it "excludes petitions that are not open" do
        petition = FactoryGirl.create(:validated_petition)
        20.times{ FactoryGirl.create(:validated_signature, :petition => petition) }

        expect(Petition.last_hour_trending.to_a).not_to include(petition)
      end
    end

    describe "trending" do
      before(:each) do
        15.times do |count|
          petition = FactoryGirl.create(:open_petition, :title => "petition ##{count+1}")
          count.times { FactoryGirl.create(:validated_signature, :petition => petition) }
        end

        @petition_with_old_signatures = FactoryGirl.create(:open_petition, :title => "petition out of range")
        10.times { FactoryGirl.create(:validated_signature, :petition => @petition_with_old_signatures, :updated_at => 2.days.ago) }
      end

      context "finding trending petitions for the last 24 hours" do
        it "only returns 10 petitions" do
          expect(Petition.trending(1).to_a.size).to eq(10)
        end

        it "orders the petitions by the highest signature count" do
          trending_petitions = Petition.trending(1)
          expect(trending_petitions.first.title).to eq("petition #15")
          expect(trending_petitions.last.title).to  eq("petition #6")
        end

        it "ignores petitions with signatures that are outside a rolling 24 hour period" do
          expect(Petition.trending(1).map(&:title).include?(@petition_with_old_signatures.title)).to be_falsey
        end
      end

      context "finding trending petitions for the last 7 days" do
        it "includes the petition with older signatures" do
          expect(Petition.trending(7).map(&:title).include?(@petition_with_old_signatures.title)).to be_truthy
        end
      end

      context "when there are validated petitions" do
        it "excludes petitions that are not open" do
          petition = FactoryGirl.create(:validated_petition)
          20.times{ FactoryGirl.create(:validated_signature, :petition => petition) }

          expect(Petition.trending(1).to_a).not_to include(petition)
        end
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
        @p5 = FactoryGirl.create(:open_petition, :response_required => true)
        @p6 = FactoryGirl.create(:open_petition, :response_required => false)
      end

      it "returns 4 petitions over the threshold or marked as requiring a response" do
        petitions = Petition.threshold
        expect(petitions.size).to eq(4)
        expect(petitions).to include(@p1, @p2, @p4, @p5)
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
    before :each do
      @petition = FactoryGirl.create(:open_petition)
      @petition.creator_signature.update_attribute(:state, Signature::VALIDATED_STATE)
      Petition.update_all_signature_counts
    end

    it "returns 1 (the creator) for a new petition" do
      @petition.reload
      expect(@petition.signature_count).to eq(1)
    end

    it "still returns 1 with a new signature" do
      FactoryGirl.create(:signature, :petition => @petition)
      @petition.reload
      expect(@petition.signature_count).to eq(1)
    end

    it "returns 2 when signature is validated" do
      s = FactoryGirl.create(:signature, :petition => @petition)
      s.update_attribute(:state, Signature::VALIDATED_STATE)
      Petition.update_all_signature_counts
      @petition.reload
      expect(@petition.signature_count).to eq(2)
    end
  end

  describe "can_be_signed?" do
    def petition(state = Petition::OPEN_STATE)
      @petition ||= FactoryGirl.create(:petition, :state => state)
    end

    it "is true if and only if the petition is OPEN and the closed_at date is in the future" do
      petition = FactoryGirl.create(:open_petition, :closed_at => 1.year.from_now)
      expect(petition.can_be_signed?).to be_truthy
    end

    it "is false if the petition is OPEN and the closed_at date is in the past" do
      petition = FactoryGirl.create(:open_petition, :closed_at => 2.minutes.ago)
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

  describe "rejection_reason" do
    it "gives rejection reason from the locale file" do
      petition = FactoryGirl.build(:rejected_petition, :rejection_code => 'duplicate')
      expect(petition.rejection_reason).to eq('Duplicate of an existing e-petition')
    end
  end

  describe "rejection_description" do
    it "gives rejection description from the locale file" do
      petition = FactoryGirl.build(:rejected_petition, :rejection_code => 'duplicate')
      expect(petition.rejection_description).to eq('<p>There is already an e-petition about this issue.</p>')
    end
  end

  describe "updating signature counts" do
    let(:petition) { double }
    before do
      allow(Petition).to receive_messages(:visible => [petition])
    end
    it "calls update signature counts for each petition" do
      allow(petition).to receive(:count_validated_signatures).and_return(123)
      allow(petition).to receive(:signature_count).and_return(122)
      expect(petition).to receive(:update_attribute).with(:signature_count, 123)
      Petition.update_all_signature_counts
    end
    it "doesn't change signature counts when not changed" do
      allow(petition).to receive(:count_validated_signatures).and_return(122)
      allow(petition).to receive(:signature_count).and_return(122)
      expect(petition).not_to receive(:update_attribute).with(:signature_count, 122)
      Petition.update_all_signature_counts
    end
  end

  describe "counting validated signatures" do
    let(:petition) { FactoryGirl.build(:petition) }

    it "only counts validated signtatures" do
      expect(petition.signatures).to receive(:validated).and_return(double(:valid_signatures, :count => 123))
      expect(petition.count_validated_signatures).to eq(123)
    end
  end

  describe "signatures that need emailing" do
    let(:petition) { FactoryGirl.create(:petition) }
    it "returns validated signatures" do
      expect(petition.need_emailing).to eq([petition.creator_signature])
    end

    it "only returns those yet to be emailed" do
      petition.creator_signature.update_attribute(:last_emailed_at, Time.now)
      expect(petition.need_emailing).to eq([])
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

  describe ".counts_by_state" do
    it "returns a hash containing counts of petition states" do
      1.times { FactoryGirl.create(:pending_petition) }
      2.times { FactoryGirl.create(:validated_petition) }
      3.times { FactoryGirl.create(:sponsored_petition) }
      4.times { FactoryGirl.create(:open_petition) }
      5.times { FactoryGirl.create(:closed_petition) }
      6.times { FactoryGirl.create(:rejected_petition) }
      7.times { FactoryGirl.create(:hidden_petition) }

      # Petition.counts_by_state.class.should == Hash

      expect(Petition.counts_by_state[:pending]).to   eq(1)
      expect(Petition.counts_by_state[:validated]).to eq(2)
      expect(Petition.counts_by_state[:sponsored]).to eq(3)
      expect(Petition.counts_by_state[:open]).to      eq(4)
      expect(Petition.counts_by_state[:closed]).to    eq(5)
      expect(Petition.counts_by_state[:rejected]).to  eq(6)
      expect(Petition.counts_by_state[:hidden]).to    eq(7)
    end
  end

  describe '#publish!' do
    subject { FactoryGirl.create(:petition) }
    let(:now) { Chronic.parse("1 Jan 2011") }
    before { allow(Time).to receive(:current).and_return(now) }

    it "sets the state to OPEN" do
      subject.publish!
      expect(subject.state).to eq(Petition::OPEN_STATE)
    end

    it "sets the open date to now" do
      subject.publish!
      expect(subject.open_at.change(usec: 0)).to eq(now.change(usec: 0))
    end

    it "sets the closed date to the end of the day on the date #{Site.petition_duration} months from now" do
      subject.publish!
      expect(subject.closed_at.change(usec: 0)).to eq( (now + Site.petition_duration.months).end_of_day.change(usec: 0) )
    end
  end

  describe "#reject" do
    subject { FactoryGirl.create(:petition) }

    %w[no-action duplicate irrelevant honours].each do |rejection_code|
      context "when the reason for rejection is #{rejection_code}" do
        before do
          subject.reject(rejection_code: rejection_code)
        end

        it "sets Petition#rejection_code to '#{rejection_code}'" do
          expect(subject.rejection_code).to eq(rejection_code)
        end

        it "sets Petition#state to 'rejected'" do
          expect(subject.state).to eq("rejected")
        end
      end
    end

    %w[libellous offensive].each do |rejection_code|
      context "when the reason for rejection is #{rejection_code}" do
        before do
          subject.reject(rejection_code: rejection_code)
        end

        it "sets Petition#rejection_code to '#{rejection_code}'" do
          expect(subject.rejection_code).to eq(rejection_code)
        end

        it "sets Petition#state to 'hidden'" do
          expect(subject.state).to eq("hidden")
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
    context "with first validated sponsor" do

      let(:petition){ FactoryGirl.create(:pending_petition) }
      let(:sponsor){ FactoryGirl.create(:sponsor, :validated, petition: petition) }

      it "changes creator signature state to validated" do
        sponsor.reload
        expect{petition.validate_creator_signature!}.to change{petition.creator_signature.state}
                                                         .from(Signature::PENDING_STATE)
                                                         .to(Signature::VALIDATED_STATE)
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
end
