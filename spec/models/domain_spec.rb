require 'rails_helper'

RSpec.describe Domain, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:domain)).to be_valid
  end

  describe "defaults" do
    describe "#name" do
      it "defaults to nil" do
        expect(subject.name).to be_nil
      end
    end

    describe "#current_rate" do
      it "defaults to 0" do
        expect(subject.current_rate).to eq(0)
      end
    end

    describe "#maximum_rate" do
      it "defaults to 0" do
        expect(subject.maximum_rate).to eq(0)
      end
    end

    describe "#resolved_at" do
      it "defaults to nil" do
        expect(subject.resolved_at).to be_nil
      end
    end

    describe "#state" do
      it "defaults to nil" do
        expect(subject.state).to be_nil
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to allow_value("localhost").for(:name) }
    it { is_expected.to allow_value("foo-bar.com").for(:name) }
    it { is_expected.not_to allow_value("foo_bar.com").for(:name) }
    it { is_expected.to validate_numericality_of(:current_rate).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:maximum_rate).is_greater_than_or_equal_to(0) }

    %w[current_rate maximum_rate].each do |attribute|
      describe attribute do
        let(:errors) { subject.errors[attribute] }
        let(:message) { "#{attribute.humanize} must be an integer" }

        before do
          subject.update(attribute => '0.1')
        end

        it "only accepts integers" do
          expect(errors).to include(message)
        end
      end
    end
  end

  describe "scopes" do
    let!(:domain_1) { FactoryGirl.create(:domain, name: "foo.com", current_rate: 10, maximum_rate: 20) }
    let!(:domain_2) { FactoryGirl.create(:domain, name: "bar.com", current_rate: 20, maximum_rate: 40) }
    let!(:domain_3) { FactoryGirl.create(:domain, :allowed, name: "baz.com", current_rate: 5, maximum_rate: 50) }

    describe ".by_current_rate" do
      let(:domains) { described_class.by_current_rate.to_a }

      it "sorts by the current rate in descending order" do
        expect(domains).to eq([domain_2, domain_1, domain_3])
      end
    end

    describe ".exceeding" do
      let(:domains) { described_class.exceeding(10).by_current_rate.to_a }

      it "returns domains with a current rate exceeding the specified amount" do
        expect(domains).to eq([domain_2])
      end
    end

    describe ".unresolved" do
      let(:domains) { described_class.unresolved.by_current_rate.to_a }

      it "returns domains that haven't been resolved yet" do
        expect(domains).to eq([domain_2, domain_1])
      end
    end

    describe ".watchlist" do
      context "without options" do
        let(:domains) { described_class.watchlist.to_a }

        it "returns all unresolved domains sorted by the current rate" do
          expect(domains).to eq([domain_2, domain_1])
        end
      end
    end
  end

  describe "class methods" do
    describe ".cleanup_logs" do
      before do
        FactoryGirl.create(:domain_log, created_at: 2.hours.ago)
        FactoryGirl.create(:domain_log, created_at: 10.minutes.ago)
        FactoryGirl.create(:domain_log, created_at: 5.minutes.ago)
      end

      it "removes domain logs created before the specified time" do
        expect {
          described_class.cleanup_logs(1.hour.ago)
        }.to change { Domain::Log.count }.by(-1)
      end
    end

    describe ".current_rates" do
      let(:current_rates) do
        { "gmail.com" => 24, "hotmail.com" => 12, "com" => 36 }
      end

      before do
        travel_to 2.minutes.ago do
          FactoryGirl.create(:domain_log, name: "gmail.com")
          FactoryGirl.create(:domain_log, name: "hotmail.com")
          FactoryGirl.create(:domain_log, name: "gmail.com")
        end
      end

      it "returns a hash of the current signature rates per hour per domain" do
        expect(described_class.current_rates).to match(current_rates)
      end
    end

    describe ".find_or_create_by_email" do
      let(:domain) { described_class.find_or_create_by_email(email) }

      before do
        FactoryGirl.create(:domain, :blocked, name: "localhost")
        FactoryGirl.create(:domain, :allowed, name: "gmail.com")
        FactoryGirl.create(:domain, :blocked, name: "hushmail.com")
      end

      context "when the email is invalid" do
        let(:email) { "foo" }

        it "returns the localhost domain" do
          expect(domain.name).to eq("localhost")
        end

        it "is blocked" do
          expect(domain.blocked?).to eq(true)
        end
      end

      context "when the email is nil" do
        let(:email) { nil }

        it "returns the localhost domain" do
          expect(domain.name).to eq("localhost")
        end

        it "is blocked" do
          expect(domain.blocked?).to eq(true)
        end
      end

      context "when the email is ''" do
        let(:email) { "" }

        it "returns the localhost domain" do
          expect(domain.name).to eq("localhost")
        end

        it "is blocked" do
          expect(domain.blocked?).to eq(true)
        end
      end

      context "when the email domain is blacklisted" do
        let(:email) { "foo@hushmail.com" }

        it "returns the domain" do
          expect(domain.name).to eq("hushmail.com")
        end

        it "is blocked" do
          expect(domain.blocked?).to eq(true)
        end
      end

      context "when the email domain is whitelisted" do
        let(:email) { "foo@gmail.com" }

        it "returns the domain" do
          expect(domain.name).to eq("gmail.com")
        end

        it "is allowed" do
          expect(domain.allowed?).to eq(true)
        end
      end

      context "when the email domain doesn't exist" do
        let(:email) { "foo@example.com" }

        it "creates the domain" do
          expect(domain.name).to eq("example.com")
        end

        it "is allowed" do
          expect(domain.allowed?).to eq(true)
        end
      end
    end

    describe ".log" do
      let(:email) { "foo@example.com" }

      it "logs the domain of the email address" do
        expect {
          described_class.log(email)
        }.to change {
          Domain::Log.where(name: "example.com").count
        }.by(1)
      end

      it "logs the parent domain of the email address" do
        expect {
          described_class.log(email)
        }.to change {
          Domain::Log.where(name: "com").count
        }.by(1)
      end
    end

    describe ".reset_rates" do
      let!(:domain_1) { FactoryGirl.create(:domain, name: "foo.com", current_rate: 10, maximum_rate: 20) }
      let!(:domain_2) { FactoryGirl.create(:domain, name: "bar.com", current_rate: 20, maximum_rate: 40) }
      let!(:domain_3) { FactoryGirl.create(:domain, name: "baz.com", current_rate: 5, maximum_rate: 50) }

      def current_rates
        [
          domain_1.reload.current_rate,
          domain_2.reload.current_rate,
          domain_3.reload.current_rate
        ]
      end

      it "resets the current rate of of all domains to 0" do
        expect {
          described_class.reset_rates
        }.to change {
          current_rates
        }.from([10, 20, 5]).to([0, 0, 0])
      end
    end

    describe ".update_rate" do
      def domain
        described_class.find_by(name: "foo.com")
      end

      context "when the domain doesn't exist" do
        it "creates the domain record" do
          expect {
            described_class.update_rate("foo.com", 20)
          }.to change {
            described_class.exists?(name: "foo.com")
          }.from(false).to(true)
        end

        it "sets the current rate" do
          expect {
            described_class.update_rate("foo.com", 20)
          }.to change {
            domain.try(:current_rate)
          }.from(nil).to(20)
        end

        it "sets the maximum rate" do
          expect {
            described_class.update_rate("foo.com", 20)
          }.to change {
            domain.try(:maximum_rate)
          }.from(nil).to(20)
        end
      end

      context "when the domain exists" do
        before do
          FactoryGirl.create(:domain, name: "foo.com", current_rate: 10, maximum_rate: 20)
        end

        it "updates the current rate" do
          expect {
            described_class.update_rate("foo.com", 20)
          }.to change { domain.current_rate }.from(10).to(20)
        end

        context "and the new rate is less than the maximum rate" do
          it "doesn't update the maximum rate" do
            expect {
              described_class.update_rate("foo.com", 15)
            }.not_to change { domain.maximum_rate }
          end
        end

        context "and the new rate is the same as the maximum rate" do
          it "doesn't update the maximum rate" do
            expect {
              described_class.update_rate("foo.com", 20)
            }.not_to change { domain.maximum_rate }
          end
        end

        context "and the new rate is more than the maximum rate" do
          it "updates the maximum rate" do
            expect {
              described_class.update_rate("foo.com", 25)
            }.to change { domain.maximum_rate }.from(20).to(25)
          end
        end
      end
    end

    describe ".update_rates" do
      let!(:domain_1) { FactoryGirl.create(:domain, name: "foo.com", current_rate: 10, maximum_rate: 20) }
      let!(:domain_2) { FactoryGirl.create(:domain, name: "bar.com", current_rate: 20, maximum_rate: 40) }
      let!(:domain_3) { FactoryGirl.create(:domain, name: "baz.com", current_rate: 5, maximum_rate: 50) }

      def current_rates
        [
          domain_1.reload.current_rate,
          domain_2.reload.current_rate,
          domain_3.reload.current_rate
        ]
      end

      before do
        travel_to 2.minutes.ago do
          FactoryGirl.create(:domain_log, name: "foo.com")
          FactoryGirl.create(:domain_log, name: "bar.com")
          FactoryGirl.create(:domain_log, name: "foo.com")
        end
      end

      it "updates the current rates for the domains" do
        expect {
          described_class.update_rates
        }.to change {
          current_rates
        }.from([10, 20, 5]).to([24, 12, 0])
      end
    end
  end

  describe "instance methods" do
    describe "#allow!" do
      let(:domain) { FactoryGirl.create(:domain) }
      let(:now) { Time.current }

      it "sets resolved_at to the current time" do
        expect {
          domain.allow!(now)
        }.to change { domain.resolved_at }.from(nil).to(now)
      end

      it "sets state to 'allow'" do
        expect {
          domain.allow!(now)
        }.to change { domain.state }.from(nil).to("allow")
      end

      context "when then domain is already blocked" do
        let(:domain) { FactoryGirl.create(:domain, :blocked) }

        it "changes allowed? from false to true" do
          expect {
            domain.allow!(now)
          }.to change { domain.allowed? }.from(false).to(true)
        end
      end
    end

    describe "#allowed?" do
      context "when state is nil" do
        let(:domain) { FactoryGirl.create(:domain, name: "example.com", state: nil) }

        it "returns true" do
          expect(domain.allowed?).to eq(true)
        end

        context "when the parent domain state is nil" do
          before do
            FactoryGirl.create(:domain, name: "com", state: nil)
          end

          it "returns true" do
            expect(domain.allowed?).to eq(true)
          end
        end

        context "when the parent domain state is 'allow'" do
          before do
            FactoryGirl.create(:domain, name: "com", state: 'allow', resolved_at: Time.current)
          end

          it "returns true" do
            expect(domain.allowed?).to eq(true)
          end
        end

        context "when the parent domain state is 'block'" do
          before do
            FactoryGirl.create(:domain, name: "com", state: 'block', resolved_at: Time.current)
          end

          it "returns false" do
            expect(domain.allowed?).to eq(false)
          end
        end
      end

      context "when state is 'allow'" do
        let(:domain) { FactoryGirl.create(:domain, state: "allow", resolved_at: Time.current) }

        it "returns true" do
          expect(domain.allowed?).to eq(true)
        end
      end

      context "when state is 'block'" do
        let(:domain) { FactoryGirl.create(:domain, state: "block", resolved_at: Time.current) }

        it "returns false" do
          expect(domain.allowed?).to eq(false)
        end
      end
    end

    describe "#block!" do
      let(:domain) { FactoryGirl.create(:domain) }
      let(:now) { Time.current }

      it "sets resolved_at to the current time" do
        expect {
          domain.block!(now)
        }.to change { domain.resolved_at }.from(nil).to(now)
      end

      it "sets state to 'block'" do
        expect {
          domain.block!(now)
        }.to change { domain.state }.from(nil).to("block")
      end

      context "when then domain is already allowed" do
        let(:domain) { FactoryGirl.create(:domain, :allowed) }

        it "changes blocked? from false to true" do
          expect {
            domain.block!(now)
          }.to change { domain.blocked? }.from(false).to(true)
        end
      end
    end

    describe "#blocked?" do
      context "when state is nil" do
        let(:domain) { FactoryGirl.create(:domain, name: "foobar.com", state: nil) }

        it "returns false" do
          expect(domain.blocked?).to eq(false)
        end

        context "when the parent domain state is nil" do
          before do
            FactoryGirl.create(:domain, name: "com", state: nil)
          end

          it "returns false" do
            expect(domain.blocked?).to eq(false)
          end
        end

        context "when the parent domain state is 'allow'" do
          before do
            FactoryGirl.create(:domain, name: "com", state: 'allow', resolved_at: Time.current)
          end

          it "returns false" do
            expect(domain.blocked?).to eq(false)
          end
        end

        context "when the parent domain state is 'block'" do
          before do
            FactoryGirl.create(:domain, name: "com", state: 'block', resolved_at: Time.current)
          end

          it "returns true" do
            expect(domain.blocked?).to eq(true)
          end
        end
      end

      context "when state is 'allow'" do
        let(:domain) { FactoryGirl.create(:domain, state: "allow", resolved_at: Time.current) }

        it "returns false" do
          expect(domain.blocked?).to eq(false)
        end
      end

      context "when state is 'block'" do
        let(:domain) { FactoryGirl.create(:domain, state: "block", resolved_at: Time.current) }

        it "returns true" do
          expect(domain.blocked?).to eq(true)
        end
      end
    end

    describe "#resolved?" do
      context "when resolved_at is nil" do
        let(:domain) { FactoryGirl.create(:domain, resolved_at: nil) }

        it "returns false" do
          expect(domain.resolved?).to eq(false)
        end
      end

      context "when resolved_at is set" do
        let(:domain) { FactoryGirl.create(:domain, resolved_at: Time.current) }

        it "returns true" do
          expect(domain.resolved?).to eq(true)
        end
      end
    end

    describe "#update_rate" do
      let(:domain) { FactoryGirl.create(:domain, current_rate: 10, maximum_rate: 20) }

      it "updates the current rate" do
        expect {
          domain.update_rate(20)
        }.to change { domain.current_rate }.from(10).to(20)
      end

      context "when the new rate is less than the maximum rate" do
        it "doesn't update the maximum rate" do
          expect {
            domain.update_rate(15)
          }.not_to change { domain.maximum_rate }
        end
      end

      context "when the new rate is the same as the maximum rate" do
        it "doesn't update the maximum rate" do
          expect {
            domain.update_rate(20)
          }.not_to change { domain.maximum_rate }
        end
      end

      context "when the new rate is more than the maximum rate" do
        it "updates the maximum rate" do
          expect {
            domain.update_rate(25)
          }.to change { domain.maximum_rate }.from(20).to(25)
        end
      end
    end
  end
end
