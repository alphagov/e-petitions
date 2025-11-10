require "rails_helper"

RSpec.describe Archived::PetitionMailer, type: :mailer do
  let :creator do
    FactoryBot.create(:archived_signature,
      name: "Barry Butler",
      email: "bazbutler@gmail.com",
      creator: true
    )
  end

  let(:signer) do
    FactoryBot.create(:archived_signature,
      name: "Laura Palmer",
      email: "laurapalmer@hotmail.com",
      petition: petition
    )
  end

  describe "notifying signature of a government response" do
    let :petition do
      FactoryBot.create(:archived_petition, :response,
        action: "Allow organic vegetable vans to use red diesel",
        background: "Add vans to permitted users of red diesel",
        additional_details: "To promote organic vegetables",
        response_summary: "Sounds like a good idea",
        response_details: "We’ll get right on that",
        signature_count: signature_count
      )
    end

    let(:signature_count) { 15000 }

    shared_examples_for "a government response email" do
      it "includes a link to the petition page" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
      end

      it "includes the petition action" do
        expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
      end

      it "includes an unsubscribe link" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
      end

      it "has a List-Unsubscribe header" do
        expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
      end

      it "has a List-Unsubscribe-Post header" do
        expect(mail).to have_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
      end

      it "has the correct subject" do
        expect(mail).to have_subject("Government responded to “Allow organic vegetable vans to use red diesel”")
      end

      it "has response summary in the body" do
        expect(mail).to have_body_text("Sounds like a good idea")
      end

      it "has response details in the body" do
        expect(mail).to have_body_text("We’ll get right on that")
      end

      it "includes a link to read the response online" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}\?reveal_response=yes])
      end

      context "when the signature count is less than the debate threshold" do
        let(:signature_count) { 12345 }

        it "includes a message about the committee's response" do
          expect(mail).to have_body_text("The Petitions Committee will take a look at this petition and its response.")
          expect(mail).to have_body_text("They can press the government for action and gather evidence.")
          expect(mail).to have_body_text("If this petition reaches 100,000 signatures, the Committee will consider it for a debate.")
        end
      end

      context "when the signature count is more than the debate threshold" do
        let(:signature_count) { 123456 }

        it "includes a message about the committee's response" do
          expect(mail).to have_body_text("This petition has over 100,000 signatures.")
          expect(mail).to have_body_text("The Petitions Committee will consider it for a debate.")
          expect(mail).to have_body_text("They can also gather further evidence and press the government for action.")
        end
      end
    end

    context "when the signature is the creator" do
      let(:signature) { creator }
      subject(:mail) { described_class.notify_creator_of_threshold_response(petition, signature) }

      it_behaves_like "a government response email"

      it "sends it only to the creator" do
        expect(mail.to).to eq(%w[bazbutler@gmail.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear Barry Butler,")
      end

      it "has the message in the body" do
        expect(mail).to have_body_text("The Government has responded to your petition")
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { signer }
      subject(:mail) { described_class.notify_signer_of_threshold_response(petition, signature) }

      it_behaves_like "a government response email"

      it "sends it only to the signer" do
        expect(mail.to).to eq(%w[laurapalmer@hotmail.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear Laura Palmer,")
      end

      it "has the message in the body" do
        expect(mail).to have_body_text("The Government has responded to the petition you signed")
      end
    end
  end

  describe "notifying signature of a debate being scheduled" do
    let :petition do
      FactoryBot.create(:archived_petition, :scheduled_for_debate,
        action: "Allow organic vegetable vans to use red diesel",
        background: "Add vans to permitted users of red diesel",
        additional_details: "To promote organic vegetables",
        scheduled_debate_date: "2017-09-12"
      )
    end

    shared_examples_for "a debate scheduled email" do
      it "includes a link to the petition page" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
      end

      it "includes the petition action" do
        expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
      end

      it "includes an unsubscribe link" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
      end

      it "has a List-Unsubscribe header" do
        expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
      end

      it "has a List-Unsubscribe-Post header" do
        expect(mail).to have_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
      end

      it "has the correct subject" do
        expect(mail).to have_subject("Parliament will debate “Allow organic vegetable vans to use red diesel”")
      end

      it "has the scheduled debate date in the body" do
        expect(mail).to have_body_text("12 September 2017")
      end
    end

    context "when the signature is the creator" do
      let(:signature) { creator }
      subject(:mail) { described_class.notify_creator_of_debate_scheduled(petition, signature) }

      it_behaves_like "a debate scheduled email"

      it "sends it only to the creator" do
        expect(mail.to).to eq(%w[bazbutler@gmail.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear Barry Butler,")
      end

      it "has the message in the body" do
        expect(mail).to have_body_text("Parliament is going to debate your petition")
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { signer }
      subject(:mail) { described_class.notify_signer_of_debate_scheduled(petition, signature) }

      it_behaves_like "a debate scheduled email"

      it "sends it only to the signer" do
        expect(mail.to).to eq(%w[laurapalmer@hotmail.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear Laura Palmer,")
      end

      it "has the message in the body" do
        expect(mail).to have_body_text("Parliament is going to debate the petition you signed")
      end
    end
  end

  describe "notifying signature of debate outcome" do
    context "when the signature is the creator" do
      let(:signature) { creator }
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
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
        end

        it "includes the petition action" do
          expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
        end

        it "includes an unsubscribe link" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
        end

        it "has a List-Unsubscribe header" do
          expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
        end

        it "has a List-Unsubscribe-Post header" do
          expect(mail).to have_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
        end
      end

      shared_examples_for "a positive debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Parliament debated “Allow organic vegetable vans to use red diesel”")
        end

        it "has the positive message in the body" do
          expect(mail).to have_body_text("Parliament debated your petition")
        end
      end

      shared_examples_for "a negative debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject('Parliament didn’t debate “Allow organic vegetable vans to use red diesel”')
        end

        it "has the negative message in the body" do
          expect(mail).to have_body_text("The Petitions Committee decided not to debate your petition")
        end
      end

      context "when the debate outcome is positive" do
        context "when the debate outcome is not filled out" do
          let :petition do
            FactoryBot.create(:archived_petition, :debated,
              action: "Allow organic vegetable vans to use red diesel",
              background: "Add vans to permitted users of red diesel",
              additional_details: "To promote organic vegetables"
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a positive debate outcome email"
        end

        context "when the debate outcome is filled out" do
          let :petition do
            FactoryBot.create(:archived_petition, :debated,
              action: "Allow organic vegetable vans to use red diesel",
              background: "Add vans to permitted users of red diesel",
              additional_details: "To promote organic vegetables",
              debated_on: "2015-09-24",
              overview: "Discussion of the 2015 Christmas Adjournment",
              transcript_url: "http://www.publications.parliament.uk/pa/cm201509/cmhansrd/cm20150924/debtext/20150924-0003.htm#2015092449#000001",
              video_url: "http://parliamentlive.tv/event/index/20150924000001",
              debate_pack_url: "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2015-0001",
              public_engagement_url: "https://committees.parliament.uk/public-engagement",
              debate_summary_url: "https://ukparliament.shorthandstories.com/about-a-petition",
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
          let :petition do
            FactoryBot.create(:archived_petition, :not_debated,
              action: "Allow organic vegetable vans to use red diesel",
              background: "Add vans to permitted users of red diesel",
              additional_details: "To promote organic vegetables"
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a negative debate outcome email"
        end

        context "when the debate outcome is filled out" do
          let :petition do
            FactoryBot.create(:archived_petition, :not_debated,
              action: "Allow organic vegetable vans to use red diesel",
              background: "Add vans to permitted users of red diesel",
              additional_details: "To promote organic vegetables",
              overview: "Discussion of the 2015 Christmas Adjournment"
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
      let(:signature) { signer }
      subject(:mail) { described_class.notify_signer_of_debate_outcome(petition, signature) }

      shared_examples_for "a debate outcome email" do
        it "addresses the signatory by name" do
          expect(mail).to have_body_text("Dear Laura Palmer,")
        end

        it "sends it only to the signatory" do
          expect(mail.to).to eq(%w[laurapalmer@hotmail.com])
          expect(mail.cc).to be_blank
          expect(mail.bcc).to be_blank
        end

        it "includes a link to the petition page" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
        end

        it "includes the petition action" do
          expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
        end

        it "includes an unsubscribe link" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
        end

        it "has a List-Unsubscribe header" do
          expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
        end

        it "has a List-Unsubscribe-Post header" do
          expect(mail).to have_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
        end
      end

      shared_examples_for "a positive debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Parliament debated “Allow organic vegetable vans to use red diesel”")
        end

        it "has the positive message in the body" do
          expect(mail).to have_body_text("Parliament debated the petition you signed")
        end
      end

      shared_examples_for "a negative debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Parliament didn’t debate “Allow organic vegetable vans to use red diesel”")
        end

        it "has the negative message in the body" do
          expect(mail).to have_body_text("The Petitions Committee decided not to debate the petition you signed")
        end
      end

      context "when the debate outcome is positive" do
        context "when the debate outcome is not filled out" do
          let :petition do
            FactoryBot.create(:archived_petition, :debated,
              action: "Allow organic vegetable vans to use red diesel",
              background: "Add vans to permitted users of red diesel",
              additional_details: "To promote organic vegetables"
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a positive debate outcome email"
        end

        context "when the debate outcome is filled out" do
          let :petition do
            FactoryBot.create(:archived_petition, :debated,
              action: "Allow organic vegetable vans to use red diesel",
              background: "Add vans to permitted users of red diesel",
              additional_details: "To promote organic vegetables",
              debated_on: "2015-09-24",
              overview: "Discussion of the 2015 Christmas Adjournment",
              transcript_url: "http://www.publications.parliament.uk/pa/cm201509/cmhansrd/cm20150924/debtext/20150924-0003.htm#2015092449#000001",
              video_url: "http://parliamentlive.tv/event/index/20150924000001",
              debate_pack_url: "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2015-0001"
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
          let :petition do
            FactoryBot.create(:archived_petition, :not_debated,
              action: "Allow organic vegetable vans to use red diesel",
              background: "Add vans to permitted users of red diesel",
              additional_details: "To promote organic vegetables"
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a negative debate outcome email"
        end

        context "when the debate outcome is filled out" do
          let :petition do
            FactoryBot.create(:archived_petition, :not_debated,
              action: "Allow organic vegetable vans to use red diesel",
              background: "Add vans to permitted users of red diesel",
              additional_details: "To promote organic vegetables",
              overview: "Discussion of the 2015 Christmas Adjournment"
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

  describe "notifying signature of a negative debate outcome" do
    context "when the signature is the creator" do
      let(:signature) { creator }
      subject(:mail) { described_class.notify_creator_of_negative_debate_outcome(petition, signature) }

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
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
        end

        it "includes the petition action" do
          expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
        end

        it "includes an unsubscribe link" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
        end

        it "has a List-Unsubscribe header" do
          expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
        end

        it "has a List-Unsubscribe-Post header" do
          expect(mail).to have_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
        end
      end

      shared_examples_for "a negative debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject('Parliament didn’t debate “Allow organic vegetable vans to use red diesel”')
        end

        it "has the negative message in the body" do
          expect(mail).to have_body_text("The Petitions Committee decided not to debate your petition")
        end
      end

      context "when the debate outcome is not filled out" do
        let :petition do
          FactoryBot.create(:archived_petition, :not_debated,
            action: "Allow organic vegetable vans to use red diesel",
            background: "Add vans to permitted users of red diesel",
            additional_details: "To promote organic vegetables"
          )
        end

        it_behaves_like "a debate outcome email"
        it_behaves_like "a negative debate outcome email"
      end

      context "when the debate outcome is filled out" do
        let :petition do
          FactoryBot.create(:archived_petition, :not_debated,
            action: "Allow organic vegetable vans to use red diesel",
            background: "Add vans to permitted users of red diesel",
            additional_details: "To promote organic vegetables",
            overview: "Discussion of the 2015 Christmas Adjournment"
          )
        end

        it_behaves_like "a debate outcome email"
        it_behaves_like "a negative debate outcome email"

        it "includes the debate outcome overview" do
          expect(mail).to have_body_text(%r[Discussion of the 2015 Christmas Adjournment])
        end
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { signer }
      subject(:mail) { described_class.notify_signer_of_negative_debate_outcome(petition, signature) }

      shared_examples_for "a debate outcome email" do
        it "addresses the signatory by name" do
          expect(mail).to have_body_text("Dear Laura Palmer,")
        end

        it "sends it only to the signatory" do
          expect(mail.to).to eq(%w[laurapalmer@hotmail.com])
          expect(mail.cc).to be_blank
          expect(mail.bcc).to be_blank
        end

        it "includes a link to the petition page" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
        end

        it "includes the petition action" do
          expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
        end

        it "includes an unsubscribe link" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
        end

        it "has a List-Unsubscribe header" do
          expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
        end

        it "has a List-Unsubscribe-Post header" do
          expect(mail).to have_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
        end
      end

      shared_examples_for "a negative debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Parliament didn’t debate “Allow organic vegetable vans to use red diesel”")
        end

        it "has the negative message in the body" do
          expect(mail).to have_body_text("The Petitions Committee decided not to debate the petition you signed")
        end
      end

      context "when the debate outcome is not filled out" do
        let :petition do
          FactoryBot.create(:archived_petition, :not_debated,
            action: "Allow organic vegetable vans to use red diesel",
            background: "Add vans to permitted users of red diesel",
            additional_details: "To promote organic vegetables"
          )
        end

        it_behaves_like "a debate outcome email"
        it_behaves_like "a negative debate outcome email"
      end

      context "when the debate outcome is filled out" do
        let :petition do
          FactoryBot.create(:archived_petition, :not_debated,
            action: "Allow organic vegetable vans to use red diesel",
            background: "Add vans to permitted users of red diesel",
            additional_details: "To promote organic vegetables",
            overview: "Discussion of the 2015 Christmas Adjournment"
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

  describe "notifying signature of a positive debate outcome" do
    context "when the signature is the creator" do
      let(:signature) { creator }
      subject(:mail) { described_class.notify_creator_of_positive_debate_outcome(petition, signature) }

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
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
        end

        it "includes the petition action" do
          expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
        end

        it "includes an unsubscribe link" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
        end

        it "has a List-Unsubscribe header" do
          expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
        end

        it "has a List-Unsubscribe-Post header" do
          expect(mail).to have_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
        end
      end

      shared_examples_for "a positive debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Parliament debated “Allow organic vegetable vans to use red diesel”")
        end

        it "has the positive message in the body" do
          expect(mail).to have_body_text("Parliament debated your petition")
        end
      end

      context "when the debate outcome is not filled out" do
        let :petition do
          FactoryBot.create(:archived_petition, :debated,
            action: "Allow organic vegetable vans to use red diesel",
            background: "Add vans to permitted users of red diesel",
            additional_details: "To promote organic vegetables"
          )
        end

        it_behaves_like "a debate outcome email"
        it_behaves_like "a positive debate outcome email"
      end

      context "when the debate outcome is filled out" do
        let :petition do
          FactoryBot.create(:archived_petition, :debated,
            action: "Allow organic vegetable vans to use red diesel",
            background: "Add vans to permitted users of red diesel",
            additional_details: "To promote organic vegetables",
            debated_on: "2015-09-24",
            overview: "Discussion of the 2015 Christmas Adjournment",
            transcript_url: "http://www.publications.parliament.uk/pa/cm201509/cmhansrd/cm20150924/debtext/20150924-0003.htm#2015092449#000001",
            video_url: "http://parliamentlive.tv/event/index/20150924000001",
            debate_pack_url: "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2015-0001",
            public_engagement_url: "https://committees.parliament.uk/public-engagement",
            debate_summary_url: "https://ukparliament.shorthandstories.com/about-a-petition",
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

    context "when the signature is not the creator" do
      let(:signature) { signer }
      subject(:mail) { described_class.notify_signer_of_positive_debate_outcome(petition, signature) }

      shared_examples_for "a debate outcome email" do
        it "addresses the signatory by name" do
          expect(mail).to have_body_text("Dear Laura Palmer,")
        end

        it "sends it only to the signatory" do
          expect(mail.to).to eq(%w[laurapalmer@hotmail.com])
          expect(mail.cc).to be_blank
          expect(mail.bcc).to be_blank
        end

        it "includes a link to the petition page" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
        end

        it "includes the petition action" do
          expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
        end

        it "includes an unsubscribe link" do
          expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
        end

        it "has a List-Unsubscribe header" do
          expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
        end

        it "has a List-Unsubscribe-Post header" do
          expect(mail).to have_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
        end
      end

      shared_examples_for "a positive debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Parliament debated “Allow organic vegetable vans to use red diesel”")
        end

        it "has the positive message in the body" do
          expect(mail).to have_body_text("Parliament debated the petition you signed")
        end
      end

      context "when the debate outcome is not filled out" do
        let :petition do
          FactoryBot.create(:archived_petition, :debated,
            action: "Allow organic vegetable vans to use red diesel",
            background: "Add vans to permitted users of red diesel",
            additional_details: "To promote organic vegetables"
          )
        end

        it_behaves_like "a debate outcome email"
        it_behaves_like "a positive debate outcome email"
      end

      context "when the debate outcome is filled out" do
        let :petition do
          FactoryBot.create(:archived_petition, :debated,
            action: "Allow organic vegetable vans to use red diesel",
            background: "Add vans to permitted users of red diesel",
            additional_details: "To promote organic vegetables",
            debated_on: "2015-09-24",
            overview: "Discussion of the 2015 Christmas Adjournment",
            transcript_url: "http://www.publications.parliament.uk/pa/cm201509/cmhansrd/cm20150924/debtext/20150924-0003.htm#2015092449#000001",
            video_url: "http://parliamentlive.tv/event/index/20150924000001",
            debate_pack_url: "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2015-0001"
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
  end

  describe "emailing a signature" do
    let :petition do
      FactoryBot.create(:archived_petition,
        action: "Allow organic vegetable vans to use red diesel",
        background: "Add vans to permitted users of red diesel",
        additional_details: "To promote organic vegetables"
      )
    end

    let(:email) do
      FactoryBot.create(:archived_petition_email,
        subject: "This is a message from the committee",
        body: "Message body from the petition committee",
        petition: petition
      )
    end

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
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
      end

      it "includes an unsubscribe link" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
      end

      it "has a List-Unsubscribe header" do
        expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
      end

      it "has a List-Unsubscribe-Post header" do
        expect(mail).to have_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
      end

      it "includes the message body" do
        expect(mail).to have_body_text(%r[Message body from the petition committee])
      end
    end

    context "when the signature is the creator" do
      let(:signature) { creator }
      subject(:mail) { described_class.email_creator(petition, signature, email) }

      it_behaves_like "a petition email"

      it "identifies them as the creator" do
        expect(mail).to have_body_text(%[You recently created the petition])
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { signer }
      subject(:mail) { described_class.email_signer(petition, signature, email) }

      it_behaves_like "a petition email"

      it "identifies them as a ordinary signature" do
        expect(mail).to have_body_text(%[You recently signed the petition])
      end
    end
  end

  describe "sending a mailshot" do
    let :petition do
      FactoryBot.create(:archived_petition,
        action: "Allow organic vegetable vans to use red diesel",
        background: "Add vans to permitted users of red diesel",
        additional_details: "To promote organic vegetables"
      )
    end

    let(:mailshot) do
      FactoryBot.create(:archived_petition_mailshot,
        subject: "This is a message from the committee",
        body: "Message body from the petition committee",
        petition: petition
      )
    end

    shared_examples_for "a petition mailshot" do
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
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
      end

      it "includes an unsubscribe link" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
      end

      it "has a List-Unsubscribe header" do
        expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
      end

      it "has a List-Unsubscribe-Post header" do
        expect(mail).to have_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
      end

      it "includes the message body" do
        expect(mail).to have_body_text(%r[Message body from the petition committee])
      end
    end

    context "when the signature is the creator" do
      let(:signature) { creator }
      subject(:mail) { described_class.mailshot_for_creator(petition, signature, mailshot) }

      it_behaves_like "a petition mailshot"

      it "identifies them as the creator" do
        expect(mail).to have_body_text(%[You recently created the petition])
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { signer }
      subject(:mail) { described_class.mailshot_for_signer(petition, signature, mailshot) }

      it_behaves_like "a petition mailshot"

      it "identifies them as a ordinary signature" do
        expect(mail).to have_body_text(%[You recently signed the petition])
      end
    end
  end

  describe "skipping anonymized signatures" do
    let(:petition) { FactoryBot.create(:archived_petition) }
    let(:email) { FactoryBot.create(:archived_petition_email, petition: petition, subject: "This is a message from the committee", body: "Message body from the petition committee") }
    subject(:mail) { described_class.email_signer(petition, signature, email) }

    context "when the signature is not anonymized" do
      let(:signature) { FactoryBot.create(:archived_signature, :validated, petition: petition) }

      it "will deliver the email" do
        expect(mail.perform_deliveries).to eq(true)
      end
    end

    context "when the signature is anonymized" do
      let(:signature) { FactoryBot.create(:archived_signature, :validated, petition: petition, created_at: 13.months.ago, anonymized_at: 1.month.ago) }

      it "will not deliver the email" do
        expect(mail.perform_deliveries).to eq(false)
      end
    end
  end
end
