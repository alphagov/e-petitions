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
      p.state.should == "pending"
    end

    it "email signees should default to false" do
      p = Petition.new
      p.email_signees.should be_false
    end

    it "duration should default to 12" do
      p = Petition.new
      p.duration.should == "12"
    end
  end

  context "validations" do
    it { should validate_presence_of(:title).with_message(/must be completed/) }
    it { should validate_presence_of(:description).with_message(/must be completed/) }
    it { should validate_presence_of(:duration).with_message(/must be completed/) }
    it { should validate_presence_of(:department).with_message(/must be completed/) }
    it { should validate_presence_of(:creator_signature).with_message(/must be completed/) }

    it "should validate the length of :title to within 150 characters" do
      FactoryGirl.build(:petition, :title => 'x' * 150).should be_valid
      FactoryGirl.build(:petition, :title => 'x' * 151).should_not be_valid
    end

    it "should validate the length of :description to within 1000 characters" do
      FactoryGirl.build(:petition, :description => 'x' * 1000).should be_valid
      FactoryGirl.build(:petition, :description => 'x' * 1001).should_not be_valid
    end

    it "should not allow blank or unknown state" do
      p = FactoryGirl.build(:petition, :state => '')
      p.errors_on(:state).should_not be_blank
      p.state = 'unknown'
      p.errors_on(:state).should_not be_blank
    end

    it "should allow known states" do
      p = FactoryGirl.build(:petition)
      %w(pending validated open rejected hidden).each do |state|
        p.state = state
        p.errors_on(:state).should be_blank
      end
    end

    context "when state is open" do
      let(:petition) { FactoryGirl.build(:open_petition, :open_at => nil, :closed_at => nil) }

      it "should check petition is invalid if no open_at date" do
        petition.should_not be_valid
        petition.errors_on(:open_at).should_not be_blank
      end

      it "should check petition is invalid if no closed_at date" do
        petition.should_not be_valid
        petition.errors_on(:closed_at).should_not be_blank
      end

      it "should check petition is valid if there is a open_at and closed_at date" do
        petition.open_at = Time.zone.now
        petition.closed_at = Time.zone.now
        petition.should be_valid
      end
    end

    context "when state is rejected" do
      let(:petition) { FactoryGirl.build(:petition, :state => Petition::REJECTED_STATE) }

      it "should check petition is invalid if no rejection code" do
        petition.should_not be_valid
        petition.errors_on(:rejection_code).should_not be_blank
      end

      it "should check there is a rejection code" do
        petition.rejection_code = 'libellous'
        petition.should be_valid
      end
    end

    context "response" do
      let(:petition) { FactoryGirl.build(:petition, :response => 'Hello', :email_signees => false) }

      it "should check petition is valid if there is a response when email_signees is true" do
        petition.should be_valid
      end

      it "should check petition is invalid if there is no response when email_signees is true" do
        petition.response = nil
        petition.email_signees = true
        petition.errors_on(:response).should_not be_blank
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
        Petition.last_hour_trending.map(&:id).include?(@petition_with_old_signatures.id).should be_false
      end

      it "returns the signature count for the last hour as an additional attribute" do
        Petition.last_hour_trending.first.signatures_in_last_hour.should == "11"
        Petition.last_hour_trending.last.signatures_in_last_hour.should  == "1"
      end

      it "limits the result to 12 petitions" do
        # 13 petitions signed in the last hour
        2.times do |count|
          petition = FactoryGirl.create(:open_petition, :title => "petition ##{count+1}")
          count.times { FactoryGirl.create(:validated_signature, :petition => petition) }
        end

        Petition.last_hour_trending.all.size.should == 12
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
          Petition.trending(1).to_a.size.should == 10
        end

        it "orders the petitions by the highest signature count" do
          trending_petitions = Petition.trending(1).all
          trending_petitions.first.title.should == "petition #15"
          trending_petitions.last.title.should  == "petition #6"
        end

        it "ignores petitions with signatures that are outside a rolling 24 hour period" do
          Petition.trending(1).all.map(&:title).include?(@petition_with_old_signatures.title).should be_false
        end
      end

      context "finding trending petitions for the last 7 days" do
        it "includes the petition with older signatures" do
          Petition.trending(7).all.map(&:title).include?(@petition_with_old_signatures.title).should be_true
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
        petitions.size.should == 4
        petitions.should include(@p1, @p2, @p4, @p5)
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
      end

      it "should return 2 pending petitions" do
        petitions = Petition.for_state(Petition::PENDING_STATE)
        petitions.size.should == 2
        petitions.should include(@p1, @p3)
      end

      it "should return 1 validated, open, closed and hidden petitions" do
        [[Petition::VALIDATED_STATE, @p2], [Petition::OPEN_STATE, @p4],
         [Petition::HIDDEN_STATE, @p5], [Petition::CLOSED_STATE, @p6]].each do |state_and_petition|
          petitions = Petition.for_state(state_and_petition[0])
          petitions.size.should == 1
          petitions.should == [state_and_petition[1]]
        end
      end
    end

    context "visible" do
      before :each do
        @hidden_petition_1 = FactoryGirl.create(:petition, :state => Petition::PENDING_STATE)
        @hidden_petition_2 = FactoryGirl.create(:petition, :state => Petition::VALIDATED_STATE)
        @hidden_petition_3 = FactoryGirl.create(:petition, :state => Petition::HIDDEN_STATE)
        @visible_petition_1 = FactoryGirl.create(:open_petition)
        @visible_petition_2 = FactoryGirl.create(:rejected_petition)
        @visible_petition_3 = FactoryGirl.create(:open_petition, :closed_at => 1.day.ago)
      end

      it "returns only visible petitions" do
        Petition.visible.size.should == 3
        Petition.visible.should include(@visible_petition_1, @visible_petition_2, @visible_petition_3)
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
        Petition.for_departments([@d1]).size.should == 2
        Petition.for_departments([@d1]).should include(@p1, @p2)
      end

      it "should return 0 petitions for d2" do
        Petition.for_departments([@d2]).size.should == 0
      end

      it "should return 1 petition for d3" do
        Petition.for_departments([@d3]).size.should == 1
        Petition.for_departments([@d3]).should == [@p3]
      end

      it "should return all petitions for d1, d2 and d3" do
        Petition.for_departments([@d1, @d2, @d3]).size.should == 3
        Petition.for_departments([@d1, @d2, @d3]).should include(@p1, @p2, @p3)
      end

      it "should return 0 for no departments" do
        Petition.for_departments([]).size.should == 0
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
      @petition.signature_count.should == 1
    end

    it "still returns 1 with a new signature" do
      FactoryGirl.create(:signature, :petition => @petition)
      @petition.reload
      @petition.signature_count.should == 1
    end

    it "returns 2 when signature is validated" do
      s = FactoryGirl.create(:signature, :petition => @petition)
      s.update_attribute(:state, Signature::VALIDATED_STATE)
      Petition.update_all_signature_counts
      @petition.reload
      @petition.signature_count.should == 2
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
      subject["SO23"].should == 7
      subject["B17"].should == 1
    end

    it "only returns validated signatures" do
      FactoryGirl.create(:pending_signature, :petition => @petition, :postcode => "b17 1SS")
      subject["B17"].should == 1
    end

    it "ignores special signatures" do
      FactoryGirl.create(:pending_signature, :petition => @petition, :postcode => "BFPO 1234")
      subject[""].should == 0
    end
  end

  describe "email_all_who_passed_finding_mp_threshold" do
    let(:deliverer) { double(:deliver => true) }
    let(:petition) { FactoryGirl.create(:open_petition) }

    before do
      FactoryGirl.create(:system_setting, :key => SystemSetting::GET_AN_MP_SIGNATURE_COUNT, :value => "10")
      PetitionMailer.stub(:ask_creator_to_find_an_mp => deliverer)
    end

    it "emails those who have passed the threshold" do
      PetitionMailer.should_receive(:ask_creator_to_find_an_mp).with(petition).and_return(deliverer)
      petition.update_attribute(:signature_count, 10)
      Petition.email_all_who_passed_finding_mp_threshold
    end

    it "does not send the email if you are below the threshold" do
      PetitionMailer.should_not_receive(:ask_creator_to_find_an_mp)
      petition.update_attribute(:signature_count, 2)
      Petition.email_all_who_passed_finding_mp_threshold
    end

    it "does not send if the petition is not open" do
      PetitionMailer.should_not_receive(:ask_creator_to_find_an_mp)
      petition.update_attribute(:signature_count, 10)
      petition.update_attribute(:state, Petition::CLOSED_STATE)
      Petition.email_all_who_passed_finding_mp_threshold
    end

    it "does not send the email again after sending once" do
      PetitionMailer.should_receive(:ask_creator_to_find_an_mp).once.and_return(deliverer)
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
      FactoryGirl.create(:open_petition, :closed_at => 1.year.from_now).can_be_signed?.should be_true
    end

    it "is false if the petition is OPEN and the closed_at date is in the past" do
      FactoryGirl.create(:open_petition, :closed_at => 2.minutes.ago).can_be_signed?.should be_false
    end

    it "is false otherwise" do
      petition(Petition::PENDING_STATE).can_be_signed?.should be_false
      petition(Petition::HIDDEN_STATE).can_be_signed?.should be_false
      petition(Petition::REJECTED_STATE).can_be_signed?.should be_false
      petition(Petition::VALIDATED_STATE).can_be_signed?.should be_false
    end
  end

  describe "open?" do
    it "should be open when state is open" do
      FactoryGirl.build(:petition, :state => Petition::OPEN_STATE).open?.should  be_true
    end

    it "should be not be open when state is anything else" do
      [Petition::PENDING_STATE, Petition::VALIDATED_STATE, Petition::REJECTED_STATE, Petition::HIDDEN_STATE].each do |state|
        FactoryGirl.build(:petition, :state => state).open?.should be_false
      end
    end
  end

  describe "rejected?" do
    it "should be rejected when state is rejected" do
      FactoryGirl.build(:petition, :state => Petition::REJECTED_STATE).rejected?.should be_true
    end

    it "should be not be rejected when state is anything else" do
      [Petition::PENDING_STATE, Petition::VALIDATED_STATE, Petition::OPEN_STATE, Petition::HIDDEN_STATE].each do |state|
        FactoryGirl.build(:petition, :state => state).rejected?.should be_false
      end
    end
  end

  describe "hidden?" do
    it "should be hidden when state is hidden" do
      FactoryGirl.build(:petition, :state => Petition::HIDDEN_STATE).hidden?.should be_true
    end

    it "should be not be hidden when state is anything else" do
      [Petition::PENDING_STATE, Petition::VALIDATED_STATE, Petition::OPEN_STATE, Petition::REJECTED_STATE].each do |state|
        FactoryGirl.build(:petition, :state => state).hidden?.should be_false
      end
    end
  end

  describe "rejection_reason" do
    it "should give rejection reason from json file" do
      petition = FactoryGirl.build(:rejected_petition, :rejection_code => 'duplicate')
      petition.rejection_reason.should == 'Duplicate of an existing e-petition'
    end
  end

  describe "rejection_description" do
    it "should give rejection description from json file" do
      petition = FactoryGirl.build(:rejected_petition, :rejection_code => 'duplicate')
      petition.rejection_description.should == '<p>There is already an e-petition about this issue.</p>'
    end
  end

  describe "updating signature counts" do
    let(:petition) { double }
    before do
      Petition.stub(:visible => [petition])
    end
    it "calls update signature counts for each petition" do
      petition.stub(:count_validated_signatures).and_return(123)
      petition.stub(:signature_count).and_return(122)
      petition.should_receive(:update_attribute).with(:signature_count, 123)
      Petition.update_all_signature_counts
    end
    it "doesn't change signature counts when not changed" do
      petition.stub(:count_validated_signatures).and_return(122)
      petition.stub(:signature_count).and_return(122)
      petition.should_not_receive(:update_attribute).with(:signature_count, 122)
      Petition.update_all_signature_counts
    end
  end

  describe "counting validated signatures" do
    let(:petition) { FactoryGirl.build(:petition) }

    it "should only count validated signtatures" do
      petition.signatures.should_receive(:validated).and_return(double(:valid_signatures, :count => 123))
      petition.count_validated_signatures.should == 123
    end
  end

  describe "signatures that need emailing" do
    let(:petition) { FactoryGirl.create(:petition) }
    it "returns validated signatures" do
      petition.need_emailing.should == [petition.creator_signature]
    end

    it "only returns those yet to be emailed" do
      petition.creator_signature.update_attribute(:last_emailed_at, Time.now)
      petition.need_emailing.should == []
    end
  end

  describe "permissions" do
    let(:petition) { FactoryGirl.build(:petition) }
    let(:user) { double(:is_a_threshold? => false, :is_a_sysadmin? => false) }

    it "is editable by moderators in the same department" do
      user.stub(:departments => [petition.department])
      petition.editable_by?(user).should be_true
    end

    it "is not editable by a moderator in another department" do
      user.stub(:departments => [])
      petition.editable_by?(user).should be_false
    end
    it "is editable by a threshold user" do
      user.stub(:is_a_threshold? => true)
      petition.editable_by?(user).should be_true
    end

    it "is editable by a sys admin" do
      user.stub(:is_a_sysadmin? => true)
      petition.editable_by?(user).should be_true
    end

    it "doesn't allow editing of response generally" do
      petition.response_editable_by?(user).should be_false
    end

    it "allows editing of the response by threshold users" do
      user.stub(:is_a_threshold? => true)
      petition.response_editable_by?(user).should be_true
    end

    it "allows editing of the response by sysadmins" do
      user.stub(:is_a_sysadmin? => true)
      petition.response_editable_by?(user).should be_true
    end
  end

  describe ".counts_by_state" do
    it "returns a hash containing counts of petition states" do
      1.times { FactoryGirl.create(:pending_petition) }
      2.times { FactoryGirl.create(:validated_petition) }
      3.times { FactoryGirl.create(:open_petition) }
      4.times { FactoryGirl.create(:closed_petition) }
      5.times { FactoryGirl.create(:rejected_petition) }
      6.times { FactoryGirl.create(:hidden_petition) }

      # Petition.counts_by_state.class.should == Hash

      Petition.counts_by_state[:pending].should   == 1
      Petition.counts_by_state[:validated].should == 2
      Petition.counts_by_state[:open].should      == 3
      Petition.counts_by_state[:closed].should    == 4
      Petition.counts_by_state[:rejected].should  == 5
      Petition.counts_by_state[:hidden].should    == 6
    end
  end

  describe "#reassign!" do
    let(:petition){ FactoryGirl.create(:petition) }
    let(:department){ FactoryGirl.create(:department) }

    it "takes a department id and saves the petition" do
      petition.reassign!(department)
      petition.reload
      petition.department_id.should == department.id
    end

    it "creates a record of the assignment and timestamps it" do
      frozen_time = Time.now
      Time.stub!(:now).and_return(frozen_time)
      petition.reassign!(department)
      department_assignment = DepartmentAssignment.first

      department_assignment.petition.should         == petition
      department_assignment.department.should       == department
      department_assignment.assigned_on.to_i.should == frozen_time.to_i
    end

    it "blows up if it can't ressign" do
      expect {
        petition.ressign!(nil)
      }.to raise_error
    end
  end
end
