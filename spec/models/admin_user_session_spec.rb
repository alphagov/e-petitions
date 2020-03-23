require 'rails_helper'

RSpec.describe AdminUserSession do
  describe "#last_login_attempt?" do
    before do
      Authlogic::Session::Base.controller = Authlogic::TestCase::MockController.new
      FactoryBot.create(:moderator_user, email: email)
    end

    let(:email) { "admin@petitions.senedd.wales" }
    let(:params) { { email: email, password: "password" } }
    let(:user_session) { described_class.new(params) }
    let(:user) { AdminUser.find_by!(email: email) }

    context "when there are no failed login attempts" do
      before do
        user.update_columns(failed_login_count: 0)
        user_session.save
      end

      it "returns false" do
        expect(user_session.attempted_record).to be_present
        expect(user_session.last_login_attempt?).to be false
      end
    end

    context "when there are 3 failed login attempts" do
      before do
        user.update_columns(failed_login_count: 3)
        user_session.save
      end

      it "returns true" do
        expect(user_session.attempted_record).to be_present
        expect(user_session.last_login_attempt?).to be true
      end
    end

    context "when there are 4 failed login attempts" do
      before do
        user.update_columns(failed_login_count: 4)
        user_session.save
      end

      it "returns false" do
        expect(user_session.attempted_record).to be_present
        expect(user_session.last_login_attempt?).to be false
      end
    end
  end
end
