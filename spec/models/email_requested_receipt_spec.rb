require 'rails_helper'

RSpec.describe EmailRequestedReceipt, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:email_requested_receipt)).to be_valid
  end

  describe 'petition' do
    it { is_expected.to belong_to(:petition).touch(true) }
  end

  context "validations" do
    subject { FactoryGirl.create(:email_requested_receipt) }

    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_uniqueness_of(:petition_id) }
  end
end
