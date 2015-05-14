module Staged
  module Validations
    module SponsorDetails
      extend ActiveSupport::Concern

      included do
        before_validation :build_sponsors, on: :create

        validate :validate_number_of_sponsors, on: :create

        def build_sponsors
          sponsor_emails.each { |email| self.sponsors << Sponsor.new(email: email) }
        end

        def validate_number_of_sponsors
          unless sponsor_emails.uniq.count.between?(AppConfig.sponsor_count_min, AppConfig.sponsor_count_max)
            errors.add(:sponsor_emails, "Specify #{AppConfig.sponsor_count_min}-#{AppConfig.sponsor_count_max} unique sponsor emails for the petition")
          end
        end
      end
    end
  end
end
