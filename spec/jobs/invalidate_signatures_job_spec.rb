require 'rails_helper'

RSpec.describe InvalidateSignaturesJob, type: :job do
  let(:invalidation) { FactoryGirl.create(:invalidation, ip_address: "10.0.1.1") }
  let(:exception_class) { ActiveJob::DeserializationError }

  context "when the invalidation is present" do
    let!(:petition) { FactoryGirl.create(:open_petition) }
    let!(:signature_1) { FactoryGirl.create(:validated_signature, ip_address: "10.0.1.1", petition: petition) }
    let!(:signature_2) { FactoryGirl.create(:validated_signature, ip_address: "192.168.1.1", petition: petition) }

    it "performs the invalidation process" do
      expect(Invalidation).to receive(:find).with(invalidation.id.to_s).and_return(invalidation)
      expect(invalidation).to receive(:invalidate!).and_call_original
      expect(petition.signature_count).to eq(3)

      perform_enqueued_jobs {
        described_class.perform_later(invalidation)
      }

      expect(invalidation.matching_count).to eq(1)
      expect(invalidation.invalidated_count).to eq(1)
      expect(petition.reload.signature_count).to eq(2)
    end
  end

  context "when the invalidation has been deleted" do
    before do
      Invalidation.delete(invalidation)
    end

    it "notifies Appsignal of the error" do
      expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))

      perform_enqueued_jobs {
        described_class.perform_later(invalidation)
      }
    end

    it "doesn't raise an error" do
      expect {
        perform_enqueued_jobs {
          described_class.perform_later(invalidation)
        }
      }.not_to raise_error
    end
  end
end
