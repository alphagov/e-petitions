require 'rails_helper'

RSpec.describe Site, type: :model do
  describe "schema" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(limit: 50, null: false, default: "Petition parliament") }
    it { is_expected.to have_db_column(:url).of_type(:string).with_options(limit: 50, null: false, default: "https://petition.parliament.uk") }
    it { is_expected.to have_db_column(:email_from).of_type(:string).with_options(limit: 100, null: false, default: %{"Petitions: UK Government and Parliament" <no-reply@petition.parliament.uk>}) }
    it { is_expected.to have_db_column(:username).of_type(:string).with_options(limit: 30) }
    it { is_expected.to have_db_column(:password_digest).of_type(:string).with_options(limit: 60) }
    it { is_expected.to have_db_column(:enabled).of_type(:boolean).with_options(null: false, default: true) }
    it { is_expected.to have_db_column(:protected).of_type(:boolean).with_options(null: false, default: false) }
    it { is_expected.to have_db_column(:petition_duration).of_type(:integer).with_options(null: false, default: 6) }
    it { is_expected.to have_db_column(:minimum_number_of_sponsors).of_type(:integer).with_options(null: false, default: 5) }
    it { is_expected.to have_db_column(:maximum_number_of_sponsors).of_type(:integer).with_options(null: false, default: 20) }
    it { is_expected.to have_db_column(:threshold_for_moderation).of_type(:integer).with_options(null: false, default: 5) }
    it { is_expected.to have_db_column(:threshold_for_response).of_type(:integer).with_options(null: false, default: 10000) }
    it { is_expected.to have_db_column(:threshold_for_debate).of_type(:integer).with_options(null: false, default: 100000) }
    it { is_expected.to have_db_column(:last_checked_at).of_type(:datetime).with_options(null: true, default: nil) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:feedback_email).of_type(:string).with_options(limit: 100, default: '"Petitions: UK Government and Parliament" <petitionscommittee@parliament.uk>') }
    it { is_expected.to have_db_column(:last_petition_created_at).of_type(:datetime).with_options(null: true, default: nil) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:email_from) }
    it { is_expected.to validate_presence_of(:petition_duration) }
    it { is_expected.to validate_presence_of(:minimum_number_of_sponsors) }
    it { is_expected.to validate_presence_of(:maximum_number_of_sponsors) }
    it { is_expected.to validate_presence_of(:threshold_for_moderation) }
    it { is_expected.to validate_presence_of(:threshold_for_response) }
    it { is_expected.to validate_presence_of(:threshold_for_debate) }

    it { is_expected.to validate_length_of(:title).is_at_most(50) }
    it { is_expected.to validate_length_of(:url).is_at_most(50) }
    it { is_expected.to validate_length_of(:email_from).is_at_most(100) }
    it { is_expected.to validate_length_of(:feedback_email).is_at_most(100) }

    it { is_expected.to validate_numericality_of(:petition_duration).only_integer }
    it { is_expected.to validate_numericality_of(:minimum_number_of_sponsors).only_integer }
    it { is_expected.to validate_numericality_of(:maximum_number_of_sponsors).only_integer }
    it { is_expected.to validate_numericality_of(:threshold_for_moderation).only_integer }
    it { is_expected.to validate_numericality_of(:threshold_for_response).only_integer }
    it { is_expected.to validate_numericality_of(:threshold_for_debate).only_integer }

    context "when protected" do
      subject { described_class.new(protected: true) }

      it { is_expected.to validate_presence_of(:username) }
      it { is_expected.to validate_presence_of(:password) }
      it { is_expected.to validate_length_of(:username).is_at_most(30) }
      it { is_expected.to validate_length_of(:password).is_at_most(30) }
      it { is_expected.to validate_confirmation_of(:password) }
    end
  end

  describe "singleton methods" do
    let(:site) { Site.first_or_create(Site.defaults) }
    let(:now) { Time.current }

    before do
      allow(Site).to receive(:first_or_create).and_return(site)
    end

    it "delegates title to the instance" do
      expect(site).to receive(:title).and_return("Petition parliament (Test)")
      expect(Site.title).to eq("Petition parliament (Test)")
    end

    it "delegates url to the instance" do
      expect(site).to receive(:url).and_return("https://petition.parliament.test")
      expect(Site.url).to eq("https://petition.parliament.test")
    end

    it "delegates email_from to the instance" do
      expect(site).to receive(:email_from).and_return("no-reply@petition.parliament.test")
      expect(Site.email_from).to eq("no-reply@petition.parliament.test")
    end

    it "delegates username to the instance" do
      expect(site).to receive(:username).and_return("username")
      expect(Site.username).to eq("username")
    end

    it "delegates password_digest to the instance" do
      expect(site).to receive(:password_digest).and_return("password_digest")
      expect(Site.password_digest).to eq("password_digest")
    end

    it "delegates enabled? to the instance" do
      expect(site).to receive(:enabled?).and_return(false)
      expect(Site.enabled?).to eq(false)
    end

    it "delegates constraints_for_public to the instance" do
      expect(site).to receive(:constraints_for_public).and_return(
        protocol: "https://", host: "petition.parliament.test", port: 443
      )

      expect(Site.constraints_for_public).to eq(
        protocol: "https://", host: "petition.parliament.test", port: 443
      )
    end

    it "delegates constraints_for_moderation to the instance" do
      expect(site).to receive(:constraints_for_moderation).and_return(
        protocol: "https://", host: "moderate.petition.parliament.test", port: 443
      )

      expect(Site.constraints_for_moderation).to eq(
        protocol: "https://", host: "moderate.petition.parliament.test", port: 443
      )
    end

    it "delegates host to the instance" do
      expect(site).to receive(:host).and_return("petition.parliament.test")
      expect(Site.host).to eq("petition.parliament.test")
    end

    it "delegates host_with_port to the instance" do
      expect(site).to receive(:host_with_port).and_return("petition.parliament.test:8443")
      expect(Site.host_with_port).to eq("petition.parliament.test:8443")
    end

    it "delegates moderate_host to the instance" do
      expect(site).to receive(:moderate_host).and_return("moderate.petition.parliament.test")
      expect(Site.moderate_host).to eq("moderate.petition.parliament.test")
    end

    it "delegates moderate_host_with_port to the instance" do
      expect(site).to receive(:moderate_host_with_port).and_return("moderate.petition.parliament.test:8443")
      expect(Site.moderate_host_with_port).to eq("moderate.petition.parliament.test:8443")
    end

    it "delegates port to the instance" do
      expect(site).to receive(:port).and_return(443)
      expect(Site.port).to eq(443)
    end

    it "delegates protected? to the instance" do
      expect(site).to receive(:protected?).and_return(true)
      expect(Site.protected?).to eq(true)
    end

    it "delegates petition_duration to the instance" do
      expect(site).to receive(:petition_duration).and_return(3)
      expect(Site.petition_duration).to eq(3)
    end

    it "delegates minimum_number_of_sponsors to the instance" do
      expect(site).to receive(:minimum_number_of_sponsors).and_return(1)
      expect(Site.minimum_number_of_sponsors).to eq(1)
    end

    it "delegates maximum_number_of_sponsors to the instance" do
      expect(site).to receive(:maximum_number_of_sponsors).and_return(5)
      expect(Site.maximum_number_of_sponsors).to eq(5)
    end

    it "delegates threshold_for_moderation to the instance" do
      expect(site).to receive(:threshold_for_moderation).and_return(5)
      expect(Site.threshold_for_moderation).to eq(5)
    end

    it "delegates formatted_threshold_for_moderation to the instance" do
      expect(site).to receive(:formatted_threshold_for_moderation).and_return("5,000")
      expect(Site.formatted_threshold_for_moderation).to eq("5,000")
    end

    it "delegates threshold_for_response to the instance" do
      expect(site).to receive(:threshold_for_response).and_return(10)
      expect(Site.threshold_for_response).to eq(10)
    end

    it "delegates formatted_threshold_for_response to the instance" do
      expect(site).to receive(:formatted_threshold_for_response).and_return("10,000")
      expect(Site.formatted_threshold_for_response).to eq("10,000")
    end

    it "delegates threshold_for_debate to the instance" do
      expect(site).to receive(:threshold_for_debate).and_return(100)
      expect(Site.threshold_for_debate).to eq(100)
    end

    it "delegates formatted_threshold_for_debate to the instance" do
      expect(site).to receive(:formatted_threshold_for_debate).and_return("100,000")
      expect(Site.formatted_threshold_for_debate).to eq("100,000")
    end

    it "delegates last_checked_at to the instance" do
      expect(site).to receive(:last_checked_at).and_return(now)
      expect(Site.last_checked_at).to eq(now)
    end

    it "delegates created_at to the instance" do
      expect(site).to receive(:created_at).and_return(now)
      expect(Site.created_at).to eq(now)
    end

    it "delegates updated_at to the instance" do
      expect(site).to receive(:updated_at).and_return(now)
      expect(Site.updated_at).to eq(now)
    end

    it "delegates last_petition_created_at to the instance" do
      expect(site).to receive(:last_petition_created_at).and_return(now)
      expect(Site.last_petition_created_at).to eq(now)
    end
  end

  describe "defaults" do
    subject(:defaults) { described_class.defaults }

    before do
      allow(ENV).to receive(:fetch).and_call_original
    end

    describe "for title" do
      it "defaults to 'Petition parliament'" do
        allow(ENV).to receive(:fetch).with("SITE_TITLE", "Petition parliament").and_return("Petition parliament")
        expect(defaults[:title]).to eq("Petition parliament")
      end

      it "can be overridden with the SITE_TITLE environment variable" do
        allow(ENV).to receive(:fetch).with("SITE_TITLE", "Petition parliament").and_return("Petition parliament (Test)")
        expect(defaults[:title]).to eq("Petition parliament (Test)")
      end
    end

    describe "for url" do
      it "defaults to 'https://petition.parliament.uk'" do
        allow(ENV).to receive(:fetch).with("EPETITIONS_PROTOCOL", "https").and_return("https")
        allow(ENV).to receive(:fetch).with("EPETITIONS_HOST", "petition.parliament.uk").and_return("petition.parliament.uk")
        allow(ENV).to receive(:fetch).with("EPETITIONS_PORT", '443').and_return(443)

        expect(defaults[:url]).to eq("https://petition.parliament.uk")
      end

      it "allows overriding via environment variables" do
        allow(ENV).to receive(:fetch).with("EPETITIONS_PROTOCOL", "https").and_return("http")
        allow(ENV).to receive(:fetch).with("EPETITIONS_HOST", "petition.parliament.uk").and_return("localhost")
        allow(ENV).to receive(:fetch).with("EPETITIONS_PORT", '443').and_return("3000")

        expect(defaults[:url]).to eq("http://localhost:3000")
      end
    end

    describe "for moderate_url" do
      it "defaults to 'https://moderate.petition.parliament.uk'" do
        allow(ENV).to receive(:fetch).with("EPETITIONS_PROTOCOL", "https").and_return("https")
        allow(ENV).to receive(:fetch).with("MODERATE_HOST", "moderate.petition.parliament.uk").and_return("moderate.petition.parliament.uk")
        allow(ENV).to receive(:fetch).with("EPETITIONS_PORT", '443').and_return(443)

        expect(defaults[:moderate_url]).to eq("https://moderate.petition.parliament.uk")
      end

      it "allows overriding via environment variables" do
        allow(ENV).to receive(:fetch).with("EPETITIONS_PROTOCOL", "https").and_return("http")
        allow(ENV).to receive(:fetch).with("MODERATE_HOST", "moderate.petition.parliament.uk").and_return("localhost")
        allow(ENV).to receive(:fetch).with("EPETITIONS_PORT", '443').and_return("3000")

        expect(defaults[:moderate_url]).to eq("http://localhost:3000")
      end
    end

    describe "for email_from" do
      it "defaults to 'no-reply@petition.parliament.uk'" do
        allow(ENV).to receive(:fetch).with("EPETITIONS_PROTOCOL", "https").and_return("https")
        allow(ENV).to receive(:fetch).with("EPETITIONS_HOST", "petition.parliament.uk").and_return("petition.parliament.uk")
        allow(ENV).to receive(:fetch).with("EPETITIONS_PORT", '443').and_return(443)

        expect(defaults[:email_from]).to eq(%{"Petitions: UK Government and Parliament" <no-reply@petition.parliament.uk>})
      end

      it "allows overriding via the url environment variables" do
        allow(ENV).to receive(:fetch).with("EPETITIONS_PROTOCOL", "https").and_return("http")
        allow(ENV).to receive(:fetch).with("EPETITIONS_HOST", "petition.parliament.uk").and_return("localhost")
        allow(ENV).to receive(:fetch).with("EPETITIONS_PORT", '443').and_return("3000")

        expect(defaults[:email_from]).to eq(%{"Petitions: UK Government and Parliament" <no-reply@localhost>})
      end

      it "allows overriding via the EPETITIONS_FROM environment variables" do
        allow(ENV).to receive(:fetch).with("EPETITIONS_FROM", %{"Petitions: UK Government and Parliament" <no-reply@petition.parliament.uk>}).and_return("no-reply@downingstreet.gov.uk")
        expect(defaults[:email_from]).to eq("no-reply@downingstreet.gov.uk")
      end
    end

    describe "for feedback_email" do
      it "defaults to 'petitionscommittee@parliament.uk'" do
        allow(ENV).to receive(:fetch).with("EPETITIONS_PROTOCOL", "https").and_return("https")
        allow(ENV).to receive(:fetch).with("EPETITIONS_HOST", "petition.parliament.uk").and_return("petition.parliament.uk")
        allow(ENV).to receive(:fetch).with("EPETITIONS_PORT", '443').and_return(443)

        expect(defaults[:feedback_email]).to eq(%{"Petitions: UK Government and Parliament" <petitionscommittee@parliament.uk>})
      end

      it "allows overriding via the url environment variables" do
        allow(ENV).to receive(:fetch).with("EPETITIONS_PROTOCOL", "https").and_return("http")
        allow(ENV).to receive(:fetch).with("EPETITIONS_HOST", "petition.parliament.uk").and_return("localhost")
        allow(ENV).to receive(:fetch).with("EPETITIONS_PORT", '443').and_return("3000")

        expect(defaults[:feedback_email]).to eq(%{"Petitions: UK Government and Parliament" <petitionscommittee@localhost>})
      end

      it "allows overriding via the EPETITIONS_FEEDBACK environment variables" do
        allow(ENV).to receive(:fetch).with("EPETITIONS_FEEDBACK", %{"Petitions: UK Government and Parliament" <petitionscommittee@parliament.uk>}).and_return("petitions@downingstreet.gov.uk")
        expect(defaults[:feedback_email]).to eq("petitions@downingstreet.gov.uk")
      end
    end

    describe "for username" do
      it "defaults to nil" do
        allow(ENV).to receive(:fetch).with("SITE_USERNAME", nil).and_return(nil)
        expect(defaults[:username]).to be_nil
      end

      it "can be overridden with the SITE_USERNAME environment variable" do
        allow(ENV).to receive(:fetch).with("SITE_USERNAME", nil).and_return("petitions")
        expect(defaults[:username]).to eq("petitions")
      end

      it "is nil if the SITE_USERNAME environment variable is set to ''" do
        allow(ENV).to receive(:fetch).with("SITE_USERNAME", nil).and_return("")
        expect(defaults[:username]).to be_nil
      end
    end

    describe "for password" do
      it "defaults to nil" do
        allow(ENV).to receive(:fetch).with("SITE_PASSWORD", nil).and_return(nil)
        expect(defaults[:password]).to be_nil
      end

      it "can be overridden with the SITE_PASSWORD environment variable" do
        allow(ENV).to receive(:fetch).with("SITE_PASSWORD", nil).and_return("letmein")
        expect(defaults[:password]).to eq("letmein")
      end

      it "is nil if the SITE_PASSWORD environment variable is set to ''" do
        allow(ENV).to receive(:fetch).with("SITE_PASSWORD", nil).and_return("")
        expect(defaults[:password]).to be_nil
      end
    end

    describe "for enabled" do
      it "defaults to true" do
        allow(ENV).to receive(:fetch).with("SITE_ENABLED", '1').and_return("1")
        expect(defaults[:enabled]).to eq(true)
      end

      it "can be overridden with the SITE_ENABLED environment variable" do
        allow(ENV).to receive(:fetch).with("SITE_ENABLED", '1').and_return("0")
        expect(defaults[:enabled]).to eq(false)
      end
    end

    describe "for protected" do
      it "defaults to false" do
        allow(ENV).to receive(:fetch).with("SITE_PROTECTED", '0').and_return("0")
        expect(defaults[:protected]).to eq(false)
      end

      it "can be overridden with the SITE_PROTECTED environment variable" do
        allow(ENV).to receive(:fetch).with("SITE_PROTECTED", '0').and_return("1")
        expect(defaults[:protected]).to eq(true)
      end
    end

    describe "for petition_duration" do
      it "defaults to 6" do
        allow(ENV).to receive(:fetch).with("PETITION_DURATION", '6').and_return("6")
        expect(defaults[:petition_duration]).to eq(6)
      end

      it "can be overridden with the PETITION_DURATION environment variable" do
        allow(ENV).to receive(:fetch).with("PETITION_DURATION", '6').and_return("12")
        expect(defaults[:petition_duration]).to eq(12)
      end
    end

    describe "for minimum_number_of_sponsors" do
      it "defaults to 5" do
        allow(ENV).to receive(:fetch).with("MINIMUM_NUMBER_OF_SPONSORS", '5').and_return("5")
        expect(defaults[:minimum_number_of_sponsors]).to eq(5)
      end

      it "can be overridden with the MINIMUM_NUMBER_OF_SPONSORS environment variable" do
        allow(ENV).to receive(:fetch).with("MINIMUM_NUMBER_OF_SPONSORS", '5').and_return("3")
        expect(defaults[:minimum_number_of_sponsors]).to eq(3)
      end
    end

    describe "for maximum_number_of_sponsors" do
      it "defaults to 20" do
        allow(ENV).to receive(:fetch).with("MAXIMUM_NUMBER_OF_SPONSORS", '20').and_return("20")
        expect(defaults[:maximum_number_of_sponsors]).to eq(20)
      end

      it "can be overridden with the MAXIMUM_NUMBER_OF_SPONSORS environment variable" do
        allow(ENV).to receive(:fetch).with("MAXIMUM_NUMBER_OF_SPONSORS", '20').and_return("50")
        expect(defaults[:maximum_number_of_sponsors]).to eq(50)
      end
    end

    describe "for threshold_for_moderation" do
      it "defaults to 5" do
        allow(ENV).to receive(:fetch).with("THRESHOLD_FOR_MODERATION", '5').and_return("5")
        expect(defaults[:threshold_for_moderation]).to eq(5)
      end

      it "can be overridden with the THRESHOLD_FOR_MODERATION environment variable" do
        allow(ENV).to receive(:fetch).with("THRESHOLD_FOR_MODERATION", '5').and_return("10")
        expect(defaults[:threshold_for_moderation]).to eq(10)
      end
    end

    describe "for threshold_for_response" do
      it "defaults to 10000" do
        allow(ENV).to receive(:fetch).with("THRESHOLD_FOR_RESPONSE", '10000').and_return("10000")
        expect(defaults[:threshold_for_response]).to eq(10000)
      end

      it "can be overridden with the THRESHOLD_FOR_RESPONSE environment variable" do
        allow(ENV).to receive(:fetch).with("THRESHOLD_FOR_RESPONSE", '10000').and_return("5000")
        expect(defaults[:threshold_for_response]).to eq(5000)
      end
    end

    describe "for threshold_for_debate" do
      it "defaults to 10000" do
        allow(ENV).to receive(:fetch).with("THRESHOLD_FOR_DEBATE", '100000').and_return("100000")
        expect(defaults[:threshold_for_debate]).to eq(100000)
      end

      it "can be overridden with the THRESHOLD_FOR_DEBATE environment variable" do
        allow(ENV).to receive(:fetch).with("THRESHOLD_FOR_DEBATE", '100000').and_return("50000")
        expect(defaults[:threshold_for_debate]).to eq(50000)
      end
    end
  end

  describe ".authenticate" do
    let(:site) { Site.first_or_create(Site.defaults) }

    before do
      expect(Site).to receive(:first_or_create).and_return(site)
    end

    it "delegates authenticate to the instance" do
      expect(site).to receive(:authenticate).with("username", "password").and_return(true)
      expect(Site.authenticate("username", "password")).to eq(true)
    end
  end

  describe ".email_protocol" do
    let(:site) { Site.first_or_create(Site.defaults) }

    before do
      expect(Site).to receive(:first_or_create).and_return(site)
    end

    it "delegates email_protocol to the instance" do
      expect(site).to receive(:email_protocol).and_return("https")
      expect(Site.email_protocol).to eq("https")
    end
  end

  describe ".opened_at_for_closing" do
    let(:site) { Site.first_or_create(Site.defaults) }
    let(:opened_at) { 3.months.ago.end_of_day }

    before do
      expect(Site).to receive(:first_or_create).and_return(site)
    end

    it "delegates opened_at_for_closing to the instance" do
      expect(site).to receive(:opened_at_for_closing).and_return(opened_at)
      expect(Site.opened_at_for_closing).to eq(opened_at)
    end
  end

  describe ".closed_at_for_opening" do
    let(:site) { Site.first_or_create(Site.defaults) }
    let(:closed_at) { 3.months.from_now.end_of_day }

    before do
      expect(Site).to receive(:first_or_create).and_return(site)
    end

    it "delegates opened_at_for_closing to the instance" do
      expect(site).to receive(:closed_at_for_opening).and_return(closed_at)
      expect(Site.closed_at_for_opening).to eq(closed_at)
    end
  end

  describe ".reload" do
    let(:site) { Site.first_or_create(Site.defaults) }

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__site__] = site
      end

      it "clears the cached instance in Thread.current" do
        expect{ Site.reload }.to change {
          Thread.current[:__site__]
        }.from(site).to(nil)
      end
    end
  end

  describe ".touch" do
    let(:site) { described_class.create! }

    before do
      expect(Site).to receive(:first_or_create).and_return(site)
    end

    it "delegates to the instance" do
      expect(site).to receive(:touch).with(:last_checked_at).and_return(true)
      expect(Site.touch(:last_checked_at)).to eq(true)
    end

    it "can accept multiple names" do
      expect(site).to receive(:touch).with(:last_checked_at, :updated_at).and_return(true)
      expect(Site.touch(:last_checked_at, :updated_at)).to eq(true)
    end
  end

  describe ".instance" do
    let(:site) { described_class.create! }

    context "when it isn't cached in Thread.current" do
      before do
        Thread.current[:__site__] = nil
      end

      after do
        Site.reload
      end

      it "finds the first record or creates it" do
        expect(Site).to receive(:first_or_create).and_return(site)
        expect(Site.instance).to equal(site)
      end

      it "caches it in Thread.current" do
        expect(Site).to receive(:first_or_create).and_return(site)
        expect(Site.instance).to equal(Thread.current[:__site__])
      end
    end

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__site__] = site
      end

      after do
        Site.reload
      end

      it "returns the cached instance" do
        expect(Site).not_to receive(:first_or_create)
        expect(Site.instance).to equal(site)
      end
    end
  end

  describe ".before_remove_const" do
    let(:site) { described_class.create! }

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__site__] = site
      end

      it "clears the cached instance in Thread.current" do
        expect{ Site.before_remove_const }.to change {
          Thread.current[:__site__]
        }.from(site).to(nil)
      end
    end
  end

  describe "#authenticate" do
    subject :site do
      described_class.create!(username: "petitions", password: "letmein")
    end

    context "when the username and password are correct" do
      it "returns true" do
        expect(site.authenticate("petitions", "letmein")).to eq(true)
      end
    end

    context "when the username and password are incorrect" do
      it "returns false" do
        expect(site.authenticate("petitions", "!letmein")).to eq(false)
      end
    end
  end

  describe "#email_protocol" do
    subject :site do
      described_class.create!(url: "https://petition.parliament.test")
    end

    it "the protocol of the url" do
      expect(site.email_protocol).to eq("https")
    end
  end

  describe "#formatted_threshold_for_moderation" do
    subject :site do
      described_class.create!(threshold_for_moderation: 5000)
    end

    it "returns a formatted number" do
      expect(site.formatted_threshold_for_moderation).to eq("5,000")
    end
  end

  describe "#formatted_threshold_for_response" do
    subject :site do
      described_class.create!(threshold_for_response: 10000)
    end

    it "returns a formatted number" do
      expect(site.formatted_threshold_for_response).to eq("10,000")
    end
  end

  describe "#formatted_threshold_for_debate" do
    subject :site do
      described_class.create!(threshold_for_debate: 100000)
    end

    it "returns a formatted number" do
      expect(site.formatted_threshold_for_debate).to eq("100,000")
    end
  end

  describe "#constraints_for_public" do
    subject :site do
      described_class.create!(url: "https://petition.parliament.test")
    end

    it "a hash of routing constraints" do
      expect(site.constraints_for_public).to eq(
        protocol: "https://", host: "petition.parliament.test", port: 443
      )
    end
  end

  describe "#constraints_for_moderation" do
    subject :site do
      described_class.create!(moderate_url: "https://moderate.petition.parliament.test")
    end

    it "a hash of routing constraints" do
      expect(site.constraints_for_moderation).to eq(
        protocol: "https://", host: "moderate.petition.parliament.test", port: 443
      )
    end
  end

  describe "#host" do
    subject :site do
      described_class.create!(url: "https://petition.parliament.test")
    end

    it "the host of the url" do
      expect(site.host).to eq("petition.parliament.test")
    end
  end

  describe "#host_with_port" do
    context "when the port is the default port" do
      subject :site do
        described_class.create!(url: "https://petition.parliament.test")
      end

      it "the host without the port of the url" do
        expect(site.host_with_port).to eq("petition.parliament.test")
      end
    end

    context "when the port is not the default port" do
      subject :site do
        described_class.create!(url: "https://petition.parliament.test:8443")
      end

      it "the host with the port of the url" do
        expect(site.host_with_port).to eq("petition.parliament.test:8443")
      end
    end
  end

  describe "#moderate_host" do
    subject :site do
      described_class.create!(moderate_url: "https://moderate.petition.parliament.test")
    end

    it "the moderation host of the url" do
      expect(site.moderate_host).to eq("moderate.petition.parliament.test")
    end
  end

  describe "#moderate_host_with_port" do
    context "when the port is the default port" do
      subject :site do
        described_class.create!(moderate_url: "https://moderate.petition.parliament.test")
      end

      it "the moderation host without the port of the url" do
        expect(site.moderate_host_with_port).to eq("moderate.petition.parliament.test")
      end
    end

    context "when the port is not the default port" do
      subject :site do
        described_class.create!(moderate_url: "https://moderate.petition.parliament.test:8443")
      end

      it "the moderation host with the port of the url" do
        expect(site.moderate_host_with_port).to eq("moderate.petition.parliament.test:8443")
      end
    end
  end

  describe "#port" do
    subject :site do
      described_class.create!(url: "https://petition.parliament.test")
    end

    it "the port of the url" do
      expect(site.port).to eq(443)
    end
  end

  describe "#opened_at_for_closing" do
    subject :site do
      described_class.create!(petition_duration: 3)
    end

    it "returns the opening date at petition_duration months ago" do
      expect(site.opened_at_for_closing).to eq(3.months.ago.end_of_day)
    end
  end

  describe "#closed_at_for_opening" do
    subject :site do
      described_class.create!(petition_duration: 3)
    end

    it "returns the closing date at petition_duration months in the future" do
      expect(site.closed_at_for_opening).to eq(3.months.from_now.end_of_day)
    end
  end
end
