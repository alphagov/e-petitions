require 'tempfile'

class ArchivePetitionJob < ApplicationJob
  queue_as :high_priority

  def perform(petition)
    unless petition.archived? || parliament.petitions.exists?(petition.id)
      archived_petition = parliament.petitions.create! do |p|
        p.id = petition.id
        p.action = petition.action
        p.background = petition.background
        p.additional_details = petition.additional_details
        p.state = petition.state
        p.debate_state = petition.debate_state
        p.special_consideration = petition.special_consideration
        p.opened_at = petition.opened_at
        p.closed_at = petition.closed_at
        p.rejected_at = petition.rejected_at
        p.stopped_at = petition.stopped_at
        p.signature_count = petition.signature_count
        p.moderation_threshold_reached_at = petition.moderation_threshold_reached_at
        p.moderation_lag = petition.moderation_lag
        p.last_signed_at = petition.last_signed_at
        p.response_threshold_reached_at = petition.response_threshold_reached_at
        p.government_response_at = petition.government_response_at
        p.debate_threshold_reached_at = petition.debate_threshold_reached_at
        p.scheduled_debate_date = petition.scheduled_debate_date
        p.debate_outcome_at = petition.debate_outcome_at
        p.created_at = petition.created_at
        p.updated_at = petition.updated_at

        if receipt = petition.email_requested_receipt
          p.email_requested_for_government_response_at = receipt.government_response
          p.email_requested_for_debate_scheduled_at = receipt.debate_scheduled
          p.email_requested_for_debate_outcome_at = receipt.debate_outcome
          p.email_requested_for_petition_email_at = receipt.petition_email
        end

        if note = petition.note
          p.build_note do |n|
            n.details = note.details
            n.created_at = note.created_at
            n.updated_at = note.updated_at
          end
        end

        if rejection = petition.rejection
          p.build_rejection do |r|
            r.code = rejection.code
            r.details = rejection.details
            r.created_at = rejection.created_at
            r.updated_at = rejection.updated_at
          end
        end

        petition.emails.each do |email|
          p.emails.build do |e|
            e.subject = email.subject
            e.body = email.body
            e.sent_by = email.sent_by
            e.created_at = email.created_at
            e.updated_at = email.updated_at
          end
        end

        if government_response = petition.government_response
          p.build_government_response do |r|
            r.responded_on = government_response.responded_on
            r.summary = government_response.summary
            r.details = government_response.details
            r.created_at = government_response.created_at
            r.updated_at = government_response.updated_at
          end
        end

        if debate_outcome = petition.debate_outcome
          p.build_debate_outcome do |o|
            o.debated = debate_outcome.debated
            o.debated_on = debate_outcome.debated_on
            o.transcript_url = debate_outcome.transcript_url
            o.video_url = debate_outcome.video_url
            o.debate_pack_url = debate_outcome.debate_pack_url
            o.overview = debate_outcome.overview
            o.created_at = debate_outcome.created_at
            o.updated_at = debate_outcome.updated_at

            if debate_outcome.commons_image?
              tempfile = Tempfile.new("commons_image")
              debate_outcome.commons_image.copy_to_local_file(:original, tempfile.path)
              tempfile.rewind

              o.commons_image = tempfile
              o.commons_image_file_name = debate_outcome.commons_image_file_name
            end
          end
        end

        constituencies = petition.signatures_by_constituency
        unless constituencies.empty?
          p.signatures_by_constituency = Hash[constituencies.map { |c| [c.constituency_id, c.signature_count] }]
        end

        locations = petition.signatures_by_country
        unless locations.empty?
          p.signatures_by_country = Hash[locations.map { |l| [l.location_code, l.signature_count] }]
        end
      end

      ArchiveSignaturesJob.perform_later(petition, archived_petition)
    end
  end

  private

  def parliament
    Parliament.instance
  end
end
