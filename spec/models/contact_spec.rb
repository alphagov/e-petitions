require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe "associations" do
    it { should belong_to(:signature) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:signature) }
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:phone_number) }
    it { is_expected.to validate_length_of(:address).is_at_most(500) }
    it { is_expected.not_to allow_value(?6 * 32).for(:phone_number).with_message(:too_long) }
  end

  describe "instance methods" do
    describe "#phone_number=" do
      it "normalizes input" do
        expect {
          subject.phone_number = "0300 200 6565"
        }.to change {
          subject.phone_number
        }.from(nil).to("03002006565")
      end
    end
  end
end
