# == Schema Information
#
# Table name: petitions
#
#  id                      :integer(4)      not null, primary key
#  title                   :string(255)     not null
#  description             :text
#  response                :text
#  state                   :string(10)      default("pending"), not null
#  open_at                 :datetime
#  department_id           :integer(4)      not null
#  creator_signature_id    :integer(4)      not null
#  created_at              :datetime
#  updated_at              :datetime
#  creator_id              :integer(4)
#  rejection_text          :text
#  closed_at               :datetime
#  signature_count         :integer(4)      default(0)
#  response_required       :boolean(1)      default(FALSE)
#  internal_response       :text
#  rejection_code          :string(50)
#  notified_by_email       :boolean(1)      default(FALSE)
#  duration                :string(2)       default("12")
#  email_requested_at      :datetime
#  get_an_mp_email_sent_at :datetime
#

require 'rails_helper'

describe Petition do
  context "defaults" do
    it "state should default to pending" do
      p = Petition.new
      expect(p.state).to eq("pending")
    end

    it "email signees should default to false" do
      p = Petition.new
      expect(p.email_signees).to be_falsey
    end

    it "duration should default to 12" do
      p = Petition.new
      expect(p.duration).to eq("12")
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:title).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:action).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:description).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:duration).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:department).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:creator_signature).with_message(/must be completed/) }

    context "sponsor validations" do

      it 'is valid with 5 sponsor emails' do
        sponsor_emails = ['test1@test.com', 'test2@test.com', 'test3@test.com', 'test4@test.com', 'test5@test.com']
        expect(FactoryGirl.create(:petition, sponsor_emails: sponsor_emails)).to be_valid
      end

      it 'is not valid with less than 5 sponsor emails' do
        sponsor_emails = ['test1@test.com', 'test2@test.com']
        expect(FactoryGirl.build(:petition, sponsor_emails: sponsor_emails)).not_to be_valid
      end

      it 'is not valid with more than 20 sponsor emails' do
        sponsor_emails = (1..25).map { |i| "sponsor#{i}@example.com" }
        expect(FactoryGirl.build(:petition, sponsor_emails: sponsor_emails)).not_to be_valid
      end

      it 'is not valid with invalid sponsor emails' do
        sponsor_emails = ['test1test', 'test2@test.com', 'test3@test.com', 'test4@test.com', 'test5@test.com']
        expect(FactoryGirl.build(:petition, sponsor_emails: sponsor_emails)).not_to be_valid
      end

      it 'is not valid with duplicate sponsor emails' do
        sponsor_emails = ['test1@test.com', 'test1@test.com', 'test3@test.com', 'test4@test.com', 'test5@test.com']
        expect(FactoryGirl.build(:petition, sponsor_emails: sponsor_emails)).not_to be_valid
      end

    end

    it "should validate the length of :title to within 150 characters" do
      expect(FactoryGirl.build(:petition, :title => 'x' * 150)).to be_valid
      expect(FactoryGirl.build(:petition, :title => 'x' * 151)).not_to be_valid
    end

    it "should validate the length of :action to within 200 characters" do
      expect(FactoryGirl.build(:petition, :action => 'x' * 200)).to be_valid
      expect(FactoryGirl.build(:petition, :action => 'x' * 201)).not_to be_valid
    end

    it "should validate the length of :description to within 1000 characters" do
      expect(FactoryGirl.build(:petition, :description => 'x' * 1000)).to be_valid
      expect(FactoryGirl.build(:petition, :description => 'x' * 1001)).not_to be_valid
    end

    it "should not allow blank or unknown state" do
      p = FactoryGirl.build(:petition, :state => '')
      expect(p.errors_on(:state)).not_to be_blank
      p.state = 'unknown'
      expect(p.errors_on(:state)).not_to be_blank
    end

    it "should allow known states" do
      p = FactoryGirl.build(:petition)
      %w(pending validated open rejected hidden).each do |state|
        p.state = state
        expect(p.errors_on(:state)).to be_blank
      end
    end

    context "when state is open" do
      let(:petition) { FactoryGirl.build(:open_petition, :open_at => nil, :closed_at => nil) }

      it "should check petition is invalid if no open_at date" do
        expect(petition).not_to be_valid
        expect(petition.errors_on(:open_at)).not_to be_blank
      end

      it "should check petition is invalid if no closed_at date" do
        expect(petition).not_to be_valid
        expect(petition.errors_on(:closed_at)).not_to be_blank
      end

      it "should check petition is valid if there is a open_at and closed_at date" do
        petition.open_at = Time.zone.now
        petition.closed_at = Time.zone.now
        expect(petition).to be_valid
      end
    end

    context "when state is rejected" do
      let(:petition) { FactoryGirl.build(:petition, :state => Petition::REJECTED_STATE) }

      it "should check petition is invalid if no rejection code" do
        expect(petition).not_to be_valid
        expect(petition.errors_on(:rejection_code)).not_to be_blank
      end

      it "should check there is a rejection code" do
        petition.rejection_code = 'libellous'
        expect(petition).to be_valid
      end
    end

    context "response" do
      let(:petition) { FactoryGirl.build(:petition, :response => 'Hello', :email_signees => false) }

      it "should check petition is valid if there is a response when email_signees is true" do
        expect(petition).to be_valid
      end

      it "should check petition is invalid if there is no response when email_signees is true" do
        petition.response = nil
        petition.email_signees = true
        expect(petition.errors_on(:response)).not_to be_blank
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
        expect(Petition.last_hour_trending.last.signatures_in_last_hour).to eq(1)
      end

      it "limits the result to 12 petitions" do
        # 13 petitions signed in the last hour
        2.times do |count|
          petition = FactoryGirl.create(:open_petition, :title => "petition ##{count+1}")
          count.times { FactoryGirl.create(:validated_signature, :petition => petition) }
        end

        expect(Petition.last_hour_trending.to_a.size).to eq(12)
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
        FactoryGirl.create(:system_setting, :key => SystemSetting::THRESHOLD_SIGNATURE_COUNT, :value => "100000")
        @p5 = FactoryGirl.create(:open_petition, :response_required => true)
        @p6 = FactoryGirl.create(:open_petition, :response_required => false)
      end

      it "should return 4 petitions over the threshold or marked as requiring a response" do
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

      it "should return 2 pending petitions" do
        petitions = Petition.for_state(Petition::PENDING_STATE)
        expect(petitions.size).to eq(2)
        expect(petitions).to include(@p1, @p3)
      end

      it "should return 1 validated, sponsored, open, closed and hidden petitions" do
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

    context "for_departments" do
      before :each do
        @d1 = FactoryGirl.create(:department)
        @d2 = FactoryGirl.create(:department)
        @d3 = FactoryGirl.create(:department)
        @p1 = FactoryGirl.create(:petition, :department => @d1)
        @p2 = FactoryGirl.create(:petition, :department => @d1)
        @p3 = FactoryGirl.create(:petition, :department => @d3)
      end

      it "should return all petitiions for d1" do
        expect(Petition.for_departments([@d1]).size).to eq(2)
        expect(Petition.for_departments([@d1])).to include(@p1, @p2)
      end

      it "should return 0 petitions for d2" do
        expect(Petition.for_departments([@d2]).size).to eq(0)
      end

      it "should return 1 petition for d3" do
        expect(Petition.for_departments([@d3]).size).to eq(1)
        expect(Petition.for_departments([@d3])).to eq([@p3])
      end

      it "should return all petitions for d1, d2 and d3" do
        expect(Petition.for_departments([@d1, @d2, @d3]).size).to eq(3)
        expect(Petition.for_departments([@d1, @d2, @d3])).to include(@p1, @p2, @p3)
      end

      it "should return 0 for no departments" do
        expect(Petition.for_departments([]).size).to eq(0)
      end
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

  describe "signature counts by postal code" do
    let(:petition) { FactoryGirl.create(:open_petition) }
    subject { petition.signature_counts_by_postal_district }

    before do
      5.times { FactoryGirl.create(:signature, :petition => petition, :postcode => "SO23 0AA") }
      2.times { FactoryGirl.create(:signature, :petition => petition, :postcode => "so231BB") }
      1.times { FactoryGirl.create(:signature, :petition => petition, :postcode => "b171wi") }
    end

    it "returns a hash of counts" do
      expect(subject["SO23"]).to eq(7)
      expect(subject["B17"]).to eq(1)
    end

    it "only returns validated signatures" do
      FactoryGirl.create(:pending_signature, :petition => @petition, :postcode => "b17 1SS")
      expect(subject["B17"]).to eq(1)
    end

    it "ignores special signatures" do
      FactoryGirl.create(:pending_signature, :petition => @petition, :postcode => "BFPO 1234")
      expect(subject[""]).to eq(0)
    end
  end

  describe "email_all_who_passed_finding_mp_threshold" do
    let(:deliverer) { double(:deliver_now => true) }
    let(:petition) { FactoryGirl.create(:open_petition) }

    before do
      FactoryGirl.create(:system_setting, :key => SystemSetting::GET_AN_MP_SIGNATURE_COUNT, :value => "10")
      allow(PetitionMailer).to receive_messages(:ask_creator_to_find_an_mp => deliverer)
    end

    it "emails those who have passed the threshold" do
      expect(PetitionMailer).to receive(:ask_creator_to_find_an_mp).with(petition).and_return(deliverer)
      petition.update_attribute(:signature_count, 10)
      Petition.email_all_who_passed_finding_mp_threshold
    end

    it "does not send the email if you are below the threshold" do
      expect(PetitionMailer).not_to receive(:ask_creator_to_find_an_mp)
      petition.update_attribute(:signature_count, 2)
      Petition.email_all_who_passed_finding_mp_threshold
    end

    it "does not send if the petition is not open" do
      expect(PetitionMailer).not_to receive(:ask_creator_to_find_an_mp)
      petition.update_attribute(:signature_count, 10)
      petition.update_attribute(:state, Petition::CLOSED_STATE)
      Petition.email_all_who_passed_finding_mp_threshold
    end

    it "does not send the email again after sending once" do
      expect(PetitionMailer).to receive(:ask_creator_to_find_an_mp).once.and_return(deliverer)
      petition.update_attribute(:signature_count, 10);
      Petition.email_all_who_passed_finding_mp_threshold
      Petition.email_all_who_passed_finding_mp_threshold
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
    it "should be open when state is open" do
      expect(FactoryGirl.build(:petition, :state => Petition::OPEN_STATE).open?).to  be_truthy
    end

    it "should be not be open when state is anything else" do
      [Petition::PENDING_STATE, Petition::VALIDATED_STATE, Petition::SPONSORED_STATE, Petition::REJECTED_STATE, Petition::HIDDEN_STATE].each do |state|
        expect(FactoryGirl.build(:petition, :state => state).open?).to be_falsey
      end
    end
  end

  describe "rejected?" do
    it "should be rejected when state is rejected" do
      expect(FactoryGirl.build(:petition, :state => Petition::REJECTED_STATE).rejected?).to be_truthy
    end

    it "should be not be rejected when state is anything else" do
      [Petition::PENDING_STATE, Petition::VALIDATED_STATE, Petition::SPONSORED_STATE, Petition::OPEN_STATE, Petition::HIDDEN_STATE].each do |state|
        expect(FactoryGirl.build(:petition, :state => state).rejected?).to be_falsey
      end
    end
  end

  describe "hidden?" do
    it "should be hidden when state is hidden" do
      expect(FactoryGirl.build(:petition, :state => Petition::HIDDEN_STATE).hidden?).to be_truthy
    end

    it "should be not be hidden when state is anything else" do
      [Petition::PENDING_STATE, Petition::VALIDATED_STATE, Petition::SPONSORED_STATE, Petition::OPEN_STATE, Petition::REJECTED_STATE].each do |state|
        expect(FactoryGirl.build(:petition, :state => state).hidden?).to be_falsey
      end
    end
  end

  describe "rejection_reason" do
    it "should give rejection reason from json file" do
      petition = FactoryGirl.build(:rejected_petition, :rejection_code => 'duplicate')
      expect(petition.rejection_reason).to eq('Duplicate of an existing e-petition')
    end
  end

  describe "rejection_description" do
    it "should give rejection description from json file" do
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

    it "should only count validated signtatures" do
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
    let(:user) { double(:is_a_threshold? => false, :is_a_sysadmin? => false) }

    it "is editable by moderators in the same department" do
      allow(user).to receive_messages(:departments => [petition.department])
      expect(petition.editable_by?(user)).to be_truthy
    end

    it "is not editable by a moderator in another department" do
      allow(user).to receive_messages(:departments => [])
      expect(petition.editable_by?(user)).to be_falsey
    end
    it "is editable by a threshold user" do
      allow(user).to receive_messages(:is_a_threshold? => true)
      expect(petition.editable_by?(user)).to be_truthy
    end

    it "is editable by a sys admin" do
      allow(user).to receive_messages(:is_a_sysadmin? => true)
      expect(petition.editable_by?(user)).to be_truthy
    end

    it "doesn't allow editing of response generally" do
      expect(petition.response_editable_by?(user)).to be_falsey
    end

    it "allows editing of the response by threshold users" do
      allow(user).to receive_messages(:is_a_threshold? => true)
      expect(petition.response_editable_by?(user)).to be_truthy
    end

    it "allows editing of the response by sysadmins" do
      allow(user).to receive_messages(:is_a_sysadmin? => true)
      expect(petition.response_editable_by?(user)).to be_truthy
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

  describe "#reassign!" do
    let(:petition){ FactoryGirl.create(:petition) }
    let(:department){ FactoryGirl.create(:department) }

    it "takes a department id and saves the petition" do
      petition.reassign!(department)
      petition.reload
      expect(petition.department_id).to eq(department.id)
    end

    it "creates a record of the assignment and timestamps it" do
      frozen_time = Time.now
      allow(Time).to receive(:now).and_return(frozen_time)
      petition.reassign!(department)
      department_assignment = DepartmentAssignment.first

      expect(department_assignment.petition).to         eq(petition)
      expect(department_assignment.department).to       eq(department)
      expect(department_assignment.assigned_on.to_i).to eq(frozen_time.to_i)
    end

    it "blows up if it can't ressign" do
      expect {
        petition.ressign!(nil)
      }.to raise_error
    end
  end

  describe "creating sponsors from sponsor emails in after create callback" do
    it 'persists sponsors to match the emails' do
      sponsor_emails = ['test1@test.com', 'test2@test.com', 'test3@test.com', 'test4@test.com', 'test5@test.com']
      petition = FactoryGirl.create(:petition, sponsor_emails: sponsor_emails)
      expect(petition.sponsors.map(&:email)).to include(*sponsor_emails)
    end
  end

  describe "#notify_creator_about_sponsor_support", immediate_delayed_job_work_off: true do
    let(:sponsor_emails) { (1..AppConfig.sponsor_moderation_threshold).map { |n| "sponsor-#{n}@example.com" } }
    subject { FactoryGirl.create(:petition, sponsor_emails: sponsor_emails) }
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
        subject.notify_creator_about_sponsor_support(sponsor)
        email = ActionMailer::Base.deliveries.last
        expect(email.from).to eq(["no-reply@example.gov"])
        expect(email.to).to eq([subject.creator_signature.email])
        expect(email.subject).to match(/has received support from a sponsor/)
      end
    end

    context 'when the petition is on the sponsor moderation threshold' do
      let(:sponsor) { subject.sponsors.first }
      before do
        while subject.supporting_sponsors_count < AppConfig.sponsor_moderation_threshold do
          subject.sponsors.where(signature_id: nil).first.create_signature!(FactoryGirl.attributes_for(:validated_signature))
        end
        sponsor.reload
      end

      it 'sends an email to the petition creator telling them about the sponsor' do
        subject.notify_creator_about_sponsor_support(sponsor)
        email = ActionMailer::Base.deliveries.last
        expect(email.from).to eq(["no-reply@example.gov"])
        expect(email.to).to eq([subject.creator_signature.email])
        expect(email.subject).to match(/has received support from a sponsor/)
      end

    end

    context 'when the petition is above the sponsor moderation threshold' do
      let(:sponsor) { FactoryGirl.create(:sponsor, :with_signature, petition: subject) }
      before do
        while subject.supporting_sponsors_count < AppConfig.sponsor_moderation_threshold do
          subject.sponsors.where(signature_id: nil).first.create_signature!(FactoryGirl.attributes_for(:validated_signature))
        end
      end

      it 'does not send an email to the petition creator telling them about the sponsor' do
        subject.notify_creator_about_sponsor_support(sponsor)
        email = ActionMailer::Base.deliveries.last
        expect(email).to be_nil
      end
    end
  end
end

