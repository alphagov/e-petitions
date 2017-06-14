namespace :epets do
  namespace :migrations do
    desc "Copy legacy archived petition data to new columns"
    task archived_petitions: :environment do
      no_action    = /\AIt did not have a clear statement explaining what action you want the government to take\./
      honours      = /\APetitions cannot include information about honours or appointments\. Find information about nominations for honours at https:\/\/www\.gov\.uk\/honours\./
      duplicate    = /\AThere is already a petition about this issue\./
      irrelevant   = /\APetitions cannot be used to request action on issues that are outside the responsibility of the government. This includes party political material; commercial endorsements including the promotion of any product, service or publication; issues that are dealt with by devolved bodies, eg The Scottish Parliament; correspondence on personal issues. E-petitions cannot be used for freedom of information requests./
      notes_added  = /The following explanatory notes have been added:/
      petition_url = /http:\/\/submissions.epetitions.direct.gov.uk\/petitions\/(\d+)/

      cleaner = lambda do |petition, pattern|
        petition.reason_for_rejection.dup.tap do |reason|
          reason.sub!(pattern, '')
          reason.sub!(notes_added, '')
          reason.gsub!(petition_url, 'https://petition.parliament.uk/archived/petitions/\1')
          reason.strip!
          reason.sub!(/\A[^a-zA-Z0-9]+/, '')
          reason.sub!(/\A\w/) { |match| match.upcase }
        end
      end

      Archived::Petition.find_each do |petition|
        Archived::Petition.transaction do
          petition.action = petition.title

          # Move decription into the additional details field. Whilst this
          # isn't strictly correct, the background field is limited to 300
          # characters so we'll automatically display additional details if
          # the background is blank.
          petition.additional_details = petition.description

          # There was no moderation for the original e-petitions website
          petition.moderation_threshold_reached_at = petition.created_at

          if petition.opened_at?
            # No way of knowing this so just set it to the closing date/time
            petition.last_signed_at = petition.closed_at

            # Synthesize threshold timestamps based upon a linear interpolation
            # of when they got to halfway to the threshold. This should weight
            # the threshold timestamp to earlier in the petition's lifespan to
            # take account of the long tail effect of petitions. We need these
            # so that the state filters can be extended to include further scopes
            # such as responded and debated.
            #
            # More complicated modelling is not possible since it all depends on
            # when the petition goes viral (if at all).
            duration = petition.closed_at - petition.opened_at

            if petition.signature_count >= 10000
              fraction = Rational(5000, petition.signature_count)
              petition.response_threshold_reached_at = petition.opened_at + duration * fraction
            end

            if petition.signature_count >= 100000
              fraction = Rational(50000, petition.signature_count)
              petition.debate_threshold_reached_at = petition.opened_at + duration * fraction
            end
          end

          if petition.response?
            government_response = petition.government_response || petition.build_government_response
            government_response.summary = ""
            government_response.details = petition.response
            government_response.save!

            if petition.signature_count > 10000
              # Assume that the petition got a government response one month after it
              petition.government_response_at = petition.response_threshold_reached_at + 1.month
            else
              # If the government responded without passing the threshold
              # assume that it was done after the petition was closed.
              petition.government_response_at = petition.closed_at + 1.month
            end
          end

          if petition.reason_for_rejection?
            rejection = petition.rejection || petition.build_rejection

            case petition.reason_for_rejection
            when no_action
              rejection.code = "no-action"
              rejection.details = cleaner.call(petition, no_action).presence
            when honours
              rejection.code = "honours"
              rejection.details = cleaner.call(petition, honours).presence
            when duplicate
              rejection.code = "duplicate"
              rejection.details = cleaner.call(petition, duplicate).presence
            when irrelevant
              rejection.code = "irrelevant"
              rejection.details = cleaner.call(petition, irrelevant).presence
            else
              raise RuntimeError, "Unrecognised rejection reason: #{petition.reason_for_rejection.inspect}"
            end

            rejection.save!

            # Assume that the updated_at timestamp is when the petition was rejected
            petition.rejected_at = petition.updated_at
          end

          # Set default values for new columns
          petition.debate_state = "pending"
          petition.special_consideration = false

          petition.save!
        end

        $stdout.puts "Migrated #{petition.id} - #{petition.title}"
      end
    end
  end
end
