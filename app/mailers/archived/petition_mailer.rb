module Archived
  class PetitionMailer < ApplicationMailer
    include ActiveSupport::NumberHelper

    def email_signer(petition, signature, email)
      @petition, @signature, @email = petition, signature, email

      mail to: @signature.email,
        subject: subject_for(:email_signer),
        list_unsubscribe: unsubscribe_url,
        list_unsubscribe_post: one_click_unsubscribe
    end

    def email_creator(petition, signature, email)
      @petition, @signature, @email = petition, signature, email

      mail to: @signature.email,
        subject: subject_for(:email_creator),
        list_unsubscribe: unsubscribe_url,
        list_unsubscribe_post: one_click_unsubscribe
    end

    def mailshot_for_signer(petition, signature, mailshot)
      @petition, @signature, @mailshot = petition, signature, mailshot

      mail to: @signature.email,
        subject: subject_for(:mailshot_for_signer),
        list_unsubscribe: unsubscribe_url,
        list_unsubscribe_post: one_click_unsubscribe
    end

    def mailshot_for_creator(petition, signature, mailshot)
      @petition, @signature, @mailshot = petition, signature, mailshot

      mail to: @signature.email,
        subject: subject_for(:mailshot_for_creator),
        list_unsubscribe: unsubscribe_url,
        list_unsubscribe_post: one_click_unsubscribe
    end

    def notify_signer_of_threshold_response(petition, signature)
      @petition, @signature = petition, signature
      @government_response, @parliament = petition.government_response, petition.parliament

      mail to: @signature.email,
        subject: subject_for(:notify_signer_of_threshold_response),
        list_unsubscribe: unsubscribe_url,
        list_unsubscribe_post: one_click_unsubscribe
    end

    def notify_creator_of_threshold_response(petition, signature)
      @petition, @signature = petition, signature
      @government_response, @parliament = petition.government_response, petition.parliament

      mail to: @signature.email,
        subject: subject_for(:notify_creator_of_threshold_response),
        list_unsubscribe: unsubscribe_url,
        list_unsubscribe_post: one_click_unsubscribe
    end

    def notify_signer_of_debate_scheduled(petition, signature)
      @petition, @signature = petition, signature

      mail to: @signature.email,
        subject: subject_for(:notify_signer_of_debate_scheduled),
        list_unsubscribe: unsubscribe_url,
        list_unsubscribe_post: one_click_unsubscribe
    end

    def notify_creator_of_debate_scheduled(petition, signature)
      @petition, @signature = petition, signature
      mail to: @signature.email,
        subject: subject_for(:notify_creator_of_debate_scheduled),
        list_unsubscribe: unsubscribe_url,
        list_unsubscribe_post: one_click_unsubscribe
    end

    def notify_signer_of_debate_outcome(petition, signature)
      @petition, @debate_outcome, @signature = petition, petition.debate_outcome, signature

      if @debate_outcome.debated?
        subject = subject_for(:notify_signer_of_positive_debate_outcome)
      else
        subject = subject_for(:notify_signer_of_negative_debate_outcome)
      end

      mail to: @signature.email, subject: subject,
        list_unsubscribe: unsubscribe_url,
        list_unsubscribe_post: one_click_unsubscribe
    end

    def notify_creator_of_debate_outcome(petition, signature)
      @petition, @debate_outcome, @signature = petition, petition.debate_outcome, signature

      if @debate_outcome.debated?
        subject = subject_for(:notify_creator_of_positive_debate_outcome)
      else
        subject = subject_for(:notify_creator_of_negative_debate_outcome)
      end

      mail to: @signature.email, subject: subject,
        list_unsubscribe: unsubscribe_url,
        list_unsubscribe_post: one_click_unsubscribe
    end

    private

    def subject_for(key, options = {})
      I18n.t key, **(i18n_options.merge(options))
    end

    def signature_belongs_to_creator?
      @signature && @signature.creator?
    end

    def i18n_options
      {}.tap do |options|
        options[:scope] = :"petitions.emails.subjects"

        if defined?(@petition)
          options[:count] = @petition.signature_count
          options[:formatted_count] = number_to_delimited(@petition.signature_count)
          options[:action] = @petition.action
        end

        if defined?(@email)
          options[:subject] = @email.subject
        end

        if defined?(@mailshot)
          options[:subject] = @mailshot.subject
        end
      end
    end

    def unsubscribe_url
      "<#{unsubscribe_archived_signature_url(@signature, token: @signature.unsubscribe_token)}>"
    end

    def one_click_unsubscribe
      "List-Unsubscribe=One-Click"
    end
  end
end
