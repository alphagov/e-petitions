require "rails_helper"

RSpec.describe PetitionMailer, type: :mailer do
  let :creator do
    FactoryGirl.create(:validated_signature, name: "Barry Butler", email: "bazbutler@gmail.com")
  end

  let :petition do
    FactoryGirl.create(:pending_petition,
      creator_signature: creator,
      action: "Allow organic vegetable vans to use red diesel",
      background: "Add vans to permitted users of red diesel",
      additional_details: "To promote organic vegetables"
    )
  end

  let(:pending_signature) { FactoryGirl.create(:pending_signature, petition: petition) }
  let(:validated_signature) { FactoryGirl.create(:validated_signature, petition: petition) }
  let(:subject_prefix) { "HM Government & Parliament Petitions" }

  describe "notifying creator of publication" do
    let(:mail) { PetitionMailer.notify_creator_that_petition_is_published(creator) }

    before do
      petition.publish
    end

    it "is sent to the right address" do
      expect(mail.to).to eq(%w[bazbutler@gmail.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "has an appropriate subject heading" do
      expect(mail).to have_subject('We published your petition "Allow organic vegetable vans to use red diesel"')
    end

    it "is addressed to the creator" do
      expect(mail).to have_body_text("Dear Barry Butler,")
    end

    it "informs the creator of the publication" do
      expect(mail).to have_body_text("We published the petition you created")
    end
  end

  describe "notifying sponsor of publication" do
    let(:mail) { PetitionMailer.notify_sponsor_that_petition_is_published(sponsor) }
    let(:sponsor) do
      FactoryGirl.create(:validated_signature,
        name: "Laura Palmer",
        email: "laura@red-room.example.com",
        petition: petition
      )
    end

    before do
      petition.publish
    end

    it "is sent to the right address" do
      expect(mail.to).to eq(%w[laura@red-room.example.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "has an appropriate subject heading" do
      expect(mail).to have_subject('We published the petition "Allow organic vegetable vans to use red diesel" that you supported')
    end

    it "is addressed to the sponsor" do
      expect(mail).to have_body_text("Dear Laura Palmer,")
    end

    it "informs the sponsor of the publication" do
      expect(mail).to have_body_text("We published the petition you supported")
    end
  end

  describe "notifying creator of closing date change" do
    let(:mail) { PetitionMailer.notify_creator_of_closing_date_change(creator) }

    before do
      petition.publish
    end

    it "is sent to the right address" do
      expect(mail.to).to eq(%w[bazbutler@gmail.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "has an appropriate subject heading" do
      expect(mail).to have_subject("We’re closing your petition early")
    end

    it "is addressed to the creator" do
      expect(mail).to have_body_text("Dear Barry Butler,")
    end

    it "informs the creator of the change" do
      expect(mail).to have_body_text("Unfortunately we’re closing all petitions")
    end
  end

  describe "gathering sponsors for petition" do
    subject(:mail) { described_class.gather_sponsors_for_petition(petition) }

    it "has the correct subject" do
      expect(mail).to have_subject(%{Action required: Petition "Allow organic vegetable vans to use red diesel"})
    end

    it "has the addresses the creator by name" do
      expect(mail).to have_body_text("Dear Barry Butler,")
    end

    it "sends it only to the petition creator" do
      expect(mail.to).to eq(%w[bazbutler@gmail.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "includes a link to pass on to potential sponsors to have them support the petition" do
      expect(mail).to have_body_text(%r[https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{petition.sponsor_token}])
    end

    it "includes the petition action" do
      expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
    end

    it "includes the petition background" do
      expect(mail).to have_body_text(%r[Add vans to permitted users of red diesel])
    end

    it "includes the petition additional details" do
      expect(mail).to have_body_text(%r[To promote organic vegetables])
    end
  end

  describe "notifying signature of debate outcome" do
    context "when the signature is the creator" do
      let(:signature) { petition.creator_signature }
      subject(:mail) { described_class.notify_creator_of_debate_outcome(petition, signature) }

      shared_examples_for "a debate outcome email" do
        it "addresses the signatory by name" do
          expect(mail).to have_body_text("Dear Barry Butler,")
        end

        it "sends it only to the creator" do
          expect(mail.to).to eq(%w[bazbutler@gmail.com])
          expect(mail.cc).to be_blank
          expect(mail.bcc).to be_blank
        end

        it "includes a link to the petition page" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/petitions/#{petition.id}])
        end

        it "includes the petition action" do
          expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
        end

        it "includes an unsubscribe link" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/signatures/#{signature.id}/unsubscribe/#{signature.unsubscribe_token}])
        end
      end

      shared_examples_for "a positive debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Parliament debated your petition")
        end

        it "has the positive message in the body" do
          expect(mail).to have_body_text("Parliament debated your petition")
        end
      end

      shared_examples_for "a negative debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Parliament didn't debate your petition")
        end

        it "has the negative message in the body" do
          expect(mail).to have_body_text("The Petitions Committee decided not to debate your petition")
        end
      end

      context "when the debate outcome is positive" do
        context "when the debate outcome is not filled out" do
          before do
            FactoryGirl.create(:debate_outcome, petition: petition)
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a positive debate outcome email"
        end

        context "when the debate outcome is filled out" do
          before do
            FactoryGirl.create(:debate_outcome,
              debated_on: "2015-09-24",
              overview: "Discussion of the 2015 Christmas Adjournment",
              transcript_url: "http://www.publications.parliament.uk/pa/cm201509/cmhansrd/cm20150924/debtext/20150924-0003.htm#2015092449#000001",
              video_url: "http://parliamentlive.tv/event/index/20150924000001",
              petition: petition
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a positive debate outcome email"

          it "includes the debate outcome overview" do
            expect(mail).to have_body_text(%r[Discussion of the 2015 Christmas Adjournment])
          end

          it "includes a link to the transcript of the debate" do
            expect(mail).to have_body_text(%r[http://www.publications.parliament.uk/pa/cm201509/cmhansrd/cm20150924/debtext/20150924-0003.htm#2015092449#000001])
          end

          it "includes a link to the video of the debate" do
            expect(mail).to have_body_text(%r[http://parliamentlive.tv/event/index/20150924000001])
          end
        end
      end

      context "when the debate outcome is negative" do
        context "when the debate outcome is not filled out" do
          before do
            FactoryGirl.create(:debate_outcome, debated: false, petition: petition)
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a negative debate outcome email"
        end

        context "when the debate outcome is filled out" do
          before do
            FactoryGirl.create(:debate_outcome,
              debated: false,
              overview: "Discussion of the 2015 Christmas Adjournment",
              petition: petition
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a negative debate outcome email"

          it "includes the debate outcome overview" do
            expect(mail).to have_body_text(%r[Discussion of the 2015 Christmas Adjournment])
          end
        end
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { FactoryGirl.create(:validated_signature, petition: petition, name: "Laura Palmer", email: "laura@red-room.example.com") }
      subject(:mail) { described_class.notify_signer_of_debate_outcome(petition, signature) }

      shared_examples_for "a debate outcome email" do
        it "addresses the signatory by name" do
          expect(mail).to have_body_text("Dear Laura Palmer,")
        end

        it "sends it only to the signatory" do
          expect(mail.to).to eq(%w[laura@red-room.example.com])
          expect(mail.cc).to be_blank
          expect(mail.bcc).to be_blank
        end

        it "includes a link to the petition page" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/petitions/#{petition.id}])
        end

        it "includes the petition action" do
          expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
        end

        it "includes an unsubscribe link" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/signatures/#{signature.id}/unsubscribe/#{signature.unsubscribe_token}])
        end
      end

      shared_examples_for "a positive debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Parliament debated the petition you signed")
        end

        it "has the positive message in the body" do
          expect(mail).to have_body_text("Parliament debated the petition you signed")
        end
      end

      shared_examples_for "a negative debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Parliament didn't debate the petition you signed")
        end

        it "has the negative message in the body" do
          expect(mail).to have_body_text("The Petitions Committee decided not to debate the petition you signed")
        end
      end

      context "when the debate outcome is positive" do
        context "when the debate outcome is not filled out" do
          before do
            FactoryGirl.create(:debate_outcome, petition: petition)
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a positive debate outcome email"
        end

        context "when the debate outcome is filled out" do
          before do
            FactoryGirl.create(:debate_outcome,
              debated_on: "2015-09-24",
              overview: "Discussion of the 2015 Christmas Adjournment",
              transcript_url: "http://www.publications.parliament.uk/pa/cm201509/cmhansrd/cm20150924/debtext/20150924-0003.htm#2015092449#000001",
              video_url: "http://parliamentlive.tv/event/index/20150924000001",
              petition: petition
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a positive debate outcome email"

          it "includes the debate outcome overview" do
            expect(mail).to have_body_text(%r[Discussion of the 2015 Christmas Adjournment])
          end

          it "includes a link to the transcript of the debate" do
            expect(mail).to have_body_text(%r[http://www.publications.parliament.uk/pa/cm201509/cmhansrd/cm20150924/debtext/20150924-0003.htm#2015092449#000001])
          end

          it "includes a link to the video of the debate" do
            expect(mail).to have_body_text(%r[http://parliamentlive.tv/event/index/20150924000001])
          end
        end
      end

      context "when the debate outcome is negative" do
        context "when the debate outcome is not filled out" do
          before do
            FactoryGirl.create(:debate_outcome, debated: false, petition: petition)
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a negative debate outcome email"
        end

        context "when the debate outcome is filled out" do
          before do
            FactoryGirl.create(:debate_outcome,
              debated: false,
              overview: "Discussion of the 2015 Christmas Adjournment",
              petition: petition
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a negative debate outcome email"

          it "includes the debate outcome overview" do
            expect(mail).to have_body_text(%r[Discussion of the 2015 Christmas Adjournment])
          end
        end
      end
    end
  end

  describe "notifying signature of debate scheduled" do
    let(:petition) { FactoryGirl.create(:open_petition, :scheduled_for_debate, creator_signature_attributes: { name: "Bob Jones", email: "bob@jones.com" }, action: "Allow organic vegetable vans to use red diesel") }

    shared_examples_for "a debate scheduled email" do
      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear #{signature.name},")
      end

      it "sends it only to the signatory" do
        expect(mail.to).to eq([signature.email])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "includes a link to the petition page" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/petitions/#{petition.id}])
      end

      it "includes an unsubscribe link" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/signatures/#{signature.id}/unsubscribe/#{signature.unsubscribe_token}])
      end
    end

    context "when the signature is the creator" do
      let(:signature) { petition.creator_signature }
      subject(:mail) { described_class.notify_creator_of_debate_scheduled(petition, signature) }

      it_behaves_like "a debate scheduled email"

      it "has the correct subject" do
        expect(mail).to have_subject("Parliament will debate your petition")
      end

      it "identifies them as the creator" do
        expect(mail).to have_body_text(%[Parliament is going to debate your petition])
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { FactoryGirl.create(:validated_signature, petition: petition, name: "Laura Palmer", email: "laura@red-room.example.com") }
      subject(:mail) { described_class.notify_signer_of_debate_scheduled(petition, signature) }

      it_behaves_like "a debate scheduled email"

      it "has the correct subject" do
        expect(mail).to have_subject("Parliament will debate the petition you signed")
      end

      it "identifies them as a ordinary signature" do
        expect(mail).to have_body_text(%[Parliament is going to debate the petition you signed])
      end
    end
  end

  describe "emailing a signature" do
    let(:petition) { FactoryGirl.create(:open_petition, :scheduled_for_debate, creator_signature_attributes: { name: "Bob Jones", email: "bob@jones.com" }, action: "Allow organic vegetable vans to use red diesel") }
    let(:email) { FactoryGirl.create(:petition_email, petition: petition, subject: "This is a message from the committee", body: "Message body from the petition committee") }

    shared_examples_for "a petition email" do
      it "has the correct subject" do
        expect(mail).to have_subject("This is a message from the committee")
      end

      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear #{signature.name},")
      end

      it "sends it only to the signatory" do
        expect(mail.to).to eq([signature.email])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "includes a link to the petition page" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/petitions/#{petition.id}])
      end

      it "includes an unsubscribe link" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/signatures/#{signature.id}/unsubscribe/#{signature.unsubscribe_token}])
      end

      it "includes the message body" do
        expect(mail).to have_body_text(%r[Message body from the petition committee])
      end
    end

    context "when the signature is the creator" do
      let(:signature) { petition.creator_signature }
      subject(:mail) { described_class.email_creator(petition, signature, email) }

      it_behaves_like "a petition email"

      it "identifies them as the creator" do
        expect(mail).to have_body_text(%[You recently created the petition])
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { FactoryGirl.create(:validated_signature, petition: petition, name: "Laura Palmer", email: "laura@red-room.example.com") }
      subject(:mail) { described_class.email_signer(petition, signature, email) }

      it_behaves_like "a petition email"

      it "identifies them as a ordinary signature" do
        expect(mail).to have_body_text(%[You recently signed the petition])
      end
    end
  end
end
