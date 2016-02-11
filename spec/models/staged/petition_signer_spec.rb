require 'rails_helper'

RSpec.describe Staged::PetitionSigner, type: :model do
  let(:signature_params) { {} }
  let(:request) { double(remote_ip: '192.168.0.1') }
  let(:move) { '' }
  let(:stage) { '' }
  let(:petition) { FactoryGirl.create(:open_petition) }
  subject { described_class.manage(signature_params, request, petition, stage, move) }
  let(:signature) { subject.signature }

  describe '#create_signature' do
    it 'strips trailing whitespace from the email' do
      signature_params[:email] = ' woo@example.com '
      subject.create_signature
      expect(signature.email).to eq 'woo@example.com'
    end

    describe 'when the stage is "done"' do
      let(:stage) { 'done' }

      it 'tries to save the signature object' do
        expect(signature).to receive(:save)
        subject.create_signature
      end

      it 'returns true if the signature object can be saved' do
        allow(signature).to receive(:save).and_return true
        expect(subject.create_signature).to eq true
      end

      it 'returns false if the signature object can not be saved' do
        allow(signature).to receive(:save).and_return false
        expect(subject.create_signature).to eq false
      end

      it 'assigns the remote_ip of the request to the ip_address of the signature' do
        allow(signature).to receive(:save).and_return true
        expect(subject.create_signature).to eq true
        expect(signature.ip_address).to eq '192.168.0.1'
      end
    end

    describe 'when the stage is not "done"' do
      let(:stage) { 'replay-email' }

      it 'returns false' do
        expect(subject.create_signature).to eq false
      end

      it 'does not try to save the signature' do
        expect(subject.signature).not_to receive(:save)
        subject.create_signature
      end
    end
  end

  describe 'stages' do
    let(:signature_params) do
      {
        :name => 'John Mcenroe', :email => 'john@example.com',
        :postcode => 'SE3 4LL', :location_code => 'GB',
        :uk_citizenship => '1'
      }
    end

    describe '#stage' do
      extend StagedObjectHelpers

      context 'when there are no errors on the signature' do
        context 'before attempting to create the signature' do
          for_stage 'signer', next_is: 'replay-email', back_is: 'signer', not_moving_is: 'signer'
          for_stage 'replay-email', next_is: 'done', back_is: 'signer', not_moving_is: 'replay-email'
          for_stage 'done', next_is: 'done', back_is: 'done', not_moving_is: 'done'
        end

        context 'after attempting to create the signature' do
          before { subject.create_signature }

          for_stage 'signer', next_is: 'replay-email', back_is: 'signer', not_moving_is: 'signer'
          for_stage 'replay-email', next_is: 'done', back_is: 'signer', not_moving_is: 'replay-email'
          for_stage 'done', next_is: 'done', back_is: 'done', not_moving_is: 'done'
        end
      end

      context 'when there are errors on the signature' do
        context 'around the "signer" UI' do
          before { signature_params.delete(:name) }

          context 'before attempting to create the petition' do
            for_stage 'signer', next_is: 'signer', back_is: 'signer', not_moving_is: 'signer'
            for_stage 'replay-email', next_is: 'done', back_is: 'signer', not_moving_is: 'replay-email'
            for_stage 'done', next_is: 'done', back_is: 'done', not_moving_is: 'done'
          end

          context 'after attempting to create the signature' do
            before { subject.create_signature }

            for_stage 'signer', next_is: 'signer', back_is: 'signer', not_moving_is: 'signer'
            for_stage 'replay-email', next_is: 'signer', back_is: 'signer', not_moving_is: 'replay-email'
            for_stage 'done', next_is: 'signer', back_is: 'signer', not_moving_is: 'signer'
          end
        end

        context 'around the "replay email" UI' do
          before { signature_params.delete(:email) }

          # NOTE: the signer stage also checks for errors on email, so
          # we need to be aware that errors on the "replay email" UI will
          # also trigger the signer stage.

          context 'before attempting to create the petition' do
            for_stage 'signer', next_is: 'signer', back_is: 'signer', not_moving_is: 'signer'
            for_stage 'replay-email', next_is: 'replay-email', back_is: 'signer', not_moving_is: 'replay-email'
            for_stage 'done', next_is: 'done', back_is: 'done', not_moving_is: 'done'
          end

          context 'after attempting to create the petition' do
            before { subject.create_signature }

            for_stage 'signer', next_is: 'signer', back_is: 'signer', not_moving_is: 'signer'
            for_stage 'replay-email', next_is: 'replay-email', back_is: 'signer', not_moving_is: 'replay-email'
            # NOTE: ideally this would be 'replay-email', but we can't
            # tell the difference between a 'signer' failure and a
            # 'replay-email' failure if we started from 'done'.
            # TODO: make it so we can?
            for_stage 'done', next_is: 'signer', back_is: 'signer', not_moving_is: 'signer'
          end
        end
      end
    end
  end
end
