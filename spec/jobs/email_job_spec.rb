require 'rails_helper'

RSpec.describe EmailJob, type: :job do
  let(:job) { described_class.new(petition) }
  let(:mailer) { double(:mailer) }
  let(:message) { double(:message, deliver_now: true) }
  let(:petition) { FactoryGirl.create(:petition) }

  before do
    job.mailer = mailer
    job.email  = :email
  end

  it "calls the email method on the mailer" do
    expect(mailer).to receive(:email).with(petition).and_return(message)
    job.perform_now
  end

  context "email sending fails" do
    shared_examples_for "catching errors during individual email sending" do
      let(:logger) { job.logger }

      it "captures the error and doesn't re-raise it" do
        job.perform_now
      end

      it "logs the email sending error as information" do
        expect(logger).to receive(:info).with(/#{Regexp.escape(exception_class.name)}/)
        job.perform_now
      end
    end

    shared_examples_for "retrying the email delivery" do
      it "retries the job" do
        expect(job).to receive(:retry_job)
        job.perform_now
      end
    end

    shared_examples_for "not retrying the email delivery" do
      it "doesn't retry the job" do
        expect(job).not_to receive(:retry_job)
        job.perform_now
      end
    end

    before do
      expect(mailer).to receive(:email).and_raise(exception_class)
    end

    context "with a fatal SMTP error" do
      let(:exception_class) { Net::SMTPFatalError }

      it_behaves_like "catching errors during individual email sending"
      it_behaves_like "not retrying the email delivery"
    end

    context "with a SMTP syntax error" do
      let(:exception_class) { Net::SMTPSyntaxError }

      it_behaves_like "catching errors during individual email sending"
      it_behaves_like "not retrying the email delivery"
    end

    context "with SMTP authentication error" do
      let(:exception_class) { Net::SMTPAuthenticationError }

      it_behaves_like "catching errors during individual email sending"
      it_behaves_like "retrying the email delivery"
    end

    context "with SMTP connection timeout" do
      let(:exception_class) { Net::OpenTimeout }

      it_behaves_like "catching errors during individual email sending"
      it_behaves_like "retrying the email delivery"
    end

    context "with SMTP server busy" do
      let(:exception_class) { Net::SMTPServerBusy }

      it_behaves_like "catching errors during individual email sending"
      it_behaves_like "retrying the email delivery"
    end

    context "with connection reset" do
      let(:exception_class) { Errno::ECONNRESET }

      it_behaves_like "catching errors during individual email sending"
      it_behaves_like "retrying the email delivery"
    end

    context "with connection refused" do
      let(:exception_class) { Errno::ECONNREFUSED }

      it_behaves_like "catching errors during individual email sending"
      it_behaves_like "retrying the email delivery"
    end

    context "with connection timeout" do
      let(:exception_class) { Errno::ETIMEDOUT }

      it_behaves_like "catching errors during individual email sending"
      it_behaves_like "retrying the email delivery"
    end

    context "with timeout error" do
      let(:exception_class) { Timeout::Error }

      it_behaves_like "catching errors during individual email sending"
      it_behaves_like "retrying the email delivery"
    end

    context "with socket error" do
      let(:exception_class) { SocketError }

      it_behaves_like "catching errors during individual email sending"
      it_behaves_like "retrying the email delivery"
    end
  end
end

RSpec.describe EmailConfirmationForSignerEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:open_petition) }
  let(:signature) { FactoryGirl.create(:pending_signature, petition: petition) }
  let(:run_jobs_and_reload_signature) do
    perform_enqueued_jobs do
      described_class.perform_later(signature)
    end

    signature.reload
  end

  it "sends the PetitionMailer#email_confirmation_for_signer email" do
    expect(PetitionMailer).to receive(:email_confirmation_for_signer).with(signature).and_call_original

    run_jobs_and_reload_signature
  end

  it "increments the signature email_count" do
    expect{ run_jobs_and_reload_signature }.to change{ signature.email_count }.from(0).to(1)
  end
end

RSpec.describe EmailDuplicateSignaturesEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:open_petition) }
  let(:original_signature) { petition.signatures.first }
  let(:duplicated_signature) { original_signature.clone }
  let(:run_jobs_and_reload_signatures) do
    perform_enqueued_jobs do
      described_class.perform_later(duplicated_signature)
    end

    duplicated_signature.reload
    original_signature.reload
  end

  it "sends the PetitionMailer#email_duplicate_signatures email" do
    expect(PetitionMailer).to receive(:email_duplicate_signatures).with(duplicated_signature).and_call_original

    run_jobs_and_reload_signatures
  end

  it "increments the signature email_count" do
    expect{ run_jobs_and_reload_signatures }.to change{ original_signature.email_count }.from(0).to(1)
  end
end

RSpec.describe GatherSponsorsForPetitionEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:petition) }

  it "sends the PetitionMailer#gather_sponsors_for_petition email" do
    expect(PetitionMailer).to receive(:gather_sponsors_for_petition).with(petition).and_call_original

    perform_enqueued_jobs do
      described_class.perform_later(petition)
    end
  end
end

RSpec.describe NotifyCreatorThatParliamentIsDissolvingJob, type: :job do
  let(:petition) { FactoryGirl.create(:petition) }
  let(:signature) { FactoryGirl.create(:signature, petition: petition) }

  context "when parliament is not dissolving" do
    before do
      allow(Parliament).to receive(:dissolution_announced?).and_return(false)
    end

    it "does not send the PetitionMailer#notify_creator_that_petition_is_published email" do
      expect(PetitionMailer).not_to receive(:notify_creator_of_closing_date_change).with(signature).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(signature)
      end
    end
  end

  context "when parliament is dissolving" do
    before do
      allow(Parliament).to receive(:dissolution_announced?).and_return(true)
      allow(Parliament).to receive(:dissolution_at).and_return(2.weeks.from_now)
    end

    it "sends the PetitionMailer#notify_creator_that_petition_is_published email" do
      expect(PetitionMailer).to receive(:notify_creator_of_closing_date_change).with(signature).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(signature)
      end
    end
  end
end

RSpec.describe NotifyCreatorOfValidatedPetitionBeingStoppedJob, type: :job do
  let(:petition) { FactoryGirl.create(:validated_petition) }
  let(:signature) { FactoryGirl.create(:signature, petition: petition) }

  context "when parliament is not dissolved" do
    before do
      allow(Parliament).to receive(:dissolved?).and_return(false)
    end

    it "does not send the PetitionMailer#notify_creator_of_validated_petition_being_stopped email" do
      expect(PetitionMailer).not_to receive(:notify_creator_of_validated_petition_being_stopped).with(signature).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(signature)
      end
    end
  end

  context "when parliament is dissolved" do
    before do
      allow(Parliament).to receive(:dissolved?).and_return(true)
    end

    it "sends the PetitionMailer#notify_creator_of_validated_petition_being_stopped email" do
      expect(PetitionMailer).to receive(:notify_creator_of_validated_petition_being_stopped).with(signature).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(signature)
      end
    end
  end
end

RSpec.describe NotifyCreatorOfSponsoredPetitionBeingStoppedJob, type: :job do
  let(:petition) { FactoryGirl.create(:sponsored_petition) }
  let(:signature) { FactoryGirl.create(:signature, petition: petition) }

  context "when parliament is not dissolved" do
    before do
      allow(Parliament).to receive(:dissolved?).and_return(false)
    end

    it "does not send the PetitionMailer#notify_creator_of_sponsored_petition_being_stopped email" do
      expect(PetitionMailer).not_to receive(:notify_creator_of_sponsored_petition_being_stopped).with(signature).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(signature)
      end
    end
  end

  context "when parliament is dissolved" do
    before do
      allow(Parliament).to receive(:dissolved?).and_return(true)
    end

    it "sends the PetitionMailer#notify_creator_of_sponsored_petition_being_stopped email" do
      expect(PetitionMailer).to receive(:notify_creator_of_sponsored_petition_being_stopped).with(signature).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(signature)
      end
    end
  end
end

RSpec.describe NotifyCreatorThatPetitionIsPublishedEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:petition) }
  let(:signature) { FactoryGirl.create(:signature, petition: petition) }

  it "sends the PetitionMailer#notify_creator_that_petition_is_published email" do
    expect(PetitionMailer).to receive(:notify_creator_that_petition_is_published).with(signature).and_call_original

    perform_enqueued_jobs do
      described_class.perform_later(signature)
    end
  end
end

RSpec.describe NotifySponsorThatPetitionIsPublishedEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:petition) }
  let(:signature) { FactoryGirl.create(:signature, petition: petition) }

  it "sends the PetitionMailer#notify_sponsor_that_petition_is_published email" do
    expect(PetitionMailer).to receive(:notify_sponsor_that_petition_is_published).with(signature).and_call_original

    perform_enqueued_jobs do
      described_class.perform_later(signature)
    end
  end
end

RSpec.describe NotifyCreatorThatPetitionWasRejectedEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:rejected_petition) }
  let(:signature) { FactoryGirl.create(:signature, petition: petition) }

  it "sends the PetitionMailer#notify_creator_that_petition_was_rejected email" do
    expect(PetitionMailer).to receive(:notify_creator_that_petition_was_rejected).with(signature).and_call_original

    perform_enqueued_jobs do
      described_class.perform_later(signature)
    end
  end
end

RSpec.describe NotifySponsorThatPetitionWasRejectedEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:rejected_petition) }
  let(:signature) { FactoryGirl.create(:validated_signature, petition: petition) }

  it "sends the PetitionMailer#notify_sponsor_that_petition_was_rejected email" do
    expect(PetitionMailer).to receive(:notify_sponsor_that_petition_was_rejected).with(signature).and_call_original

    perform_enqueued_jobs do
      described_class.perform_later(signature)
    end
  end
end

RSpec.describe PetitionAndEmailConfirmationForSponsorEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:petition) }
  let(:sponsor) { FactoryGirl.create(:sponsor, :pending, petition: petition) }

  it "sends the SponsorMailer#petition_and_email_confirmation_for_sponsor email" do
    expect(SponsorMailer).to receive(:petition_and_email_confirmation_for_sponsor).with(sponsor).and_call_original

    perform_enqueued_jobs do
      described_class.perform_later(sponsor)
    end
  end
end

RSpec.describe SponsorSignedEmailBelowThresholdEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:petition) }
  let(:sponsor) { FactoryGirl.create(:sponsor, :validated, petition: petition) }

  it "sends the SponsorMailer#sponsor_signed_email_below_threshold email" do
    expect(SponsorMailer).to receive(:sponsor_signed_email_below_threshold).with(petition, sponsor).and_call_original

    perform_enqueued_jobs do
      described_class.perform_later(petition, sponsor)
    end
  end
end

RSpec.describe SponsorSignedEmailOnThresholdEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:petition) }
  let(:sponsor) { FactoryGirl.create(:sponsor, :validated, petition: petition) }

  it "sends the SponsorMailer#sponsor_signed_email_on_threshold email" do
    expect(SponsorMailer).to receive(:sponsor_signed_email_on_threshold).with(petition, sponsor).and_call_original

    perform_enqueued_jobs do
      described_class.perform_later(petition, sponsor)
    end
  end
end

RSpec.describe FeedbackEmailJob, type: :job do
  let(:feedback) { FactoryGirl.create(:feedback) }

  it "sends the FeedbackMailer#send_feedback email" do
    expect(FeedbackMailer).to receive(:send_feedback).with(feedback).and_call_original

    perform_enqueued_jobs do
      described_class.perform_later(feedback)
    end
  end
end

