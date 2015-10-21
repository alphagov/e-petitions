module Staged
  module Validations
    module Email
      extend ActiveSupport::Concern

      included do
        validates :email, presence: true, format: { with: EMAIL_REGEX, allow_blank: true }

        validate do
          errors.add :email, :disposable if disposable_domain?
        end
      end

      private

      def disposable_domain?
        return false unless email?

        begin
          disposable_domains.include?(parsed_email.domain)
        rescue Mail::Field::ParseError
          false
        end
      end

      def parsed_email
        Mail::Address.new(email)
      end

      def disposable_domains
        Rails.application.config.x.disposable_domains
      end
    end
  end
end
