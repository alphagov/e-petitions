require 'csv'

namespace :import do
  desc "Import archived petitions"
  task :archived_petitions => :environment do
    file = ENV['FILE']

    if file.blank?
      raise ArgumentError, "Please provide a CSV file to import using FILE=<file.csv>"
    end

    unless File.exist?(file)
      raise ArgumentError, "The CSV file #{file.inspect} doesn't exist"
    end

    rejection_reasons = {
      "no-action"  => "It did not have a clear statement explaining what action you want the government to take.",
      "duplicate"  => "There is already an e-petition about this issue.",
      "libellous"  => "E-petitions will not be accepted if they contain information which may be protected by an injunction or court order; contain material that is potentially confidential, commercially sensitive or which may cause personal distress or loss; include the names of individuals if they have been accused of a crime or information that may identify them; include the names of individual officials who work for public bodies, unless they are part of the senior management of those organisations; include the names of family members of elected representatives, eg MPs, or officials who work for public bodies.",
      "offensive"  => "E-petitions will not be accepted if they contain offensive, joke or nonsense content; use language which may cause offence, is provocative or extreme in its views; use wording that is impossible to understand; include statements that amount to advertisements.",
      "irrelevant" => "E-petitions cannot be used to request action on issues that are outside the responsibility of the government. This includes party political material; commercial endorsements including the promotion of any product, service or publication; issues that are dealt with by devolved bodies, eg The Scottish Parliament; correspondence on personal issues. E-petitions cannot be used for freedom of information requests.",
      "honours"    => "E-petitions cannot include information about honours or appointments. Find information about nominations for honours at https://www.gov.uk/honours.",
    }

    converters = [
      ->(value) { value == 'NULL' ? nil : value },
      ->(value) { value =~ /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/ ? Time.strptime(value + ' UTC', '%Y-%m-%d %H:%M:%S %Z') : value },
      ->(value) { value =~ /\A\d+\z/ ? Integer(value) : value }
    ]

    CSV.foreach(file, headers: true, converters: converters) do |row|
      if ArchivedPetition::STATES.include?(row['state'])
        petition = ArchivedPetition.find_or_initialize_by(id: row['id'])

        petition.title             = row['title']
        petition.description       = row['description']
        petition.response          = row['response']
        petition.state             = row['state']
        petition.opened_at         = row['open_at']
        petition.closed_at         = row['closed_at']
        petition.signature_count   = row['signature_count']

        if petition.rejected?
          if row['rejection_text'].blank?
            petition.reason_for_rejection = rejection_reasons[row['rejection_code']]
          else
            petition.reason_for_rejection = "#{rejection_reasons[row['rejection_code']]}\n\nThe following explanatory notes have been added:\n\n#{row['rejection_text']}"
          end
        end
      end

      petition.created_at = row['created_at']
      petition.updated_at = row['updated_at']

      petition.save!
    end
  end
end
