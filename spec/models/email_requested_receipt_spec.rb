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

  describe '#get' do
    let(:receipt) { FactoryGirl.build(:email_requested_receipt) }
    let(:the_stored_time) { 6.days.ago }

    it 'returns nil when nothing has been stamped for the supplied name' do
      expect(receipt.get('government_response')).to be_nil
    end

    it 'returns the stored timestamp for the supplied name' do
      receipt.government_response = the_stored_time
      expect(receipt.get('government_response')).to eq the_stored_time
    end

    it 'raises an error if the supplied name is not a valid timestamp' do
      expect {
        receipt.get('aint_no_such_timestamp')
      }.to raise_error(ArgumentError)
    end

    it 'raises an error if we try to access the rails created_at/updated_at stamps this way' do
      expect {
        receipt.get('created_at')
      }.to raise_error(ArgumentError)
      expect {
        receipt.get('updated_at')
      }.to raise_error(ArgumentError)
    end
  end

  describe '#set' do
    let(:receipt) { FactoryGirl.create(:email_requested_receipt) }
    let(:the_stored_time) { 6.days.ago }

    it 'saves the stored timestamp for the supplied name in the db to the supplied time' do
      receipt.set('government_response', the_stored_time)
      receipt.reload
      expect(receipt.government_response).to eq the_stored_time
    end

    it 'raises an error if the supplied name is not a valid timestamp' do
      expect {
        receipt.set('aint_no_such_timestamp', the_stored_time)
      }.to raise_error(ArgumentError)
    end

    it 'raises an error if we try to set the rails created_at/updated_at stamps this way' do
      expect {
        receipt.set('created_at', the_stored_time)
      }.to raise_error(ArgumentError)
      expect {
        receipt.set('updated_at', the_stored_time)
      }.to raise_error(ArgumentError)
    end
  end
end
