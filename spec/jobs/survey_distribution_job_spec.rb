require 'rails_helper'

RSpec.describe SurveyDistributionJob, type: :job do
  let!(:petitioner_1)   { FactoryBot.create(:signature, constituency_id: constituency_1.external_id, email: "constituency1_petition1_resident1@example.com") }
  let!(:petition_1)     { FactoryBot.create(:petition, creator: petitioner_1) }

  let!(:petitioner_2)   { FactoryBot.create(:signature, constituency_id: constituency_1.external_id, email: "constituency1_petition2_resident1@example.com") }
  let!(:petition_2)     { FactoryBot.create(:petition, creator: petitioner_2) }

  let!(:constituency_1) { FactoryBot.create(:constituency) }
  let!(:constituency_2) { FactoryBot.create(:constituency) }

  let!(:petitioner_3)   { FactoryBot.create(:pending_signature, petition: petition_1, constituency_id: constituency_1.external_id, email: "constituency1_petition1_resident2@example.com") }
  let!(:petitioner_4)   { FactoryBot.create(:pending_signature, petition: petition_1, constituency_id: constituency_2.external_id, email: "constituency2_petition1_resident1@example.com") }
  let!(:petitioner_5)   { FactoryBot.create(:pending_signature, petition: petition_1, constituency_id: constituency_2.external_id, email: "constituency2_petition1_resident2@example.com") }
  let!(:petitioner_6)   { FactoryBot.create(:pending_signature, petition: petition_1, constituency_id: constituency_2.external_id, email: "constituency2_petition1_resident3@example.com") }

  let!(:petitioner_7)   { FactoryBot.create(:pending_signature, petition: petition_2, constituency_id: constituency_1.external_id, email: "constituency1_petition2_resident2@example.com") }
  let!(:petitioner_8)   { FactoryBot.create(:pending_signature, petition: petition_2, constituency_id: constituency_2.external_id, email: "constituency2_petition2_resident1@example.com") }
  let!(:petitioner_9)   { FactoryBot.create(:pending_signature, petition: petition_2, constituency_id: constituency_2.external_id, email: "constituency2_petition2_resident2@example.com") }
  let!(:petitioner_10)  { FactoryBot.create(:pending_signature, petition: petition_2, constituency_id: constituency_2.external_id, email: "constituency2_petition2_resident3@example.com") }

  describe '#perform' do
    before do
      perform_enqueued_jobs do
        described_class.perform_now(survey.id)
      end
    end

    context 'when the survey is for one petition' do
      context 'for a small percentage of petitioners' do
        let(:survey) { FactoryBot.create(:survey, constituency: nil, petitions: [petition_1], percentage_petitioners: 20) }

        it 'emails that percentage only' do
          expect(ActionMailer::Base.deliveries.length).to eq 1

          expect_all_email_recipient_addresses_to_contain_text "petition1"
        end
      end

      context 'for 100% of petitioners' do
        let(:survey) { FactoryBot.create(:survey, constituency: nil, petitions: [petition_1], percentage_petitioners: 100) }

        it 'emails that percentage only' do
          expect(ActionMailer::Base.deliveries.length).to eq 5

          expect_all_email_recipient_addresses_to_contain_text "petition1"
        end
      end

      context 'for a small percentage of a constituency' do
        let(:survey) { FactoryBot.create(:survey, constituency_id: constituency_2.external_id, petitions: [petition_1], percentage_petitioners: 30) }

        it 'emails that percentage for that constituency only' do
          expect(ActionMailer::Base.deliveries.length).to eq 1

          expect_all_email_recipient_addresses_to_contain_text "constituency2"
        end
      end

      context 'for 100% of petitioners for a constituency' do
        let(:survey) { FactoryBot.create(:survey, constituency_id: constituency_2.external_id, petitions: [petition_1], percentage_petitioners: 100) }

        it 'emails that percentage for that constituency only' do
          expect(ActionMailer::Base.deliveries.length).to eq 3

          expect_all_email_recipient_addresses_to_contain_text "constituency2"
        end
      end
    end

    context 'when the survey is for multiple petitions' do
      context 'for a small percentage of petitioners' do
        let(:survey) { FactoryBot.create(:survey, petitions: [petition_1, petition_2], percentage_petitioners: 40) }

        it 'emails that percentage' do
          expect(ActionMailer::Base.deliveries.length).to eq 4
        end
      end

      context 'for 100% of petitioners' do
        let(:survey) { FactoryBot.create(:survey, petitions: [petition_1, petition_2], percentage_petitioners: 100) }

        it 'emails that percentage' do
          expect(ActionMailer::Base.deliveries.length).to eq 10
        end
      end

      context 'for a small percentage of a constituency' do
        let(:survey) { FactoryBot.create(:survey, constituency_id: constituency_2.external_id, petitions: [petition_1, petition_2], percentage_petitioners: 28) }

        it 'emails that percentage' do
          expect(ActionMailer::Base.deliveries.length).to eq 2

          expect_all_email_recipient_addresses_to_contain_text "constituency2"
        end
      end

      context 'for 100% of petitioners for a constituency' do
        let(:survey) { FactoryBot.create(:survey, constituency_id: constituency_2.external_id, petitions: [petition_1, petition_2], percentage_petitioners: 100) }

        it 'emails that percentage' do
          expect(ActionMailer::Base.deliveries.length).to eq 6

          expect_all_email_recipient_addresses_to_contain_text "constituency2"
        end
      end
    end
  end

  def expect_all_email_recipient_addresses_to_contain_text(text)
    ActionMailer::Base.deliveries.each do |mail|
      expect(mail.to.first).to include text
    end
  end
end
