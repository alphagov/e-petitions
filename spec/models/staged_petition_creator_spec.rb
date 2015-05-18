require 'rails_helper'

describe StagedPetitionCreator do
  let(:petition_params) { {} }
  let(:move) { '' }
  let(:stage) { '' }
  let(:request) { double(remote_ip: '192.168.0.1') }
  subject { described_class.new(petition_params, request, stage, move) }
  let(:petition) { subject.petition }

  describe '#create_petition' do
    it 'strips trailing whitespace from the petition title' do
      petition_params[:title] = ' woo '
      subject.create_petition
      expect(petition.title).to eq 'woo'
    end

    context 'when creator_signature attributes are present' do
      it 'strips trailing whitespace from the creator signature email' do
        petition_params[:creator_signature_attributes] = { email: ' woo@example.com ' }
        subject.create_petition
        expect(petition.creator_signature.email).to eq 'woo@example.com'
      end

      it 'assigns the remote_ip of the request to the ip_address of the creator signature' do
        petition_params[:creator_signature_attributes] = { email: ' woo@example.com ' }
        subject.create_petition
        expect(petition.creator_signature.ip_address).to eq '192.168.0.1'
      end

      it 'assumes that the creator wants notify_by_email to be true' do
        petition_params[:creator_signature_attributes] = { email: ' woo@example.com ' }
        subject.create_petition
        expect(petition.creator_signature.notify_by_email).to eq true
      end
    end

    context 'when creator_signature attributes are not present' do
      it 'does not cause a creator_signature to appear' do
        subject.create_petition
        expect(petition.creator_signature).to be_nil
      end
    end

    describe 'when the stage is "done"' do
      let(:stage) { 'done' }

      it 'tries to save the petition object' do
        expect(petition).to receive(:save)
        subject.create_petition
      end

      it 'returns true if the petition object can be saved' do
        allow(petition).to receive(:save).and_return true
        expect(subject.create_petition).to eq true
      end

      it 'returns true if the petition object can not be saved' do
        allow(petition).to receive(:save).and_return false
        expect(subject.create_petition).to eq false
      end
    end

    describe 'when the stage is not "done"' do
      let(:stage) { 'replay-petition' }

      it 'returns false' do
        expect(subject.create_petition).to eq false
      end

      it 'does not try to save the petition' do
        expect(subject.petition).not_to receive(:save)
        subject.create_petition
      end
    end
  end

  describe 'stages' do
    def self.for_stage(name, next_is:, back_is:, not_moving_is:)
      context "and the previous_stage was \"#{name}\"" do
        let(:stage) { name }
        context 'and we are moving forwards' do
          let(:move) { 'next' }
          it "is \"#{next_is}\"" do
            expect(subject.stage).to eq next_is
          end
        end
        context 'and we are moving backwards' do
          let(:move) { 'back' }
          it "is \"#{back_is}\"" do
            expect(subject.stage).to eq back_is
          end
        end
        context 'and we are not moving' do
          let(:move) { nil }
          it "is \"#{not_moving_is}\"" do
            expect(subject.stage).to eq not_moving_is
          end
        end
      end
    end

    let(:department) { FactoryGirl.create(:department) }
    let(:sponsor_emails) { (1..AppConfig.sponsor_count_min).map { |i| "sponsor#{i}@example.com" } }
    let(:creator_signature_params) do
      {
        :name => 'John Mcenroe', :email => 'john@example.com',
        :postcode => 'SE3 4LL', :country => 'United Kingdom',
        :uk_citizenship => '1'
      }
    end
    let(:petition_params) do
      {
        :title => 'Save the planet',
        :action => 'Limit temperature rise at two degrees',
        :description => 'Global warming is upon us',
        :sponsor_emails => sponsor_emails,
        :creator_signature_attributes => creator_signature_params
      }
    end

    describe '#stage' do
      context 'when there are no errors on the petition' do
        context 'before attempting to create the petition' do
          for_stage 'petition', next_is: 'creator', back_is: 'petition', not_moving_is: 'petition'
          for_stage 'creator', next_is: 'sponsors', back_is: 'petition', not_moving_is: 'creator'
          for_stage 'sponsors', next_is: 'replay-petition', back_is: 'creator', not_moving_is: 'sponsors'
          for_stage 'replay-petition', next_is: 'replay-email', back_is: 'sponsors', not_moving_is: 'replay-petition'
          for_stage 'replay-email', next_is: 'done', back_is: 'replay-petition', not_moving_is: 'replay-email'
          for_stage 'done', next_is: 'done', back_is: 'done', not_moving_is: 'done'
        end

        context 'after attempting to create the petition' do
          before { subject.create_petition }

          for_stage 'petition', next_is: 'creator', back_is: 'petition', not_moving_is: 'petition'
          for_stage 'creator', next_is: 'sponsors', back_is: 'petition', not_moving_is: 'creator'
          for_stage 'sponsors', next_is: 'replay-petition', back_is: 'creator', not_moving_is: 'sponsors'
          for_stage 'replay-petition', next_is: 'replay-email', back_is: 'sponsors', not_moving_is: 'replay-petition'
          for_stage 'replay-email', next_is: 'done', back_is: 'replay-petition', not_moving_is: 'replay-email'
          for_stage 'done', next_is: 'done', back_is: 'done', not_moving_is: 'done'
        end
      end

      context 'when there are errors on the petition' do
        context 'around the "petition" UI' do
          before { petition_params.delete(:title) }

          context 'before attempting to create the petition' do
            for_stage 'petition', next_is: 'petition', back_is: 'petition', not_moving_is: 'petition'
            for_stage 'creator', next_is: 'sponsors', back_is: 'petition', not_moving_is: 'creator'
            for_stage 'sponsors', next_is: 'replay-petition', back_is: 'creator', not_moving_is: 'sponsors'
            for_stage 'replay-petition', next_is: 'replay-email', back_is: 'sponsors', not_moving_is: 'replay-petition'
            for_stage 'replay-email', next_is: 'done', back_is: 'replay-petition', not_moving_is: 'replay-email'
            for_stage 'done', next_is: 'done', back_is: 'done', not_moving_is: 'done'
          end

          context 'after attempting to create the petition' do
            before { subject.create_petition }

            for_stage 'petition', next_is: 'petition', back_is: 'petition', not_moving_is: 'petition'
            for_stage 'creator', next_is: 'sponsors', back_is: 'petition', not_moving_is: 'creator'
            for_stage 'sponsors', next_is: 'replay-petition', back_is: 'creator', not_moving_is: 'sponsors'
            for_stage 'replay-petition', next_is: 'replay-email', back_is: 'sponsors', not_moving_is: 'replay-petition'
            for_stage 'replay-email', next_is: 'petition', back_is: 'replay-petition', not_moving_is: 'replay-email'
            for_stage 'done', next_is: 'petition', back_is: 'petition', not_moving_is: 'petition'
          end
        end

        context 'around the "creator" UI' do
          before { creator_signature_params.delete(:postcode) }

          context 'before attempting to create the petition' do
            for_stage 'petition', next_is: 'creator', back_is: 'petition', not_moving_is: 'petition'
            for_stage 'creator', next_is: 'creator', back_is: 'petition', not_moving_is: 'creator'
            for_stage 'sponsors', next_is: 'replay-petition', back_is: 'creator', not_moving_is: 'sponsors'
            for_stage 'replay-petition', next_is: 'replay-email', back_is: 'sponsors', not_moving_is: 'replay-petition'
            for_stage 'replay-email', next_is: 'done', back_is: 'replay-petition', not_moving_is: 'replay-email'
            for_stage 'done', next_is: 'done', back_is: 'done', not_moving_is: 'done'
          end

          context 'after attempting to create the petition' do
            before { subject.create_petition }

            for_stage 'petition', next_is: 'creator', back_is: 'petition', not_moving_is: 'petition'
            for_stage 'creator', next_is: 'creator', back_is: 'petition', not_moving_is: 'creator'
            for_stage 'sponsors', next_is: 'replay-petition', back_is: 'creator', not_moving_is: 'sponsors'
            for_stage 'replay-petition', next_is: 'replay-email', back_is: 'sponsors', not_moving_is: 'replay-petition'
            for_stage 'replay-email', next_is: 'creator', back_is: 'replay-petition', not_moving_is: 'replay-email'
            for_stage 'done', next_is: 'creator', back_is: 'creator', not_moving_is: 'creator'
          end
        end

        context 'around the "sponsors" UI' do
          before { petition_params[:sponsor_emails] = ['dave@'] }

          context 'before attempting to create the petition' do
            for_stage 'petition', next_is: 'creator', back_is: 'petition', not_moving_is: 'petition'
            for_stage 'creator', next_is: 'sponsors', back_is: 'petition', not_moving_is: 'creator'
            for_stage 'sponsors', next_is: 'sponsors', back_is: 'creator', not_moving_is: 'sponsors'
            for_stage 'replay-petition', next_is: 'replay-email', back_is: 'sponsors', not_moving_is: 'replay-petition'
            for_stage 'replay-email', next_is: 'done', back_is: 'replay-petition', not_moving_is: 'replay-email'
            for_stage 'done', next_is: 'done', back_is: 'done', not_moving_is: 'done'
          end

          context 'after attempting to create the petition' do
            before { subject.create_petition }
            for_stage 'petition', next_is: 'creator', back_is: 'petition', not_moving_is: 'petition'
            for_stage 'creator', next_is: 'sponsors', back_is: 'petition', not_moving_is: 'creator'
            for_stage 'sponsors', next_is: 'sponsors', back_is: 'creator', not_moving_is: 'sponsors'
            for_stage 'replay-petition', next_is: 'replay-email', back_is: 'sponsors', not_moving_is: 'replay-petition'
            for_stage 'replay-email', next_is: 'sponsors', back_is: 'replay-petition', not_moving_is: 'replay-email'
            for_stage 'done', next_is: 'sponsors', back_is: 'sponsors', not_moving_is: 'sponsors'
          end
        end

        context 'around the "replay email" UI' do
          before { creator_signature_params.delete(:email) }

          # NOTE: the creator stage also checks for errors on email, so
          # we need to be aware that errors on the "replay email" UI will
          # also trigger the creator stage.

          context 'before attempting to create the petition' do
            for_stage 'petition', next_is: 'creator', back_is: 'petition', not_moving_is: 'petition'
            for_stage 'creator', next_is: 'creator', back_is: 'petition', not_moving_is: 'creator'
            for_stage 'sponsors', next_is: 'replay-petition', back_is: 'creator', not_moving_is: 'sponsors'
            for_stage 'replay-petition', next_is: 'replay-email', back_is: 'sponsors', not_moving_is: 'replay-petition'
            for_stage 'replay-email', next_is: 'replay-email', back_is: 'replay-petition', not_moving_is: 'replay-email'
            for_stage 'done', next_is: 'done', back_is: 'done', not_moving_is: 'done'
          end

          context 'after attempting to create the petition' do
            before { subject.create_petition }
            for_stage 'petition', next_is: 'creator', back_is: 'petition', not_moving_is: 'petition'
            for_stage 'creator', next_is: 'creator', back_is: 'petition', not_moving_is: 'creator'
            for_stage 'sponsors', next_is: 'replay-petition', back_is: 'creator', not_moving_is: 'sponsors'
            for_stage 'replay-petition', next_is: 'replay-email', back_is: 'sponsors', not_moving_is: 'replay-petition'
            for_stage 'replay-email', next_is: 'replay-email', back_is: 'replay-petition', not_moving_is: 'replay-email'
            # NOTE: ideally this would be 'replay-email', but we can't
            # tell the difference between a 'creator' failure and a
            # 'replay-email' failure if we started from 'done'.
            # TODO: make it so we can?
            for_stage 'done', next_is: 'creator', back_is: 'creator', not_moving_is: 'creator'
          end
        end
      end
    end
  end
end
