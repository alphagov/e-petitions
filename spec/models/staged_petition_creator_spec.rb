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

  describe '#create' do
    it 'strips trailing whitespace from the petition title' do
      params[:petition] = { title: ' woo ' }
      subject.create
      expect(subject.title).to eq 'woo'
    end

    context 'when creator_signature attributes are present' do
      it 'strips trailing whitespace from the creator signature email' do
        params[:petition] = { creator_signature: { email: ' woo@example.com ' } }
        subject.create
        expect(subject.creator_signature.email).to eq 'woo@example.com'
      end

      it 'assigns the remote_ip of the request to the ip_address of the creator signature' do
        params[:petition] = { creator_signature: { email: ' woo@example.com ' } }
        subject.create
        expect(subject.creator_signature.ip_address).to eq '192.168.0.1'
      end

      it 'assumes that the creator wants notify_by_email to be true' do
        params[:petition] = { creator_signature: { email: ' woo@example.com ' } }
        subject.create
        expect(subject.creator_signature.notify_by_email).to eq true
      end
    end

    context 'when creator_signature attributes are present' do
      it 'does not cause a creator_signature to appear' do
        subject.create
        expect(subject.creator_signature).to be_nil
      end
    end

    describe 'when the stage is "done"' do
      before { allow(subject).to receive(:stage).and_return 'done' }

      it 'returns the result of trying to save the petition object' do
        expect(subject.petition).to receive(:save)
        subject.create
      end

      it 'returns the result of trying to save the petition object' do
        allow(subject.petition).to receive(:save).and_return :a_save_result
        expect(subject.create).to eq :a_save_result
      end
    end

    describe 'when the stage is not "done"' do
      before { allow(subject).to receive(:stage).and_return 'not-done' }

      it 'returns false' do
        expect(subject.create).to eq false
      end

      it 'does not try to save the petition' do
        expect(subject.petition).not_to receive(:save)
        subject.create
      end

      it 'validates the petition' do
        expect(subject.petition).to receive(:valid?)
        subject.create
      end
    end
  end
  end
end
