require 'rails_helper'

RSpec.describe NotifyJob, type: :job, notify: false do
  let(:success) do
    {
      status: 200,
      headers: {
        "Content-Type" => "application/json"
      },
      body: "{}"
    }
  end

  let(:notify_url) do
    "https://api.notifications.service.gov.uk/v2/notifications/email"
  end

  def notify_request(args)
    request = {
      email_address: args[:email_address],
      template_id: args[:template_id],
      reference: args[:reference],
      personalisation: args[:personalisation].merge(
        moderation_threshold: Site.formatted_threshold_for_moderation,
        referral_threshold: Site.formatted_threshold_for_referral,
        debate_threshold: Site.formatted_threshold_for_debate
      )
    }

    a_request(:post, notify_url).with(body: request.to_json)
  end

  shared_examples_for "a notify job" do
    describe "error handling" do
      around do |example|
        freeze_time { example.run }
      end

      context "when there is a deserialization error" do
        let(:model) { arguments.first.class }
        let(:exception_class) { ActiveJob::DeserializationError }

        before do
          allow(model).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))

          perform_enqueued_jobs {
            described_class.perform_later(*arguments)
          }
        end

        it "doesn't reschedule the job" do
          expect {
            described_class.perform_now(*arguments)
          }.not_to have_enqueued_job(described_class)
        end
      end

      context "when GOV.UK Notify is down" do
        let(:exception_class) { Net::OpenTimeout }

        before do
          stub_request(:post, notify_url).to_timeout
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for an hour later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(1.hour.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 500 error" do
        let(:exception_class) { Notifications::Client::ServerError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 500,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "Exception", message: "Internal server error" }
            ]}.to_json
          )
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for an hour later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(1.hour.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 400 error" do
        let(:exception_class) { Notifications::Client::BadRequestError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 400,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "BadRequestError", message: "Can't send to this recipient using a team-only API key" }
            ]}.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 403 error" do
        let(:exception_class) { Notifications::Client::AuthError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 403,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "AuthError", message: "Invalid token: API key not found" }
            ]}.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 404 error" do
        let(:exception_class) { Notifications::Client::NotFoundError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 404,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "NotFoundError", message: "Not Found" }
            ]}.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when GOV.UK Notify is returning an unknown 4XX error" do
        let(:exception_class) { Notifications::Client::ClientError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 408,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "RequestTimeoutError", message: "Request Timeout" }
            ]}.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when the rate limit is exceeded" do
        let(:exception_class) { Notifications::Client::RateLimitError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 429,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "RateLimitError", message: "Exceeded rate limit for key type LIVE of 3000 requests per 60 seconds" }
            ]}.to_json
          )
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 5 minutes later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(5.minutes.from_now)
        end
      end

      context "when the daily message limit is exceeded" do
        let(:exception_class) { Notifications::Client::RateLimitError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 429,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "TooManyRequestsError", message: "Exceeded send limits (250,000) for today" }
            ]}.to_json
          )
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for midnight" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(Date.tomorrow.beginning_of_day)
        end
      end
    end
  end

  describe "subclasses" do
    let(:easter) { false }
    let(:christmas) { false }
    let(:moderation_queue) { 5 }

    before do
      stub_request(:post, notify_url).to_return(success)

      allow(Holiday).to receive(:easter?).and_return(easter)
      allow(Holiday).to receive(:christmas?).and_return(christmas)

      allow(Petition).to receive_message_chain(:in_moderation, :count).and_return(moderation_queue)
      allow(Site).to receive(:threshold_for_moderation_delay).and_return(10)
    end

    describe GatherSponsorsForPetitionEmailJob do
      let(:signature) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:pending_petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :pending_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and it's not a holiday" do
          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the English template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "7e098470-4a73-435c-bd8c-9f0d9d9ba010",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the English moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "c93ca86b-b508-417c-a4b5-28ec33047b2e",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Easter" do
          let(:easter) { true }

          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the English Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "ed21ff1d-b718-4cef-9491-451f443f9a1d",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the English moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "c93ca86b-b508-417c-a4b5-28ec33047b2e",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Christmas" do
          let(:christmas) { true }

          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the English Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "f7965a34-6f8e-4aa3-97fe-51e8f465d264",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the English moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "c93ca86b-b508-417c-a4b5-28ec33047b2e",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :pending_petition,
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and it's not a holiday" do
          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the Welsh template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "1a52a93e-808a-4ce4-9b24-2d165aaaef4b",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Gwnewch bethau",
                  content: "Oherwydd rhesymau\n\nDyma ychydig mwy o resymau",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the Welsh moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "fb8c5cee-8fb1-46f3-8818-58f3c4311c2b",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Gwnewch bethau",
                  content: "Oherwydd rhesymau\n\nDyma ychydig mwy o resymau",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Easter" do
          let(:easter) { true }

          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the Welsh Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "5920b765-6921-4537-9e01-d8b1338b1071",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Gwnewch bethau",
                  content: "Oherwydd rhesymau\n\nDyma ychydig mwy o resymau",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the Welsh moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "fb8c5cee-8fb1-46f3-8818-58f3c4311c2b",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Gwnewch bethau",
                  content: "Oherwydd rhesymau\n\nDyma ychydig mwy o resymau",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Christmas" do
          let(:christmas) { true }

          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the Welsh Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "6c9730a2-e31d-4c15-9c05-e96ef5cb8ff4",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Gwnewch bethau",
                  content: "Oherwydd rhesymau\n\nDyma ychydig mwy o resymau",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the Welsh moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "fb8c5cee-8fb1-46f3-8818-58f3c4311c2b",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Gwnewch bethau",
                  content: "Oherwydd rhesymau\n\nDyma ychydig mwy o resymau",
                  creator: "Charlie",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}/noddwyr/newydd?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end
      end
    end

    describe PetitionAndEmailConfirmationForSponsorEmailJob do
      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:pending_petition) }
        let(:signature) { FactoryBot.create(:pending_signature, sponsor: true, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :sponsored_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :pending_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "0f912b39-37e2-4de0-886a-28c3e529d139",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Do stuff",
                content: "Because of reasons\n\nHere's some more reasons",
                creator: "Charlie",
                url_en: "https://petitions.senedd.wales/sponsors/#{signature.id}/verify?token=#{signature.perishable_token}",
                url_cy: "https://deisebau.senedd.cymru/noddwyr/#{signature.id}/gwirio?token=#{signature.perishable_token}"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Welsh" do
          let(:signature) do
            FactoryBot.create(
              :pending_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "cy-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "f10ca6dd-4f07-479c-a588-a3abbafe2c55",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Do stuff",
                content: "Because of reasons\n\nHere's some more reasons",
                creator: "Charlie",
                url_en: "https://petitions.senedd.wales/sponsors/#{signature.id}/verify?token=#{signature.perishable_token}",
                url_cy: "https://deisebau.senedd.cymru/noddwyr/#{signature.id}/gwirio?token=#{signature.perishable_token}"
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :sponsored_petition,
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :pending_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "0f912b39-37e2-4de0-886a-28c3e529d139",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Gwnewch bethau",
                content: "Oherwydd rhesymau\n\nDyma ychydig mwy o resymau",
                creator: "Charlie",
                url_en: "https://petitions.senedd.wales/sponsors/#{signature.id}/verify?token=#{signature.perishable_token}",
                url_cy: "https://deisebau.senedd.cymru/noddwyr/#{signature.id}/gwirio?token=#{signature.perishable_token}"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Welsh" do
          let(:signature) do
            FactoryBot.create(
              :pending_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "cy-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "f10ca6dd-4f07-479c-a588-a3abbafe2c55",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Gwnewch bethau",
                content: "Oherwydd rhesymau\n\nDyma ychydig mwy o resymau",
                creator: "Charlie",
                url_en: "https://petitions.senedd.wales/sponsors/#{signature.id}/verify?token=#{signature.perishable_token}",
                url_cy: "https://deisebau.senedd.cymru/noddwyr/#{signature.id}/gwirio?token=#{signature.perishable_token}"
              }
            )).to have_been_made
          end
        end
      end
    end

    describe EmailDuplicateSponsorEmailJob do
      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:validated_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :validated_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              email_count: 1,
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "0f1791a4-55cc-42c2-84d4-d822b35dad55",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Do stuff"
              }
            )).to have_been_made
          end

          it "increments the signature email_count" do
            expect {
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end
            }.to change {
              signature.reload.email_count
            }.from(1).to(2)
          end
        end

        context "and the sponsor signed in Welsh" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "cy-GB",
              email_count: 1,
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "c58cd340-4ba9-43f7-b6f4-7386f7c63260",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Do stuff",
              }
            )).to have_been_made
          end

          it "increments the signature email_count" do
            expect {
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end
            }.to change {
              signature.reload.email_count
            }.from(1).to(2)
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :validated_petition,
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              email_count: 1,
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "0f1791a4-55cc-42c2-84d4-d822b35dad55",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Gwnewch bethau"
              }
            )).to have_been_made
          end

          it "increments the signature email_count" do
            expect {
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end
            }.to change {
              signature.reload.email_count
            }.from(1).to(2)
          end
        end

        context "and the sponsor signed in Welsh" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "cy-GB",
              email_count: 1,
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "c58cd340-4ba9-43f7-b6f4-7386f7c63260",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Gwnewch bethau"
              }
            )).to have_been_made
          end

          it "increments the signature email_count" do
            expect {
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end
            }.to change {
              signature.reload.email_count
            }.from(1).to(2)
          end
        end
      end
    end

    describe EmailConfirmationForSignerEmailJob do
      let(:petition) { FactoryBot.create(:open_petition, action_en: "Do stuff", action_cy: "Gwnewch bethau") }
      let(:constituency) { FactoryBot.create(:constituency, :cardiff_south_and_penarth) }

      it_behaves_like "a notify job" do
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the signature was created in Englsh" do
        let(:signature) { FactoryBot.create(:pending_signature, email: "suzie@example.com", locale: "en-GB", petition: petition) }

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "suzie@example.com",
            template_id: "a33e91d1-808a-4a85-abcc-8a4c62266789",
            reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
            personalisation: {
              action_en: "Do stuff",
              action_cy: "Gwnewch bethau",
              url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/verify?token=#{signature.perishable_token}",
              url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/gwirio?token=#{signature.perishable_token}"
            }
          )).to have_been_made
        end

        it "increments the signature email_count" do
          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.email_count
          }.from(0).to(1)
        end

        it "sets the constituency_id" do
          expect(Constituency).to receive(:find_by_postcode).with("CF991NA").and_return(constituency)

          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.constituency_id
          }.from(nil).to("W09000043")
        end
      end

      context "when the signature was created in Welsh" do
        let(:signature) { FactoryBot.create(:pending_signature, email: "suzie@example.com", locale: "cy-GB", petition: petition) }

        it "sends an email via GOV.UK Notify with the Welsh template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "suzie@example.com",
            template_id: "de60bc30-2d7b-4a71-851f-0ac357af048f",
            reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
            personalisation: {
              action_en: "Do stuff",
              action_cy: "Gwnewch bethau",
              url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/verify?token=#{signature.perishable_token}",
              url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/gwirio?token=#{signature.perishable_token}"
            }
          )).to have_been_made
        end

        it "increments the signature email_count" do
          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.email_count
          }.from(0).to(1)
        end

        it "sets the constituency_id" do
          expect(Constituency).to receive(:find_by_postcode).with("CF991NA").and_return(constituency)

          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.constituency_id
          }.from(nil).to("W09000043")
        end
      end
    end

    describe EmailDuplicateSignaturesEmailJob do
      let(:petition) { FactoryBot.create(:open_petition, action_en: "Do stuff", action_cy: "Gwnewch bethau") }

      it_behaves_like "a notify job" do
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the signature was created in English" do
        let(:signature) { FactoryBot.create(:validated_signature, email: "suzie@example.com", locale: "en-GB", email_count: 1, petition: petition) }

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "suzie@example.com",
            template_id: "e4beb5af-0db1-406b-9c03-a8c8b65f27fd",
            reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
            personalisation: {
              action_en: "Do stuff",
              action_cy: "Gwnewch bethau",
              url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}"
            }
          )).to have_been_made
        end

        it "increments the signature email_count" do
          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.email_count
          }.from(1).to(2)
        end
      end

      context "when the signature was created in Welsh" do
        let(:signature) { FactoryBot.create(:validated_signature, email: "suzie@example.com", locale: "cy-GB", email_count: 1, petition: petition) }

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "suzie@example.com",
            template_id: "8d63e92e-1591-420d-a8ec-1df6ecf6a34c",
            reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
            personalisation: {
              action_en: "Do stuff",
              action_cy: "Gwnewch bethau",
              url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}"
            }
          )).to have_been_made
        end

        it "increments the signature email_count" do
          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.email_count
          }.from(1).to(2)
        end
      end
    end

    describe NotifyCreatorThatPetitionIsPublishedEmailJob do
      let(:signature) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:open_petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :open_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "dc337901-65b0-4e76-b1d5-b14b90e7ee3e",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              creator: "Charlie",
              action_en: "Do stuff", action_cy: "Gwnewch bethau",
              url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}"
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :open_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Welsh template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "2d864e9a-275b-41ea-90c9-92b93da8c48a",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              creator: "Charlie",
              action_en: "Do stuff", action_cy: "Gwnewch bethau",
              url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}"
            }
          )).to have_been_made
        end
      end
    end

    describe NotifySponsorThatPetitionIsPublishedEmailJob do
      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:open_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, sponsor: true, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :open_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "a8557cbf-a889-4392-88a1-988634169d69",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                sponsor: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Welsh" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "cy-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "46f90a8f-eb76-4ed7-b24f-c657560c5c41",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                sponsor: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}"
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :open_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "a8557cbf-a889-4392-88a1-988634169d69",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                sponsor: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Welsh" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "cy-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "46f90a8f-eb76-4ed7-b24f-c657560c5c41",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                sponsor: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}"
              }
            )).to have_been_made
          end
        end
      end
    end

    describe NotifyCreatorThatPetitionWasRejectedEmailJob do
      let(:signature) { petition.creator }
      let(:rejection) { petition.rejection }
      let(:rejection_code) { "duplicate" }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:rejected_petition) }
        let(:arguments) { [signature, rejection] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            state,
            rejection_code: rejection_code,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the petition was published" do
          let(:state) { :rejected_petition }

          it "sends an email via GOV.UK Notify with the English rejection template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "262dc874-cba2-4aef-888d-b6fcd23401a8",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action: "Do stuff",
                content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                content_cy: "Mae deiseb yn bodoli eisoes ar y mater hwn. Ni allwn dderbyn deiseb newydd os oes un yn bodoli eisoes ar fater tebyg iawn, neu os yw’r Pwyllgor Deisebau wedi ystyried deiseb debyg yn ystod y flwyddyn ddiwethaf.",
                url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                standards_url_en: "https://petitions.senedd.wales/help#standards",
                standards_url_cy: "https://deisebau.senedd.cymru/help#standards",
                new_petition_url_en: "https://petitions.senedd.wales/petitions/check",
                new_petition_url_cy: "https://deisebau.senedd.cymru/deisebau/gwirio"
              }
            )).to have_been_made
          end
        end

        context "and the petition was hidden" do
          let(:state) { :hidden_petition }
          let(:rejection_code) { "offensive" }

          it "sends an email via GOV.UK Notify with the English hidden rejection template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "0e9af1c3-17b2-4af6-9440-5fce1f5eb7bb",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action: "Do stuff",
                content_en: "It’s offensive, nonsense, a joke, or an advert.",
                content_cy: "Mae’n sarhaus, yn nonsens, yn jôc neu’n hysbyseb.",
                url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                standards_url_en: "https://petitions.senedd.wales/help#standards",
                standards_url_cy: "https://deisebau.senedd.cymru/help#standards",
                new_petition_url_en: "https://petitions.senedd.wales/petitions/check",
                new_petition_url_cy: "https://deisebau.senedd.cymru/deisebau/gwirio"
              }
            )).to have_been_made
          end
        end

        context "and the petition failed to get enough signatures" do
          let(:state) { :rejected_petition }
          let(:rejection_code) { "insufficient" }

          it "sends an email via GOV.UK Notify with the English insufficient template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "47bbcd29-ffc8-4bea-b490-c6caed2fd0ae",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action_en: "Do stuff", action_cy: "Gwnewch bethau",
                content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in the Senedd.",
                content_cy: "Ni chasglwyd digon o lofnodion i gyfeirio’r ddeiseb at y Pwyllgor Deisebau.\n\nMae angen o leiaf 50 llofnod ar ddeiseb cyn y gellir ei hystyried yn y Senedd.",
                url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                standards_url_en: "https://petitions.senedd.wales/help#standards",
                standards_url_cy: "https://deisebau.senedd.cymru/help#standards",
                new_petition_url_en: "https://petitions.senedd.wales/petitions/check",
                new_petition_url_cy: "https://deisebau.senedd.cymru/deisebau/gwirio"
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            state,
            rejection_code: rejection_code,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and the petition was published" do
          let(:state) { :rejected_petition }

          it "sends an email via GOV.UK Notify with the Welsh rejection template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "71d0736e-ff45-43d5-b083-c78f04d2b02c",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action: "Gwnewch bethau",
                content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                content_cy: "Mae deiseb yn bodoli eisoes ar y mater hwn. Ni allwn dderbyn deiseb newydd os oes un yn bodoli eisoes ar fater tebyg iawn, neu os yw’r Pwyllgor Deisebau wedi ystyried deiseb debyg yn ystod y flwyddyn ddiwethaf.",
                url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                standards_url_en: "https://petitions.senedd.wales/help#standards",
                standards_url_cy: "https://deisebau.senedd.cymru/help#standards",
                new_petition_url_en: "https://petitions.senedd.wales/petitions/check",
                new_petition_url_cy: "https://deisebau.senedd.cymru/deisebau/gwirio"
              }
            )).to have_been_made
          end
        end

        context "and the petition was hidden" do
          let(:state) { :hidden_petition }
          let(:rejection_code) { "offensive" }

          it "sends an email via GOV.UK Notify with the Welsh hidden rejection template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "59dad299-5c03-48b9-be2b-37b90a7701fe",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action: "Gwnewch bethau",
                content_en: "It’s offensive, nonsense, a joke, or an advert.",
                content_cy: "Mae’n sarhaus, yn nonsens, yn jôc neu’n hysbyseb.",
                url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                standards_url_en: "https://petitions.senedd.wales/help#standards",
                standards_url_cy: "https://deisebau.senedd.cymru/help#standards",
                new_petition_url_en: "https://petitions.senedd.wales/petitions/check",
                new_petition_url_cy: "https://deisebau.senedd.cymru/deisebau/gwirio"
              }
            )).to have_been_made
          end
        end

        context "and the petition failed to get enough signatures" do
          let(:state) { :rejected_petition }
          let(:rejection_code) { "insufficient" }

          it "sends an email via GOV.UK Notify with the Welsh insufficient template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "fd40fb7a-0548-4880-bbeb-eb07e409348a",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action_en: "Do stuff", action_cy: "Gwnewch bethau",
                content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in the Senedd.",
                content_cy: "Ni chasglwyd digon o lofnodion i gyfeirio’r ddeiseb at y Pwyllgor Deisebau.\n\nMae angen o leiaf 50 llofnod ar ddeiseb cyn y gellir ei hystyried yn y Senedd.",
                url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                standards_url_en: "https://petitions.senedd.wales/help#standards",
                standards_url_cy: "https://deisebau.senedd.cymru/help#standards",
                new_petition_url_en: "https://petitions.senedd.wales/petitions/check",
                new_petition_url_cy: "https://deisebau.senedd.cymru/deisebau/gwirio"
              }
            )).to have_been_made
          end
        end
      end
    end

    describe NotifySponsorThatPetitionWasRejectedEmailJob do
      let(:rejection) { petition.rejection }
      let(:rejection_code) { "duplicate" }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:rejected_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, sponsor: true, petition: petition) }
        let(:arguments) { [signature, rejection] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            state,
            rejection_code: rejection_code,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the petition was published" do
          let(:state) { :rejected_petition }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "0a9de360-8eab-4e81-946b-7fe2146b6b1e",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Do stuff",
                  content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                  content_cy: "Mae deiseb yn bodoli eisoes ar y mater hwn. Ni allwn dderbyn deiseb newydd os oes un yn bodoli eisoes ar fater tebyg iawn, neu os yw’r Pwyllgor Deisebau wedi ystyried deiseb debyg yn ystod y flwyddyn ddiwethaf.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "9bcdcefd-60a3-4698-85c7-5b4246745b43",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Do stuff",
                  content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                  content_cy: "Mae deiseb yn bodoli eisoes ar y mater hwn. Ni allwn dderbyn deiseb newydd os oes un yn bodoli eisoes ar fater tebyg iawn, neu os yw’r Pwyllgor Deisebau wedi ystyried deiseb debyg yn ystod y flwyddyn ddiwethaf.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and the petition was hidden" do
          let(:state) { :hidden_petition }
          let(:rejection_code) { "offensive" }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English hidden rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "69e7f6e1-da4c-4b1e-95d5-e687a62c2cc7",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Do stuff",
                  content_en: "It’s offensive, nonsense, a joke, or an advert.",
                  content_cy: "Mae’n sarhaus, yn nonsens, yn jôc neu’n hysbyseb.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh hidden rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "cf28ed24-3710-4843-bc35-0ec157adb9ca",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Do stuff",
                  content_en: "It’s offensive, nonsense, a joke, or an advert.",
                  content_cy: "Mae’n sarhaus, yn nonsens, yn jôc neu’n hysbyseb.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and the petition failed to get enough signatures" do
          let(:state) { :rejected_petition }
          let(:rejection_code) { "insufficient" }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English insufficient template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "611e4790-2a93-43fe-897d-07c21caddd0b",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action_en: "Do stuff", action_cy: "Gwnewch bethau",
                  content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in the Senedd.",
                  content_cy: "Ni chasglwyd digon o lofnodion i gyfeirio’r ddeiseb at y Pwyllgor Deisebau.\n\nMae angen o leiaf 50 llofnod ar ddeiseb cyn y gellir ei hystyried yn y Senedd.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh insufficient template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "3911e196-c27a-41dc-8ee4-8390dd198ee6",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action_en: "Do stuff", action_cy: "Gwnewch bethau",
                  content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in the Senedd.",
                  content_cy: "Ni chasglwyd digon o lofnodion i gyfeirio’r ddeiseb at y Pwyllgor Deisebau.\n\nMae angen o leiaf 50 llofnod ar ddeiseb cyn y gellir ei hystyried yn y Senedd.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            state,
            rejection_code: rejection_code,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and the petition was published" do
          let(:state) { :rejected_petition }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "0a9de360-8eab-4e81-946b-7fe2146b6b1e",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Gwnewch bethau",
                  content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                  content_cy: "Mae deiseb yn bodoli eisoes ar y mater hwn. Ni allwn dderbyn deiseb newydd os oes un yn bodoli eisoes ar fater tebyg iawn, neu os yw’r Pwyllgor Deisebau wedi ystyried deiseb debyg yn ystod y flwyddyn ddiwethaf.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "9bcdcefd-60a3-4698-85c7-5b4246745b43",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Gwnewch bethau",
                  content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                  content_cy: "Mae deiseb yn bodoli eisoes ar y mater hwn. Ni allwn dderbyn deiseb newydd os oes un yn bodoli eisoes ar fater tebyg iawn, neu os yw’r Pwyllgor Deisebau wedi ystyried deiseb debyg yn ystod y flwyddyn ddiwethaf.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and the petition was hidden" do
          let(:state) { :hidden_petition }
          let(:rejection_code) { "offensive" }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English hidden rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "69e7f6e1-da4c-4b1e-95d5-e687a62c2cc7",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Gwnewch bethau",
                  content_en: "It’s offensive, nonsense, a joke, or an advert.",
                  content_cy: "Mae’n sarhaus, yn nonsens, yn jôc neu’n hysbyseb.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh hidden rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "cf28ed24-3710-4843-bc35-0ec157adb9ca",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Gwnewch bethau",
                  content_en: "It’s offensive, nonsense, a joke, or an advert.",
                  content_cy: "Mae’n sarhaus, yn nonsens, yn jôc neu’n hysbyseb.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and the petition failed to get enough signatures" do
          let(:state) { :rejected_petition }
          let(:rejection_code) { "insufficient" }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English insufficient template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "611e4790-2a93-43fe-897d-07c21caddd0b",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action_en: "Do stuff", action_cy: "Gwnewch bethau",
                  content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in the Senedd.",
                  content_cy: "Ni chasglwyd digon o lofnodion i gyfeirio’r ddeiseb at y Pwyllgor Deisebau.\n\nMae angen o leiaf 50 llofnod ar ddeiseb cyn y gellir ei hystyried yn y Senedd.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh insufficient template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "3911e196-c27a-41dc-8ee4-8390dd198ee6",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action_en: "Do stuff", action_cy: "Gwnewch bethau",
                  content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in the Senedd.",
                  content_cy: "Ni chasglwyd digon o lofnodion i gyfeirio’r ddeiseb at y Pwyllgor Deisebau.\n\nMae angen o leiaf 50 llofnod ar ddeiseb cyn y gellir ei hystyried yn y Senedd.",
                  url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                  url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                  standards_url_en: "https://petitions.senedd.wales/help#standards",
                  standards_url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end
      end
    end

    describe SponsorSignedEmailBelowThresholdEmailJob do
      let(:creator) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:rejected_petition) }
        let(:sponsor) { FactoryBot.create(:validated_signature, sponsor: true, petition: petition) }
        let(:arguments) { [creator, sponsor] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :pending_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:sponsor) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(creator, sponsor)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "32eabf04-06e7-4e80-9be4-f425321419c1",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                sponsor_count_en: "You have 1 supporter so far",
                sponsor_count_cy: "Mae gennych chi 1 cefnogwr hyd yn hyn",
                url_en: "https://petitions.senedd.wales/help#standards",
                url_cy: "https://deisebau.senedd.cymru/help#standards"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Welsh" do
          let(:sponsor) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "cy-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(creator, sponsor)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "32eabf04-06e7-4e80-9be4-f425321419c1",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                sponsor_count_en: "You have 1 supporter so far",
                sponsor_count_cy: "Mae gennych chi 1 cefnogwr hyd yn hyn",
                url_en: "https://petitions.senedd.wales/help#standards",
                url_cy: "https://deisebau.senedd.cymru/help#standards"
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :pending_petition,
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:sponsor) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(creator, sponsor)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "29b774ac-7852-4657-9b7d-c0395e7f890c",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                sponsor: "Suzie", creator: "Charlie", action: "Gwnewch bethau",
                sponsor_count_en: "You have 1 supporter so far",
                sponsor_count_cy: "Mae gennych chi 1 cefnogwr hyd yn hyn",
                url_en: "https://petitions.senedd.wales/help#standards",
                url_cy: "https://deisebau.senedd.cymru/help#standards"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Welsh" do
          let(:sponsor) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "cy-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(creator, sponsor)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "29b774ac-7852-4657-9b7d-c0395e7f890c",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                sponsor: "Suzie", creator: "Charlie", action: "Gwnewch bethau",
                sponsor_count_en: "You have 1 supporter so far",
                sponsor_count_cy: "Mae gennych chi 1 cefnogwr hyd yn hyn",
                url_en: "https://petitions.senedd.wales/help#standards",
                url_cy: "https://deisebau.senedd.cymru/help#standards"
              }
            )).to have_been_made
          end
        end
      end
    end

    describe SponsorSignedEmailOnThresholdEmailJob do
      let(:creator) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:rejected_petition) }
        let(:sponsor) { FactoryBot.create(:validated_signature, sponsor: true, petition: petition) }
        let(:arguments) { [creator, sponsor] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :validated_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and it's not a holiday" do
          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "b0bbd8f3-ad81-4095-a01d-68d979775418",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "b0bbd8f3-ad81-4095-a01d-68d979775418",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Easter" do
          let(:easter) { true }

          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "6fbe2afa-0ee5-4dec-adab-1a7518cbee33",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "6fbe2afa-0ee5-4dec-adab-1a7518cbee33",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Christmas" do
          let(:christmas) { true }

          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "f6ea7df0-9cb1-4895-941a-183ddd0e79db",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "f6ea7df0-9cb1-4895-941a-183ddd0e79db",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :validated_petition,
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and it's not a holiday" do
          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "8766cdb6-19cb-4eab-a2ba-1af7643f66ee",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Gwnewch bethau",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "8766cdb6-19cb-4eab-a2ba-1af7643f66ee",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Gwnewch bethau",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Easter" do
          let(:easter) { true }

          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "fffa81d1-0625-44a1-af7b-780dd27a7719",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Gwnewch bethau",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "fffa81d1-0625-44a1-af7b-780dd27a7719",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Gwnewch bethau",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Christmas" do
          let(:christmas) { true }

          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "50d84545-2438-478d-9838-d61fc2467efd",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Gwnewch bethau",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Welsh" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "cy-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Welsh Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "50d84545-2438-478d-9838-d61fc2467efd",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Gwnewch bethau",
                  url_en: "https://petitions.senedd.wales/help#standards",
                  url_cy: "https://deisebau.senedd.cymru/help#standards"
                }
              )).to have_been_made
            end
          end
        end
      end
    end

    describe FeedbackEmailJob do
      let(:feedback) do
        FactoryBot.create(
          :feedback,
          comment: "This is a test",
          petition_link_or_title: "https://petitions.senedd.wales/petitions/10000",
          email: "suzie@example.com",
          user_agent: "Mozilla/5.0"
        )
      end

      it_behaves_like "a notify job" do
        let(:arguments) { [feedback] }
      end

      it "sends an email via GOV.UK Notify to the feedback address" do
        perform_enqueued_jobs do
          described_class.perform_later(feedback)
        end

        json = {
          email_address: "petitions@senedd.wales",
          template_id: "68009505-3bc4-49b6-b1b5-c3f36967f9b4",
          reference: feedback.to_gid_param,
          personalisation: {
            comment: "This is a test",
            link_or_title: "https://petitions.senedd.wales/petitions/10000",
            email: "suzie@example.com",
            user_agent: "Mozilla/5.0"
          }
        }.to_json

        expect(a_request(:post, notify_url).with(body: json)).to have_been_made
      end

      context "when feedback sending is disabled" do
        before do
          allow(Site).to receive(:disable_feedback_sending?).and_return(true)
        end

        around do |example|
          freeze_time { example.run }
        end

        it "doesn't send an email via GOV.UK Notify to the feedback address" do
          described_class.perform_now(feedback)

          expect(a_request(:post, notify_url)).not_to have_been_made
        end

        it "reschedules the job" do
          expect {
            described_class.perform_now(feedback)
          }.to have_enqueued_job(described_class).with(feedback).on_queue("high_priority").at(1.hour.from_now)
        end
      end
    end

    describe EmailCreatorAboutOtherBusinessEmailJob do
      let(:signature) { petition.creator }

      let(:email) do
        FactoryBot.create(
          :petition_email,
          petition: petition,
          subject_en: "The Petitions committee will be discussing this petition",
          subject_cy: "Bydd y pwyllgor Deisebau yn trafod y ddeiseb hon",
          body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Senedd.",
          body_cy: "Ar 21 Gorffennaf, bydd y pwyllgor Deisebau yn trafod y ddeiseb hon i weld a ddylid ei hargymell ar gyfer dadl yn y Senedd.",
        )
      end

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:referred_petition) }
        let(:arguments) { [signature, email] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :referred_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, email)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "5b75b985-fc6e-4473-8b51-0958818bea63",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_cy: "Gwnewch bethau",
              petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
              subject_en: "The Petitions committee will be discussing this petition",
              subject_cy: "Bydd y pwyllgor Deisebau yn trafod y ddeiseb hon",
              body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Senedd.",
              body_cy: "Ar 21 Gorffennaf, bydd y pwyllgor Deisebau yn trafod y ddeiseb hon i weld a ddylid ei hargymell ar gyfer dadl yn y Senedd.",
              unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :referred_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Welsh template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, email)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "86b5dee8-ca22-45be-af00-d74d601e656d",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_cy: "Gwnewch bethau",
              petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
              subject_en: "The Petitions committee will be discussing this petition",
              subject_cy: "Bydd y pwyllgor Deisebau yn trafod y ddeiseb hon",
              body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Senedd.",
              body_cy: "Ar 21 Gorffennaf, bydd y pwyllgor Deisebau yn trafod y ddeiseb hon i weld a ddylid ei hargymell ar gyfer dadl yn y Senedd.",
              unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end
    end

    describe EmailCreatorAboutDiversitySurveyEmailJob do
      let(:signature) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:referred_petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :referred_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "f238271b-d186-455a-b2d7-18b17109cb4d",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              creator: "Charlie"
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :referred_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Welsh template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "eb7d9389-d6d7-4a6a-bcc9-c5e8b449b34f",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              creator: "Charlie"
            }
          )).to have_been_made
        end
      end
    end

    describe EmailSignerAboutOtherBusinessEmailJob do
      let(:email) do
        FactoryBot.create(
          :petition_email,
          petition: petition,
          subject_en: "The Petitions committee will be discussing this petition",
          subject_cy: "Bydd y pwyllgor Deisebau yn trafod y ddeiseb hon",
          body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Senedd.",
          body_cy: "Ar 21 Gorffennaf, bydd y pwyllgor Deisebau yn trafod y ddeiseb hon i weld a ddylid ei hargymell ar gyfer dadl yn y Senedd.",
        )
      end

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:referred_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature, email] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :referred_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, email)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "fdc05cf0-81d1-4a28-933c-65b8e10666dd",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                subject_en: "The Petitions committee will be discussing this petition",
                subject_cy: "Bydd y pwyllgor Deisebau yn trafod y ddeiseb hon",
                body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Senedd.",
                body_cy: "Ar 21 Gorffennaf, bydd y pwyllgor Deisebau yn trafod y ddeiseb hon i weld a ddylid ei hargymell ar gyfer dadl yn y Senedd.",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Welsh" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "cy-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, email)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "5aa3434b-0530-4655-a2d2-318fd3668568",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                subject_en: "The Petitions committee will be discussing this petition",
                subject_cy: "Bydd y pwyllgor Deisebau yn trafod y ddeiseb hon",
                body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Senedd.",
                body_cy: "Ar 21 Gorffennaf, bydd y pwyllgor Deisebau yn trafod y ddeiseb hon i weld a ddylid ei hargymell ar gyfer dadl yn y Senedd.",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :referred_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, email)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "fdc05cf0-81d1-4a28-933c-65b8e10666dd",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                subject_en: "The Petitions committee will be discussing this petition",
                subject_cy: "Bydd y pwyllgor Deisebau yn trafod y ddeiseb hon",
                body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Senedd.",
                body_cy: "Ar 21 Gorffennaf, bydd y pwyllgor Deisebau yn trafod y ddeiseb hon i weld a ddylid ei hargymell ar gyfer dadl yn y Senedd.",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Welsh" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "cy-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, email)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "5aa3434b-0530-4655-a2d2-318fd3668568",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                subject_en: "The Petitions committee will be discussing this petition",
                subject_cy: "Bydd y pwyllgor Deisebau yn trafod y ddeiseb hon",
                body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Senedd.",
                body_cy: "Ar 21 Gorffennaf, bydd y pwyllgor Deisebau yn trafod y ddeiseb hon i weld a ddylid ei hargymell ar gyfer dadl yn y Senedd.",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end
    end

    describe NotifyCreatorOfDebateScheduledEmailJob do
      let(:signature) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:scheduled_debate_petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :scheduled_debate_petition,
            debate_threshold_reached_at: "2020-06-30T20:30:00Z",
            scheduled_debate_date: "2020-07-07",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "085e81e4-5ced-4cfe-b142-a03f8b5ffb08",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_cy: "Gwnewch bethau",
              petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
              debate_date_en: "7 July 2020", debate_date_cy: "7 Gorffennaf 2020",
              unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :scheduled_debate_petition,
            debate_threshold_reached_at: "2020-06-30T20:30:00Z",
            scheduled_debate_date: "2020-07-07",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Welsh template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "0e81b36b-9e52-445c-8984-0ee9d89399fe",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_cy: "Gwnewch bethau",
              petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
              debate_date_en: "7 July 2020", debate_date_cy: "7 Gorffennaf 2020",
              unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end
    end

    describe NotifySignerOfDebateScheduledEmailJob do
      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:scheduled_debate_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :scheduled_debate_petition,
            debate_threshold_reached_at: "2020-06-30T20:30:00Z",
            scheduled_debate_date: "2020-07-07",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "824662f6-2cb1-4da8-b65d-6b071c569d0e",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                debate_date_en: "7 July 2020", debate_date_cy: "7 Gorffennaf 2020",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Welsh" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "cy-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "939413df-ec0d-4898-acb2-46a63ea3d42f",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                debate_date_en: "7 July 2020", debate_date_cy: "7 Gorffennaf 2020",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :scheduled_debate_petition,
            debate_threshold_reached_at: "2020-06-30T20:30:00Z",
            scheduled_debate_date: "2020-07-07",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "824662f6-2cb1-4da8-b65d-6b071c569d0e",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                debate_date_en: "7 July 2020", debate_date_cy: "7 Gorffennaf 2020",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Welsh" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "cy-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "939413df-ec0d-4898-acb2-46a63ea3d42f",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                debate_date_en: "7 July 2020", debate_date_cy: "7 Gorffennaf 2020",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end
    end

    describe NotifyCreatorOfNegativeDebateOutcomeEmailJob do
      let(:signature) { petition.creator }
      let(:outcome) { petition.debate_outcome }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:not_debated_petition) }
        let(:arguments) { [signature, outcome] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :not_debated_petition,
            overview_en: "Because it was no longer relevant",
            overview_cy: "Oherwydd nad oedd yn berthnasol mwyach",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, outcome)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "41021e4a-70d7-43ec-b98e-14ca5e8e0835",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_cy: "Gwnewch bethau",
              overview_en: "Because it was no longer relevant",
              overview_cy: "Oherwydd nad oedd yn berthnasol mwyach",
              petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
              petitions_committee_url_en: "https://petitions.senedd.wales/help#petitions-committee",
              petitions_committee_url_cy: "https://deisebau.senedd.cymru/help#petitions-committee",
              unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :not_debated_petition,
            overview_en: "Because it was no longer relevant",
            overview_cy: "Oherwydd nad oedd yn berthnasol mwyach",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Welsh template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, outcome)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "3e283d4a-7b74-4a96-8431-857e3b3bfc89",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_cy: "Gwnewch bethau",
              overview_en: "Because it was no longer relevant",
              overview_cy: "Oherwydd nad oedd yn berthnasol mwyach",
              petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
              petitions_committee_url_en: "https://petitions.senedd.wales/help#petitions-committee",
              petitions_committee_url_cy: "https://deisebau.senedd.cymru/help#petitions-committee",
              unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end
    end

    describe NotifySignerOfNegativeDebateOutcomeEmailJob do
      let(:outcome) { petition.debate_outcome }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:not_debated_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature, outcome] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :not_debated_petition,
            overview_en: "Because it was no longer relevant",
            overview_cy: "Oherwydd nad oedd yn berthnasol mwyach",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "865e3a66-6b98-406d-8883-04dd7d35a580",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                overview_en: "Because it was no longer relevant",
                overview_cy: "Oherwydd nad oedd yn berthnasol mwyach",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                petitions_committee_url_en: "https://petitions.senedd.wales/help#petitions-committee",
                petitions_committee_url_cy: "https://deisebau.senedd.cymru/help#petitions-committee",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Welsh" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "cy-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "d97d154f-cdb8-4273-b6cb-d5f89479efba",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                overview_en: "Because it was no longer relevant",
                overview_cy: "Oherwydd nad oedd yn berthnasol mwyach",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                petitions_committee_url_en: "https://petitions.senedd.wales/help#petitions-committee",
                petitions_committee_url_cy: "https://deisebau.senedd.cymru/help#petitions-committee",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :not_debated_petition,
            overview_en: "Because it was no longer relevant",
            overview_cy: "Oherwydd nad oedd yn berthnasol mwyach",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "865e3a66-6b98-406d-8883-04dd7d35a580",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                overview_en: "Because it was no longer relevant",
                overview_cy: "Oherwydd nad oedd yn berthnasol mwyach",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                petitions_committee_url_en: "https://petitions.senedd.wales/help#petitions-committee",
                petitions_committee_url_cy: "https://deisebau.senedd.cymru/help#petitions-committee",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Welsh" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "cy-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "d97d154f-cdb8-4273-b6cb-d5f89479efba",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                overview_en: "Because it was no longer relevant",
                overview_cy: "Oherwydd nad oedd yn berthnasol mwyach",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                petitions_committee_url_en: "https://petitions.senedd.wales/help#petitions-committee",
                petitions_committee_url_cy: "https://deisebau.senedd.cymru/help#petitions-committee",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end
    end

    describe NotifyCreatorOfPositiveDebateOutcomeEmailJob do
      let(:signature) { petition.creator }
      let(:outcome) { petition.debate_outcome }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:debated_petition) }
        let(:arguments) { [signature, outcome] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :debated_petition,
            overview_en: "Senedd came to the conclusion that this was a good idea",
            overview_cy: "Daeth y Senedd i'r casgliad bod hwn yn syniad da",
            transcript_url_en: "https://record.assembly.wales/Plenary/5667#A51756",
            transcript_url_cy: "https://cofnod.cynulliad.cymru/Plenary/5667#A51756",
            video_url_en: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
            video_url_cy: "http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True",
            debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
            debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, outcome)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "929f4523-ee7d-4895-a9e5-32f9fff0c41a",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_cy: "Gwnewch bethau",
              overview_en: "Senedd came to the conclusion that this was a good idea",
              overview_cy: "Daeth y Senedd i'r casgliad bod hwn yn syniad da",
              transcript_url_en: "https://record.assembly.wales/Plenary/5667#A51756",
              transcript_url_cy: "https://cofnod.cynulliad.cymru/Plenary/5667#A51756",
              video_url_en: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
              video_url_cy: "http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True",
              debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
              debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667",
              petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
              unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :debated_petition,
            overview_en: "Senedd came to the conclusion that this was a good idea",
            overview_cy: "Daeth y Senedd i'r casgliad bod hwn yn syniad da",
            transcript_url_en: "https://record.assembly.wales/Plenary/5667#A51756",
            transcript_url_cy: "https://cofnod.cynulliad.cymru/Plenary/5667#A51756",
            video_url_en: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
            video_url_cy: "http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True",
            debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
            debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Welsh template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, outcome)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "4bda6753-3639-4bad-94a2-b1b1596222b9",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_cy: "Gwnewch bethau",
              overview_en: "Senedd came to the conclusion that this was a good idea",
              overview_cy: "Daeth y Senedd i'r casgliad bod hwn yn syniad da",
              transcript_url_en: "https://record.assembly.wales/Plenary/5667#A51756",
              transcript_url_cy: "https://cofnod.cynulliad.cymru/Plenary/5667#A51756",
              video_url_en: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
              video_url_cy: "http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True",
              debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
              debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667",
              petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
              petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
              unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end
    end

    describe NotifySignerOfPositiveDebateOutcomeEmailJob do
      let(:outcome) { petition.debate_outcome }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:debated_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature, outcome] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :debated_petition,
            overview_en: "Senedd came to the conclusion that this was a good idea",
            overview_cy: "Daeth y Senedd i'r casgliad bod hwn yn syniad da",
            transcript_url_en: "https://record.assembly.wales/Plenary/5667#A51756",
            transcript_url_cy: "https://cofnod.cynulliad.cymru/Plenary/5667#A51756",
            video_url_en: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
            video_url_cy: "http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True",
            debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
            debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "4254e36c-b0bc-48ad-9a8c-62d59d16d0ce",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                overview_en: "Senedd came to the conclusion that this was a good idea",
                overview_cy: "Daeth y Senedd i'r casgliad bod hwn yn syniad da",
                transcript_url_en: "https://record.assembly.wales/Plenary/5667#A51756",
                transcript_url_cy: "https://cofnod.cynulliad.cymru/Plenary/5667#A51756",
                video_url_en: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
                video_url_cy: "http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True",
                debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
                debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Welsh" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "cy-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "61cd5971-7bc7-4a1e-b30b-d799a36bff5c",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                overview_en: "Senedd came to the conclusion that this was a good idea",
                overview_cy: "Daeth y Senedd i'r casgliad bod hwn yn syniad da",
                transcript_url_en: "https://record.assembly.wales/Plenary/5667#A51756",
                transcript_url_cy: "https://cofnod.cynulliad.cymru/Plenary/5667#A51756",
                video_url_en: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
                video_url_cy: "http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True",
                debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
                debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Welsh" do
        let(:petition) do
          FactoryBot.create(
            :debated_petition,
            overview_en: "Senedd came to the conclusion that this was a good idea",
            overview_cy: "Daeth y Senedd i'r casgliad bod hwn yn syniad da",
            transcript_url_en: "https://record.assembly.wales/Plenary/5667#A51756",
            transcript_url_cy: "https://cofnod.cynulliad.cymru/Plenary/5667#A51756",
            video_url_en: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
            video_url_cy: "http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True",
            debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
            debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_cy: "Gwnewch bethau",
            background_cy: "Oherwydd rhesymau",
            additional_details_cy: "Dyma ychydig mwy o resymau",
            locale: "cy-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "cy-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "4254e36c-b0bc-48ad-9a8c-62d59d16d0ce",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                overview_en: "Senedd came to the conclusion that this was a good idea",
                overview_cy: "Daeth y Senedd i'r casgliad bod hwn yn syniad da",
                transcript_url_en: "https://record.assembly.wales/Plenary/5667#A51756",
                transcript_url_cy: "https://cofnod.cynulliad.cymru/Plenary/5667#A51756",
                video_url_en: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
                video_url_cy: "http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True",
                debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
                debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Welsh" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "cy-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Welsh template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "61cd5971-7bc7-4a1e-b30b-d799a36bff5c",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_cy: "Gwnewch bethau",
                overview_en: "Senedd came to the conclusion that this was a good idea",
                overview_cy: "Daeth y Senedd i'r casgliad bod hwn yn syniad da",
                transcript_url_en: "https://record.assembly.wales/Plenary/5667#A51756",
                transcript_url_cy: "https://cofnod.cynulliad.cymru/Plenary/5667#A51756",
                video_url_en: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
                video_url_cy: "http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True",
                debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
                debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667",
                petition_url_en: "https://petitions.senedd.wales/petitions/#{petition.id}",
                petition_url_cy: "https://deisebau.senedd.cymru/deisebau/#{petition.id}",
                unsubscribe_url_en: "https://petitions.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_cy: "https://deisebau.senedd.cymru/llofnodion/#{signature.id}/dad-danysgrifio?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end
    end
  end
end
