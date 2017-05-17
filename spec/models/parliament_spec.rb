require 'rails_helper'

RSpec.describe Parliament, type: :model do
  describe "schema" do
    it { is_expected.to have_db_column(:government).of_type(:string).with_options(limit: 100, null: true) }
    it { is_expected.to have_db_column(:opening_at).of_type(:datetime).with_options(null: true) }
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
    it { is_expected.to have_many(:petitions).inverse_of(:parliament).class_name("ArchivedPetition") }
  end

  describe "callbacks" do
    describe "when the parliament is updated" do
      let(:parliament) { FactoryGirl.create(:parliament, :dissolving, dissolution_at: 3.weeks.from_now) }
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
    end

    context "when dissolution_at is not nil" do
      subject { Parliament.new(dissolution_at: 2.weeks.from_now) }

      it { is_expected.to validate_presence_of(:government) }
      it { is_expected.to validate_presence_of(:opening_at) }
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
    end

    context "when dissolution_at is in the past" do
      subject { Parliament.new(dissolution_at: 1.day.ago) }

      it { is_expected.to validate_presence_of(:government) }
      it { is_expected.to validate_presence_of(:opening_at) }
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
    end
  end

  describe "scopes" do
    describe "archived" do
      let!(:coalition) { FactoryGirl.create(:parliament, :coalition) }
      let!(:conservatives) { FactoryGirl.create(:parliament, :conservatives) }
      let!(:new_government) { FactoryGirl.create(:parliament, :new_government) }

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
      let!(:coalition) { FactoryGirl.create(:parliament, :coalition) }
      let!(:conservatives) { FactoryGirl.create(:parliament, :conservatives) }
      let!(:new_government) { FactoryGirl.create(:parliament, :new_government) }

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
    let(:parliament) { FactoryGirl.create(:parliament) }
    let(:now) { Time.current }

    before do
      allow(Parliament).to receive(:last_or_create).and_return(parliament)
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

    it "delegates dissolution_at to the instance" do
      expect(parliament).to receive(:dissolution_at).and_return(now)
      expect(Parliament.dissolution_at).to eq(now)
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
    let(:parliament) { FactoryGirl.create(:parliament) }

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
    let(:parliament) { FactoryGirl.create(:parliament) }

    context "when it isn't cached in Thread.current" do
      before do
        Thread.current[:__parliament__] = nil
      end

      after do
        Parliament.reload
      end

      it "finds the last record" do
        expect(Parliament).to receive(:last_or_create).and_return(parliament)
        expect(Parliament.instance).to equal(parliament)
      end

      it "caches it in Thread.current" do
        expect(Parliament).to receive(:last_or_create).and_return(parliament)
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
        expect(Parliament).not_to receive(:last_or_create)
        expect(Parliament.instance).to equal(parliament)
      end
    end
  end

  describe ".before_remove_const" do
    let(:parliament) { FactoryGirl.create(:parliament) }

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
        FactoryGirl.build(:parliament, opening_at: nil, dissolution_at: nil)
      end

      it "returns nil" do
        expect(parliament.period).to be_nil
      end
    end

    context "when opening_at is nil" do
      subject :parliament do
        FactoryGirl.build(:parliament, opening_at: nil, dissolution_at: 1.year.from_now)
      end

      it "returns nil" do
        expect(parliament.period).to be_nil
      end
    end

    context "when dissolution_at is nil" do
      subject :parliament do
        FactoryGirl.build(:parliament, opening_at: 1.year.ago, dissolution_at: nil)
      end

      it "returns nil" do
        expect(parliament.period).to be_nil
      end
    end

    context "when opening_at and dissolution_at are not nil" do
      subject :parliament do
        FactoryGirl.build(:parliament, opening_at: "2010-05-18 00:00:00", dissolution_at: "2015-03-30 00:01:00")
      end

      it "returns the years of operation" do
        expect(parliament.period).to eq("2010–2015")
      end
    end
  end

  describe "#period?" do
    context "when opening_at and dissolution_at are nil" do
      subject :parliament do
        FactoryGirl.build(:parliament, opening_at: nil, dissolution_at: nil)
      end

      it "returns false" do
        expect(parliament.period?).to eq(false)
      end
    end

    context "when opening_at is nil" do
      subject :parliament do
        FactoryGirl.build(:parliament, opening_at: nil, dissolution_at: 1.year.from_now)
      end

      it "returns false" do
        expect(parliament.period?).to eq(false)
      end
    end

    context "when dissolution_at is nil" do
      subject :parliament do
        FactoryGirl.build(:parliament, opening_at: 1.year.ago, dissolution_at: nil)
      end

      it "returns false" do
        expect(parliament.period?).to eq(false)
      end
    end

    context "when opening_at and dissolution_at are not nil" do
      subject :parliament do
        FactoryGirl.build(:parliament, opening_at: "2010-05-18 00:00:00", dissolution_at: "2015-03-30 00:01:00")
      end

      it "returns true" do
        expect(parliament.period?).to eq(true)
      end
    end
  end

  describe "#opened?" do
    context "when opening_at is nil" do
      subject :parliament do
        FactoryGirl.build(:parliament, opening_at: nil)
      end

      it "returns false" do
        expect(parliament.opened?).to eq(false)
      end
    end

    context "when opening_at is in the future" do
      subject :parliament do
        FactoryGirl.create(:parliament, opening_at: 4.weeks.from_now)
      end

      it "returns false" do
        expect(parliament.opened?).to eq(false)
      end
    end

    context "when opening_at is in the past" do
      subject :parliament do
        FactoryGirl.create(:parliament, opening_at: 2.years.ago)
      end

      it "returns true" do
        expect(parliament.opened?).to eq(true)
      end
    end
  end

  describe "#dissolution_announced?" do
    context "when dissolution_at is nil" do
      subject :parliament do
        FactoryGirl.create(:parliament)
      end

      it "returns false" do
        expect(parliament.dissolution_announced?).to eq(false)
      end
    end

    context "when dissolution_at is not nil" do
      subject :parliament do
        FactoryGirl.create(:parliament, :dissolving)
      end

      it "returns true" do
        expect(parliament.dissolution_announced?).to eq(true)
      end
    end
  end

  describe "#dissolved?" do
    context "when dissolution_at is nil" do
      subject :parliament do
        FactoryGirl.create(:parliament)
      end

      it "returns false" do
        expect(parliament.dissolved?).to eq(false)
      end
    end

    context "when dissolution_at is in the future" do
      subject :parliament do
        FactoryGirl.create(:parliament, :dissolving)
      end

      it "returns false" do
        expect(parliament.dissolved?).to eq(false)
      end
    end

    context "when dissolution_at is in the past" do
      subject :parliament do
        FactoryGirl.create(:parliament, :dissolved)
      end

      it "returns true" do
        expect(parliament.dissolved?).to eq(true)
      end
    end
  end

  describe "#registration_closed?" do
    context "when registration_closed_at is nil" do
      subject :parliament do
        FactoryGirl.create(:parliament)
      end

      it "returns false" do
        expect(parliament.registration_closed?).to eq(false)
      end
    end

    context "when registration_closed_at is in the future" do
      subject :parliament do
        FactoryGirl.create(:parliament, :dissolving, registration_closed_at: 2.weeks.from_now)
      end

      it "returns false" do
        expect(parliament.registration_closed?).to eq(false)
      end
    end

    context "when registration_closed_at is in the past" do
      subject :parliament do
        FactoryGirl.create(:parliament, :dissolved, registration_closed_at: 2.weeks.ago)
      end

      it "returns true" do
        expect(parliament.registration_closed?).to eq(true)
      end
    end
  end

  describe "#archived?" do
    context "when archived_at is nil" do
      subject :parliament do
        FactoryGirl.build(:parliament, archived_at: nil)
      end

      it "returns false" do
        expect(parliament.archived?).to eq(false)
      end
    end

    context "when archived_at is in the future" do
      subject :parliament do
        FactoryGirl.build(:parliament, archived_at: 2.weeks.from_now)
      end

      it "returns false" do
        expect(parliament.archived?).to eq(false)
      end
    end

    context "when archived_at is in the past" do
      subject :parliament do
        FactoryGirl.build(:parliament, archived_at: 2.weeks.ago)
      end

      it "returns true" do
        expect(parliament.archived?).to eq(true)
      end
    end
  end
end
