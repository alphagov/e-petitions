require 'rails_helper'

RSpec.describe Parliament, type: :model do
  describe "schema" do
    it { is_expected.to have_db_column(:government).of_type(:string).with_options(limit: 100, null: true) }
    it { is_expected.to have_db_column(:opening_at).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:petition_duration).of_type(:integer).with_options(default: 6) }
    it { is_expected.to have_db_column(:dissolution_at).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:dissolution_heading).of_type(:string).with_options(limit: 100, null: true) }
    it { is_expected.to have_db_column(:dissolution_message).of_type(:text).with_options(null: true) }
    it { is_expected.to have_db_column(:dissolution_faq_url).of_type(:string).with_options(limit: 500, null: true) }
    it { is_expected.to have_db_column(:dissolved_heading).of_type(:string).with_options(limit: 100, null: true) }
    it { is_expected.to have_db_column(:dissolved_message).of_type(:text).with_options(null: true) }
    it { is_expected.to have_db_column(:notification_cutoff_at).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:registration_closed_at).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:archived_at).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "associations" do
    it { is_expected.to have_many(:petitions).inverse_of(:parliament).class_name("Archived::Petition") }
  end

  describe "callbacks" do
    context "when the parliament is updated" do
      let(:parliament) { FactoryBot.create(:parliament, :dissolving, dissolution_at: 3.weeks.from_now) }
      let(:site) { Site.instance }

      before do
        travel_to 2.days.ago do
          site.touch
        end
      end

      it "updates the site timestamp" do
        expect {
          parliament.update!(dissolution_at: 2.weeks.from_now)
        }.to change {
          site.reload.updated_at
        }
      end
    end
  end

  describe "validations" do
    context "when dissolution_at is nil" do
      subject { Parliament.new }

      it { is_expected.to validate_presence_of(:government) }
      it { is_expected.to validate_presence_of(:opening_at) }
      it { is_expected.not_to validate_presence_of(:petition_duration) }
      it { is_expected.not_to validate_presence_of(:dissolution_heading) }
      it { is_expected.not_to validate_presence_of(:dissolution_message) }
      it { is_expected.not_to validate_presence_of(:dissolved_heading) }
      it { is_expected.not_to validate_presence_of(:dissolved_message) }
      it { is_expected.not_to validate_presence_of(:dissolution_faq_url) }
      it { is_expected.to validate_length_of(:government).is_at_most(100) }
      it { is_expected.to validate_length_of(:dissolution_heading).is_at_most(100) }
      it { is_expected.to validate_length_of(:dissolution_message).is_at_most(600) }
      it { is_expected.to validate_length_of(:dissolved_heading).is_at_most(100) }
      it { is_expected.to validate_length_of(:dissolved_message).is_at_most(600) }
      it { is_expected.to validate_length_of(:dissolution_faq_url).is_at_most(500) }
      it { is_expected.to validate_numericality_of(:petition_duration).only_integer }
      it { is_expected.to validate_numericality_of(:petition_duration).is_greater_than_or_equal_to(1) }
      it { is_expected.to validate_numericality_of(:petition_duration).is_less_than_or_equal_to(12) }
    end

    context "when dissolution_at is not nil" do
      subject { Parliament.new(dissolution_at: 2.weeks.from_now) }

      it { is_expected.to validate_presence_of(:government) }
      it { is_expected.to validate_presence_of(:opening_at) }
      it { is_expected.not_to validate_presence_of(:petition_duration) }
      it { is_expected.to validate_presence_of(:dissolution_heading) }
      it { is_expected.to validate_presence_of(:dissolution_message) }
      it { is_expected.not_to validate_presence_of(:dissolved_heading) }
      it { is_expected.not_to validate_presence_of(:dissolved_message) }
      it { is_expected.not_to validate_presence_of(:dissolution_faq_url) }
      it { is_expected.to validate_length_of(:government).is_at_most(100) }
      it { is_expected.to validate_length_of(:dissolution_heading).is_at_most(100) }
      it { is_expected.to validate_length_of(:dissolution_message).is_at_most(600) }
      it { is_expected.to validate_length_of(:dissolved_heading).is_at_most(100) }
      it { is_expected.to validate_length_of(:dissolved_message).is_at_most(600) }
      it { is_expected.to validate_length_of(:dissolution_faq_url).is_at_most(500) }
      it { is_expected.to validate_numericality_of(:petition_duration).only_integer }
      it { is_expected.to validate_numericality_of(:petition_duration).is_greater_than_or_equal_to(1) }
      it { is_expected.to validate_numericality_of(:petition_duration).is_less_than_or_equal_to(12) }
    end

    context "when dissolution_at is in the past" do
      subject { Parliament.new(dissolution_at: 1.day.ago) }

      it { is_expected.to validate_presence_of(:government) }
      it { is_expected.to validate_presence_of(:opening_at) }
      it { is_expected.not_to validate_presence_of(:petition_duration) }
      it { is_expected.to validate_presence_of(:dissolution_heading) }
      it { is_expected.to validate_presence_of(:dissolution_message) }
      it { is_expected.to validate_presence_of(:dissolved_heading) }
      it { is_expected.to validate_presence_of(:dissolved_message) }
      it { is_expected.not_to validate_presence_of(:dissolution_faq_url) }
      it { is_expected.to validate_length_of(:government).is_at_most(100) }
      it { is_expected.to validate_length_of(:dissolution_heading).is_at_most(100) }
      it { is_expected.to validate_length_of(:dissolution_message).is_at_most(600) }
      it { is_expected.to validate_length_of(:dissolved_heading).is_at_most(100) }
      it { is_expected.to validate_length_of(:dissolved_message).is_at_most(600) }
      it { is_expected.to validate_length_of(:dissolution_faq_url).is_at_most(500) }
      it { is_expected.to validate_numericality_of(:petition_duration).only_integer }
      it { is_expected.to validate_numericality_of(:petition_duration).is_greater_than_or_equal_to(1) }
      it { is_expected.to validate_numericality_of(:petition_duration).is_less_than_or_equal_to(12) }
    end
  end

  describe "scopes" do
    describe "archived" do
      let!(:coalition) { FactoryBot.create(:parliament, :coalition) }
      let!(:conservatives) { FactoryBot.create(:parliament, :conservatives) }
      let!(:new_government) { FactoryBot.create(:parliament, :new_government) }

      context "when the archive_at timestamp is in the future" do
        let(:now) { "2017-05-31T00:00:00".in_time_zone }

        it "returns archived parliaments in descending order" do
          expect(described_class.archived(now)).to eq([coalition])
        end
      end

      context "when the archive_at timestamp is in the past" do
        let(:now) { "2017-06-18T00:00:00".in_time_zone }

        it "returns archived parliaments in descending order" do
          expect(described_class.archived(now)).to eq([conservatives, coalition])
        end
      end
    end

    describe "current" do
      let!(:coalition) { FactoryBot.create(:parliament, :coalition) }
      let!(:conservatives) { FactoryBot.create(:parliament, :conservatives) }
      let!(:new_government) { FactoryBot.create(:parliament, :new_government) }

      let(:now) { "2017-05-31T00:00:00".in_time_zone }

      around do |example|
        travel_to(now) { example.run }
      end

      it "excludes archived parliaments" do
        expect(described_class.current).not_to include(coalition)
      end

      it "excludes parliaments scheduled to be archived" do
        expect(described_class.current).not_to include(conservatives)
      end

      it "includes the new parliament" do
        expect(described_class.current).to include(new_government)
      end
    end
  end

  describe "singleton methods" do
    let(:parliament) { FactoryBot.create(:parliament) }
    let(:now) { Time.current }

    before do
      allow(Parliament).to receive(:current_or_create).and_return(parliament)
    end

    around do |example|
      Parliament.reload
      example.run
      Parliament.reload
    end

    it "delegates government to the instance" do
      expect(parliament).to receive(:government).and_return("Conservative – Liberal Democrat coalition")
      expect(Parliament.government).to eq("Conservative – Liberal Democrat coalition")
    end

    it "delegates opening_at to the instance" do
      expect(parliament).to receive(:opening_at).and_return(now)
      expect(Parliament.opening_at).to eq(now)
    end

    it "delegates opened? to the instance" do
      expect(parliament).to receive(:opened?).and_return(true)
      expect(Parliament.opened?).to eq(true)
    end

    it "delegates closed? to the instance" do
      expect(parliament).to receive(:closed?).and_return(false)
      expect(Parliament.closed?).to eq(false)
    end

    it "delegates dissolution_at to the instance" do
      expect(parliament).to receive(:dissolution_at).and_return(now)
      expect(Parliament.dissolution_at).to eq(now)
    end

    it "delegates dissolution_at? to the instance" do
      expect(parliament).to receive(:dissolution_at?).and_return(true)
      expect(Parliament.dissolution_at?).to eq(true)
    end

    it "delegates notification_cutoff_at to the instance" do
      expect(parliament).to receive(:notification_cutoff_at).and_return(now)
      expect(Parliament.notification_cutoff_at).to eq(now)
    end

    it "delegates dissolution_heading to the instance" do
      expect(parliament).to receive(:dissolution_heading).and_return("Parliament is dissolving")
      expect(Parliament.dissolution_heading).to eq("Parliament is dissolving")
    end

    it "delegates dissolution_message to the instance" do
      expect(parliament).to receive(:dissolution_message).and_return("Parliament is dissolving")
      expect(Parliament.dissolution_message).to eq("Parliament is dissolving")
    end

    it "delegates dissolved_heading to the instance" do
      expect(parliament).to receive(:dissolved_heading).and_return("Parliament is dissolved")
      expect(Parliament.dissolved_heading).to eq("Parliament is dissolved")
    end

    it "delegates dissolved_message to the instance" do
      expect(parliament).to receive(:dissolved_message).and_return("Parliament is dissolved")
      expect(Parliament.dissolved_message).to eq("Parliament is dissolved")
    end

    it "delegates dissolution_faq_url to the instance" do
      expect(parliament).to receive(:dissolution_faq_url).and_return("https://parliament.example.com/parliament-is-closing")
      expect(Parliament.dissolution_faq_url).to eq("https://parliament.example.com/parliament-is-closing")
    end

    it "delegates dissolution_faq_url? to the instance" do
      expect(parliament).to receive(:dissolution_faq_url?).and_return(true)
      expect(Parliament.dissolution_faq_url?).to eq(true)
    end

    it "delegates dissolution_announced? to the instance" do
      expect(parliament).to receive(:dissolution_announced?).and_return(true)
      expect(Parliament.dissolution_announced?).to eq(true)
    end

    it "delegates dissolving? to the instance" do
      expect(parliament).to receive(:dissolving?).and_return(true)
      expect(Parliament.dissolving?).to eq(true)
    end

    it "delegates dissolved? to the instance" do
      expect(parliament).to receive(:dissolved?).and_return(true)
      expect(Parliament.dissolved?).to eq(true)
    end

    it "delegates registration_closed? to the instance" do
      expect(parliament).to receive(:registration_closed?).and_return(true)
      expect(Parliament.registration_closed?).to eq(true)
    end
  end

  describe ".reload" do
    let(:parliament) { FactoryBot.create(:parliament) }

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__parliament__] = parliament
      end

      it "clears the cached instance in Thread.current" do
        expect{ Parliament.reload }.to change {
          Thread.current[:__parliament__]
        }.from(parliament).to(nil)
      end
    end
  end

  describe ".instance" do
    let(:parliament) { FactoryBot.create(:parliament) }

    context "when it isn't cached in Thread.current" do
      before do
        Thread.current[:__parliament__] = nil
      end

      after do
        Parliament.reload
      end

      it "finds the last record" do
        expect(Parliament).to receive(:current_or_create).and_return(parliament)
        expect(Parliament.instance).to equal(parliament)
      end

      it "caches it in Thread.current" do
        expect(Parliament).to receive(:current_or_create).and_return(parliament)
        expect(Parliament.instance).to equal(Thread.current[:__parliament__])
      end
    end

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__parliament__] = parliament
      end

      after do
        Parliament.reload
      end

      it "returns the cached instance" do
        expect(Parliament).not_to receive(:current_or_create)
        expect(Parliament.instance).to equal(parliament)
      end
    end
  end

  describe ".before_remove_const" do
    let(:parliament) { FactoryBot.create(:parliament) }

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__parliament__] = parliament
      end

      it "clears the cached instance in Thread.current" do
        expect{ Parliament.before_remove_const }.to change {
          Thread.current[:__parliament__]
        }.from(parliament).to(nil)
      end
    end
  end

  describe "#period" do
    context "when opening_at and dissolution_at are nil" do
      subject :parliament do
        FactoryBot.build(:parliament, opening_at: nil, dissolution_at: nil)
      end

      it "returns nil" do
        expect(parliament.period).to be_nil
      end
    end

    context "when opening_at is nil" do
      subject :parliament do
        FactoryBot.build(:parliament, opening_at: nil, dissolution_at: 1.year.from_now)
      end

      it "returns nil" do
        expect(parliament.period).to be_nil
      end
    end

    context "when dissolution_at is nil" do
      subject :parliament do
        FactoryBot.build(:parliament, opening_at: 1.year.ago, dissolution_at: nil)
      end

      it "returns nil" do
        expect(parliament.period).to be_nil
      end
    end

    context "when opening_at and dissolution_at are not nil" do
      subject :parliament do
        FactoryBot.build(:parliament, opening_at: "2010-05-18 00:00:00", dissolution_at: "2015-03-30 00:01:00")
      end

      it "returns the years of operation" do
        expect(parliament.period).to eq("2010–2015")
      end
    end
  end

  describe "#period?" do
    context "when opening_at and dissolution_at are nil" do
      subject :parliament do
        FactoryBot.build(:parliament, opening_at: nil, dissolution_at: nil)
      end

      it "returns false" do
        expect(parliament.period?).to eq(false)
      end
    end

    context "when opening_at is nil" do
      subject :parliament do
        FactoryBot.build(:parliament, opening_at: nil, dissolution_at: 1.year.from_now)
      end

      it "returns false" do
        expect(parliament.period?).to eq(false)
      end
    end

    context "when dissolution_at is nil" do
      subject :parliament do
        FactoryBot.build(:parliament, opening_at: 1.year.ago, dissolution_at: nil)
      end

      it "returns false" do
        expect(parliament.period?).to eq(false)
      end
    end

    context "when opening_at and dissolution_at are not nil" do
      subject :parliament do
        FactoryBot.build(:parliament, opening_at: "2010-05-18 00:00:00", dissolution_at: "2015-03-30 00:01:00")
      end

      it "returns true" do
        expect(parliament.period?).to eq(true)
      end
    end
  end

  describe "#opened?" do
    context "when opening_at is nil" do
      subject :parliament do
        FactoryBot.build(:parliament, opening_at: nil)
      end

      it "returns false" do
        expect(parliament.opened?).to eq(false)
      end
    end

    context "when opening_at is in the future" do
      subject :parliament do
        FactoryBot.create(:parliament, opening_at: 4.weeks.from_now)
      end

      it "returns false" do
        expect(parliament.opened?).to eq(false)
      end
    end

    context "when opening_at is in the past" do
      subject :parliament do
        FactoryBot.create(:parliament, opening_at: 2.years.ago)
      end

      it "returns true" do
        expect(parliament.opened?).to eq(true)
      end
    end
  end

  describe "#closed?" do
    context "when Parliament is open" do
      context "and has not been dissolved" do
        subject :parliament do
          FactoryBot.build(:parliament, opening_at: 2.years.ago, dissolution_at: nil)
        end

        it "return false" do
          expect(parliament.closed?).to eq(false)
        end
      end

      context "and is dissolving" do
        subject :parliament do
          FactoryBot.build(:parliament, opening_at: 2.years.ago, dissolution_at: 1.day.from_now)
        end

        it "return false" do
          expect(parliament.closed?).to eq(false)
        end
      end

      context "and has been dissolved" do
        subject :parliament do
          FactoryBot.build(:parliament, opening_at: 2.years.ago, dissolution_at: 1.day.ago)
        end

        it "return true" do
          expect(parliament.closed?).to eq(true)
        end
      end
    end

    context "whem Parliament has not been opened" do
      subject :parliament do
        FactoryBot.build(:parliament, opening_at: nil, dissolution_at: nil)
      end

      it "return true" do
        expect(parliament.closed?).to eq(true)
      end
    end
  end

  describe "#dissolution_announced?" do
    context "when dissolution_at is nil" do
      subject :parliament do
        FactoryBot.create(:parliament)
      end

      it "returns false" do
        expect(parliament.dissolution_announced?).to eq(false)
      end
    end

    context "when dissolution_at is not nil" do
      subject :parliament do
        FactoryBot.create(:parliament, :dissolving)
      end

      context "and show_dissolution_notification is false" do
        before do
          expect(parliament).to receive(:show_dissolution_notification?).and_return(false)
        end

        it "returns false" do
          expect(parliament.dissolution_announced?).to eq(false)
        end
      end

      context "and show_dissolution_notification is true" do
        before do
          expect(parliament).to receive(:show_dissolution_notification?).and_return(true)
        end

        it "returns true" do
          expect(parliament.dissolution_announced?).to eq(true)
        end
      end
    end
  end

  describe "#dissolving?" do
    context "when dissolution_at is nil" do
      subject :parliament do
        FactoryBot.create(:parliament)
      end

      it "returns false" do
        expect(parliament.dissolving?).to eq(false)
      end
    end

    context "when dissolution_at is in the future" do
      subject :parliament do
        FactoryBot.create(:parliament, :dissolving)
      end

      it "returns true" do
        expect(parliament.dissolving?).to eq(true)
      end
    end

    context "when dissolution_at is in the past" do
      subject :parliament do
        FactoryBot.create(:parliament, :dissolved)
      end

      it "returns false" do
        expect(parliament.dissolving?).to eq(false)
      end
    end
  end

  describe "#dissolved?" do
    context "when dissolution_at is nil" do
      subject :parliament do
        FactoryBot.create(:parliament)
      end

      it "returns false" do
        expect(parliament.dissolved?).to eq(false)
      end
    end

    context "when dissolution_at is in the future" do
      subject :parliament do
        FactoryBot.create(:parliament, :dissolving)
      end

      it "returns false" do
        expect(parliament.dissolved?).to eq(false)
      end
    end

    context "when dissolution_at is in the past" do
      subject :parliament do
        FactoryBot.create(:parliament, :dissolved)
      end

      it "returns true" do
        expect(parliament.dissolved?).to eq(true)
      end
    end
  end

  describe "#registration_closed?" do
    context "when registration_closed_at is nil" do
      subject :parliament do
        FactoryBot.create(:parliament)
      end

      it "returns false" do
        expect(parliament.registration_closed?).to eq(false)
      end
    end

    context "when registration_closed_at is in the future" do
      subject :parliament do
        FactoryBot.create(:parliament, :dissolving, registration_closed_at: 2.weeks.from_now)
      end

      it "returns false" do
        expect(parliament.registration_closed?).to eq(false)
      end
    end

    context "when registration_closed_at is in the past" do
      subject :parliament do
        FactoryBot.create(:parliament, :dissolved, registration_closed_at: 2.weeks.ago)
      end

      it "returns true" do
        expect(parliament.registration_closed?).to eq(true)
      end
    end
  end

  describe "#archived?" do
    context "when archived_at is nil" do
      subject :parliament do
        FactoryBot.build(:parliament, archived_at: nil)
      end

      it "returns false" do
        expect(parliament.archived?).to eq(false)
      end
    end

    context "when archived_at is in the future" do
      subject :parliament do
        FactoryBot.build(:parliament, archived_at: 2.weeks.from_now)
      end

      it "returns false" do
        expect(parliament.archived?).to eq(false)
      end
    end

    context "when archived_at is in the past" do
      subject :parliament do
        FactoryBot.build(:parliament, archived_at: 2.weeks.ago)
      end

      it "returns true" do
        expect(parliament.archived?).to eq(true)
      end
    end
  end

  describe "#archiving?" do
    context "when archiving_started_at is nil" do
      subject :parliament do
        FactoryBot.build(:parliament, archiving_started_at: nil)
      end

      it "returns false" do
        expect(parliament.archiving?).to eq(false)
      end
    end

    context "when archiving_started_at is not nil" do
      subject :parliament do
        FactoryBot.build(:parliament, archiving_started_at: 1.day.ago)
      end

      context "and all petitions are unarchived" do
        before do
          FactoryBot.create(:closed_petition, archived_at: nil)
          FactoryBot.create(:closed_petition, archived_at: nil)
        end

        it "returns true" do
          expect(parliament.archiving?).to eq(true)
        end
      end

      context "and there is a mix of archived and unarchived petitions" do
        before do
          FactoryBot.create(:closed_petition, archived_at: 12.hours.ago)
          FactoryBot.create(:closed_petition, archived_at: nil)
        end

        it "returns true" do
          expect(parliament.archiving?).to eq(true)
        end
      end

      context "and all the petitions are archived" do
        before do
          FactoryBot.create(:closed_petition, archived_at: 12.hours.ago)
          FactoryBot.create(:closed_petition, archived_at: 6.hours.ago)
        end

        it "returns false" do
          expect(parliament.archiving?).to eq(false)
        end
      end
    end
  end

  describe "#archiving_finished?" do
    context "when archiving_started_at is nil" do
      subject :parliament do
        FactoryBot.build(:parliament, archiving_started_at: nil)
      end

      it "returns false" do
        expect(parliament.archiving_finished?).to eq(false)
      end
    end

    context "when archiving_started_at is not nil" do
      subject :parliament do
        FactoryBot.build(:parliament, archiving_started_at: 1.day.ago)
      end

      context "and all petitions are unarchived" do
        before do
          FactoryBot.create(:closed_petition, archived_at: nil)
          FactoryBot.create(:closed_petition, archived_at: nil)
        end

        it "returns false" do
          expect(parliament.archiving_finished?).to eq(false)
        end
      end

      context "and there is a mix of archived and unarchived petitions" do
        before do
          FactoryBot.create(:closed_petition, archived_at: 12.hours.ago)
          FactoryBot.create(:closed_petition, archived_at: nil)
        end

        it "returns false" do
          expect(parliament.archiving_finished?).to eq(false)
        end
      end

      context "and all the petitions are archived" do
        before do
          FactoryBot.create(:closed_petition, archived_at: 12.hours.ago)
          FactoryBot.create(:closed_petition, archived_at: 6.hours.ago)
        end

        it "returns true" do
          expect(parliament.archiving_finished?).to eq(true)
        end
      end
    end
  end

  describe "#start_archiving!" do
    let :archive_petitions_job do
      {
        job: ArchivePetitionsJob,
        args: [],
        queue: "high_priority"
      }
    end

    context "when petitions have not been archived" do
      subject :parliament do
        FactoryBot.create(:parliament, archiving_started_at: nil)
      end

      before do
        FactoryBot.create(:closed_petition, archived_at: nil)
        FactoryBot.create(:closed_petition, archived_at: nil)
      end

      it "schedules an ArchivedPetitionsJob" do
        expect {
          subject.start_archiving!
        }.to change {
          enqueued_jobs
        }.from([]).to([archive_petitions_job])
      end

      it "updates the archiving_started_at timestamp" do
        expect {
          subject.start_archiving!
        }.to change {
          subject.reload.archiving_started_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end
    end

    context "when archiving has already started" do
      subject :parliament do
        FactoryBot.create(:parliament, archiving_started_at: 2.hours.ago)
      end

      before do
        FactoryBot.create(:closed_petition, archived_at: 1.hour.ago)
        FactoryBot.create(:closed_petition, archived_at: nil)
      end

      it "doesn't schedule an ArchivedPetitionsJob" do
        expect {
          subject.start_archiving!
        }.not_to change {
          enqueued_jobs
        }
      end

      it "doesn't update the archiving_started_at timestamp" do
        expect {
          subject.start_archiving!
        }.not_to change {
          subject.reload.archiving_started_at
        }
      end
    end

    context "when archiving has finished" do
      subject :parliament do
        FactoryBot.create(:parliament, archiving_started_at: 2.hours.ago)
      end

      before do
        FactoryBot.create(:closed_petition, archived_at: 1.hour.ago)
        FactoryBot.create(:closed_petition, archived_at: 1.hour.ago)
      end

      it "doesn't schedule an ArchivedPetitionsJob" do
        expect {
          subject.start_archiving!
        }.not_to change {
          enqueued_jobs
        }
      end

      it "doesn't update the archiving_started_at timestamp" do
        expect {
          subject.start_archiving!
        }.not_to change {
          subject.reload.archiving_started_at
        }
      end
    end
  end

  describe "#archive!" do
    let :delete_petitions_job do
      {
        job: DeletePetitionsJob,
        args: [],
        queue: "high_priority"
      }
    end

    context "when archiving has not started" do
      subject :parliament do
        FactoryBot.create(:parliament, archiving_started_at: nil)
      end

      before do
        FactoryBot.create(:closed_petition, archived_at: nil)
        FactoryBot.create(:closed_petition, archived_at: nil)
      end

      it "doesn't schedule an DeletePetitionsJob" do
        expect {
          subject.archive!
        }.not_to change {
          enqueued_jobs
        }
      end

      it "doesn't update the archived_at timestamp" do
        expect {
          subject.archive!
        }.not_to change {
          subject.reload.archived_at
        }
      end
    end

    context "when archiving has started" do
      subject :parliament do
        FactoryBot.create(:parliament, archiving_started_at: 2.hours.ago)
      end

      before do
        FactoryBot.create(:closed_petition, archived_at: 1.hour.ago)
        FactoryBot.create(:closed_petition, archived_at: nil)
      end

      it "doesn't schedule an DeletePetitionsJob" do
        expect {
          subject.archive!
        }.not_to change {
          enqueued_jobs
        }
      end

      it "doesn't update the archived_at timestamp" do
        expect {
          subject.archive!
        }.not_to change {
          subject.reload.archived_at
        }
      end
    end

    context "when archiving has finished" do
      subject :parliament do
        FactoryBot.create(:parliament, archiving_started_at: 2.hours.ago)
      end

      before do
        FactoryBot.create(:closed_petition, archived_at: 1.hour.ago)
        FactoryBot.create(:closed_petition, archived_at: 1.hour.ago)
      end

      it "schedules an DeletePetitionsJob" do
        expect {
          subject.archive!
        }.to change {
          enqueued_jobs
        }.from([]).to([delete_petitions_job])
      end

      it "updates the archived_at timestamp" do
        expect {
          subject.archive!
        }.to change {
          subject.reload.archived_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end
    end
  end

  describe "#send_emails!" do
    let :send_emails_job do
      {
        job: NotifyPetitionsThatParliamentIsDissolvingJob,
        args: [],
        queue: "high_priority"
      }
    end

    context "when parliament has not announced dissolution" do
      subject :parliament do
        FactoryBot.create(:parliament)
      end

      it "does not schedule a job" do
        expect {
          subject.send_emails!
        }.not_to change {
          enqueued_jobs
        }
      end
    end

    context "when parliament has announced dissolution" do
      context "and the dissolution date has not passed" do
        subject :parliament do
          FactoryBot.create(:parliament, :dissolving)
        end

        it "schedules a job" do
          expect {
            subject.send_emails!
          }.to change {
            enqueued_jobs
          }.from([]).to([send_emails_job])
        end
      end

      context "and the dissolution date has passsed" do
        subject :parliament do
          FactoryBot.create(:parliament, :dissolved)
        end

        it "does not schedule a job" do
          expect {
            subject.send_emails!
          }.not_to change {
            enqueued_jobs
          }
        end
      end
    end
  end

  describe "#schedule_closure!" do
    let :close_petitions_job do
      {
        job: ClosePetitionsEarlyJob,
        args: [dissolution_at.iso8601],
        queue: "high_priority",
        at: dissolution_at.to_f
      }
    end

    let :stop_petitions_job do
      {
        job: StopPetitionsEarlyJob,
        args: [dissolution_at.iso8601],
        queue: "high_priority",
        at: dissolution_at.to_f
      }
    end

    context "when parliament has not announced dissolution" do
      subject :parliament do
        FactoryBot.create(:parliament)
      end

      it "does not schedule a job" do
        expect {
          subject.schedule_closure!
        }.not_to change {
          enqueued_jobs
        }
      end
    end

    context "when parliament has announced dissolution" do
      context "and the dissolution date has not passed" do
        let(:dissolution_at) { 2.weeks.from_now }

        subject :parliament do
          FactoryBot.create(:parliament, :dissolving, dissolution_at: dissolution_at, show_dissolution_notification: true)
        end

        it "schedules a job" do
          expect {
            subject.schedule_closure!
          }.to change {
            enqueued_jobs
          }.from([]).to([close_petitions_job, stop_petitions_job])
        end
      end

      context "and the dissolution date has passsed" do
        let(:dissolution_at) { 2.weeks.ago }

        subject :parliament do
          FactoryBot.create(:parliament, :dissolved, dissolution_at: dissolution_at)
        end

        it "does not schedule a job" do
          expect {
            subject.schedule_closure!
          }.not_to change {
            enqueued_jobs
          }
        end
      end
    end
  end

  describe "#can_archive_petitions?" do
    context "when parliament has not announced dissolution" do
      subject :parliament do
        FactoryBot.create(:parliament)
      end

      it "returns false" do
        expect(parliament.can_archive_petitions?).to eq(false)
      end
    end

    context "when parliament has announced dissolution" do
      context "and the dissolution date has not passed" do
        subject :parliament do
          FactoryBot.create(:parliament, :dissolving)
        end

        it "returns false" do
          expect(parliament.can_archive_petitions?).to eq(false)
        end
      end

      context "and the dissolution date has passed" do
        context "and the petitions have not been archived" do
          subject :parliament do
            FactoryBot.create(:parliament, :dissolved, archiving_started_at: nil)
          end

          before do
            FactoryBot.create(:closed_petition, archived_at: nil)
          end

          it "returns true" do
            expect(parliament.can_archive_petitions?).to eq(true)
          end
        end

        context "and the petitions are being archived" do
          subject :parliament do
            FactoryBot.create(:parliament, :dissolved, archiving_started_at: 2.hours.ago)
          end

          before do
            FactoryBot.create(:closed_petition, archived_at: nil)
          end

          it "returns false" do
            expect(parliament.can_archive_petitions?).to eq(false)
          end
        end

        context "and the petitions have been archived" do
          subject :parliament do
            FactoryBot.create(:parliament, :dissolved, archiving_started_at: 2.hours.ago)
          end

          before do
            FactoryBot.create(:closed_petition, archived_at: 1.hour.ago)
          end

          it "returns false" do
            expect(parliament.can_archive_petitions?).to eq(false)
          end
        end
      end
    end
  end

  describe "#can_archive?" do
    context "when parliament has not announced dissolution" do
      subject :parliament do
        FactoryBot.create(:parliament)
      end

      it "returns false" do
        expect(parliament.can_archive?).to eq(false)
      end
    end

    context "when parliament has announced dissolution" do
      context "and the dissolution date has not passed" do
        subject :parliament do
          FactoryBot.create(:parliament, :dissolving)
        end

        it "returns false" do
          expect(parliament.can_archive?).to eq(false)
        end
      end

      context "and the dissolution date has passed" do
        context "and the petitions have not been archived" do
          subject :parliament do
            FactoryBot.create(:parliament, :dissolved, archiving_started_at: nil)
          end

          before do
            FactoryBot.create(:closed_petition, archived_at: nil)
          end

          it "returns false" do
            expect(parliament.can_archive?).to eq(false)
          end
        end

        context "and the petitions are being archived" do
          subject :parliament do
            FactoryBot.create(:parliament, :dissolved, archiving_started_at: 2.hours.ago)
          end

          before do
            FactoryBot.create(:closed_petition, archived_at: nil)
          end

          it "returns false" do
            expect(parliament.can_archive?).to eq(false)
          end
        end

        context "and the petitions have been archived" do
          subject :parliament do
            FactoryBot.create(:parliament, :dissolved, archiving_started_at: 2.hours.ago)
          end

          before do
            FactoryBot.create(:closed_petition, archived_at: 1.hour.ago)
          end

          it "returns true" do
            expect(parliament.can_archive?).to eq(true)
          end
        end
      end
    end
  end

  describe "#formatted_threshold_for_response" do
    subject :parliament do
      FactoryBot.build(:parliament, threshold_for_response: 10000)
    end

    it "returns a formatted number" do
      expect(parliament.formatted_threshold_for_response).to eq("10,000")
    end
  end

  describe "#formatted_threshold_for_debate" do
    subject :parliament do
      FactoryBot.build(:parliament, threshold_for_debate: 100000)
    end

    it "returns a formatted number" do
      expect(parliament.formatted_threshold_for_debate).to eq("100,000")
    end
  end
end
