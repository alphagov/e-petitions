require 'rails_helper'

RSpec.describe AnonymiseSignaturesJob, type: :job do
  shared_examples_for "anonymisation" do
    let(:timestamp) { Date.tomorrow.beginning_of_day }
    let(:now) { "2016-08-11T07:30:00Z".in_time_zone }

    context "created over 12 months ago" do
      let!(:signature) {
        FactoryGirl.create(signature_type, created_at: 13.months.ago(now))
      }

      it "anonymises the signature" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(timestamp.iso8601)
          }
        }.to change {
          signature.reload.anonymised_at
        }.from(nil).to(timestamp)
      end
    end

    context "less than 12 months ago" do
      let!(:signature) {
        FactoryGirl.create(signature_type, created_at: 11.months.ago(now))
      }

      it "doesn't anonymise the signature" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(timestamp.iso8601)
          }
        }.not_to change {
          signature.reload.anonymised_at
        }
      end
    end
  end

  context "with a pending signature" do
    let(:signature_type) { :pending_signature }

    it_behaves_like "anonymisation"
  end

  context "when a validated signature" do
    let(:signature_type) { :validated_signature }

    it_behaves_like "anonymisation"
  end
end
