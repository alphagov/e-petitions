require 'rails_helper'

describe StagedPetitionCreator do
  let(:params) { ActionController::Parameters.new({}) }
  let(:request) { double(remote_ip: '192.168.0.1') }
  subject { described_class.new(params, request) }

  describe '#creator_signature!' do
    it 'builds a new creator signature for the petition' do
      expect(subject.creator_signature).to be_nil
      subject.creator_signature!
      expect(subject.creator_signature).to be_present
    end

    it 'returns the newly built creator signature' do
      newly_built = subject.creator_signature!
      expect(subject.creator_signature).to eq newly_built
    end

    it 'sets the country of the built signature to "United Kingdom"' do
      expect(subject.creator_signature!.country).to eq 'United Kingdom'
    end

    it 'does not create a new instance if the petition already has a creator signature' do
      existing = Signature.new
      subject.petition.creator_signature = existing
      subject.creator_signature!
      expect(subject.creator_signature).to eq existing
    end

    it 'does not change the country if the petition already has a creator signature' do
      existing = Signature.new(country: 'France')
      subject.petition.creator_signature = existing
      subject.creator_signature!
      expect(subject.creator_signature.country).to eq 'France'
    end
  end
end
