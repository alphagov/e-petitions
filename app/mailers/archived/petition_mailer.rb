module Archived
  class PetitionMailer < ApplicationMailer
    include ActiveSupport::NumberHelper

    def notify_signer_of_debate_scheduled(petition, signature)
      @petition, @signature = petition, signature

      mail to: @signature.email,
        subject: subject_for(:notify_signer_of_debate_scheduled),
        list_unsubscribe: unsubscribe_url
    end

    def notify_creator_of_debate_scheduled(petition, signature)
      @petition, @signature = petition, signature
      mail to: @signature.email,
        subject: subject_for(:notify_creator_of_debate_scheduled),
        list_unsubscribe: unsubscribe_url
    end

    private

    def subject_for(key, options = {})
      I18n.t key, i18n_options.merge(options)
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
      end
    end

    def unsubscribe_url
      "<#{unsubscribe_archived_signature_url(@signature, token: @signature.unsubscribe_token)}>"
    end
  end
end
