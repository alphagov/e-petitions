require 'rails_helper'

RSpec.describe Domain, type: :model do
  subject { FactoryBot.build(:domain) }

  it "has a valid factory" do
    expect(FactoryBot.build(:domain)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:canonical_domain_id).of_type(:integer).with_options(null: true) }
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(limit: 100, null: false) }
    it { is_expected.to have_db_column(:strip_characters).of_type(:string).with_options(limit: 10, null: true) }
    it { is_expected.to have_db_column(:strip_extension).of_type(:string).with_options(limit: 10, default: "+", null: true) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index(:canonical_domain_id) }
    it { is_expected.to have_db_index(:name).unique }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:strip_characters).is_at_most(10) }
    it { is_expected.to validate_length_of(:strip_extension).is_at_most(10) }

    it { is_expected.to allow_value("*").for(:name) }
    it { is_expected.to allow_value("*.com").for(:name) }
    it { is_expected.to allow_value("*.example.com").for(:name) }
    it { is_expected.to allow_value("example.com").for(:name) }
    it { is_expected.to allow_value("example.co.uk").for(:name) }
    it { is_expected.not_to allow_value("example").for(:name) }
  end

  describe "callbacks" do
    context "when aliased_domain is set" do
      let!(:gmail) { FactoryBot.create(:domain, name: "gmail.com") }
      let!(:domain) { FactoryBot.build(:domain, name: "googlemail.com", aliased_domain: "gmail.com") }

      it "sets the canonical domain association" do
        expect {
          domain.save
        }.to change {
          domain.canonical_domain
        }.from(nil).to(gmail)
      end
    end
  end

  describe ".by_name" do
    let!(:domain_1) { FactoryBot.create(:domain, name: "baz.com") }
    let!(:domain_2) { FactoryBot.create(:domain, name: "foo.com") }
    let!(:domain_3) { FactoryBot.create(:domain, name: "bar.com") }

    it "returns domains in alphabetical order" do
      expect(described_class.by_name).to match_array([domain_3, domain_1, domain_2])
    end
  end

  describe ".normalize" do
    let(:email) { "bob.jones+petitions@example.com" }
    let(:canonical_email) { described_class.normalize(email) }

    context "when a global rule matches" do
      before do
        FactoryBot.create(:domain, name: "*")
      end

      it "normalizes the email address" do
        expect(canonical_email).to eq("bobjones@example.com")
      end
    end

    context "when a wildcard rule matches" do
      before do
        FactoryBot.create(:domain, name: "*.com")
      end

      it "normalizes the email address" do
        expect(canonical_email).to eq("bobjones@example.com")
      end
    end

    context "when a domain rule " do
      before do
        FactoryBot.create(:domain, name: "example.com")
      end

      it "normalizes the email address" do
        expect(canonical_email).to eq("bobjones@example.com")
      end
    end

    context "when multiple rules match" do
      before do
        FactoryBot.create(:domain, name: "*", strip_characters: nil, strip_extension: nil)
        FactoryBot.create(:domain, name: "*.com", strip_characters: nil, strip_extension: nil)
        FactoryBot.create(:domain, name: "example.com")
      end

      it "normalizes the email address using the most specific rule" do
        expect(canonical_email).to eq("bobjones@example.com")
      end
    end

    context "when there are multiple strip characters" do
      before do
        FactoryBot.create(:domain, name: "example.com", strip_characters: "._")
      end

      context "and the email uses the first character only" do
        let(:email) { "bob.jones@example.com" }

        it "normalizes the email address" do
          expect(canonical_email).to eq("bobjones@example.com")
        end
      end

      context "and the email uses the second character only" do
        let(:email) { "bob_jones@example.com" }

        it "normalizes the email address" do
          expect(canonical_email).to eq("bobjones@example.com")
        end
      end

      context "and the email uses both characters" do
        let(:email) { "bob_and_alice.jones@example.com" }

        it "normalizes the email address" do
          expect(canonical_email).to eq("bobandalicejones@example.com")
        end
      end
    end

    context "when there are multiple extension characters" do
      before do
        FactoryBot.create(:domain, name: "example.com", strip_extension: "+-")
      end

      context "and the email uses the first character only" do
        let(:email) { "bob+petitions@example.com" }

        it "normalizes the email address" do
          expect(canonical_email).to eq("bob@example.com")
        end
      end

      context "and the email uses the second character only" do
        let(:email) { "bob-petitions@example.com" }

        it "normalizes the email address" do
          expect(canonical_email).to eq("bob@example.com")
        end
      end

      context "and the email uses both characters" do
        let(:email) { "bob-petitions+20000@example.com" }

        it "normalizes the email address" do
          expect(canonical_email).to eq("bob@example.com")
        end
      end
    end

    context "when the domain is an alias" do
      let(:email) { "bob.jones+petitions@googlemail.com" }

      before do
        FactoryBot.create(:domain, name: "gmail.com")
        FactoryBot.create(:domain, name: "googlemail.com", aliased_domain: "gmail.com")
      end

      it "normalizes the email address" do
        expect(canonical_email).to eq("bobjones@gmail.com")
      end
    end
  end
end
