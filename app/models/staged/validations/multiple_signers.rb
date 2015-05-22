module Staged
  module Validations
    module MultipleSigners
      extend ActiveSupport::Concern

      included do
        validate do |signature|
          matcher = ::Signature.where(:encrypted_email => signature.encrypted_email, :petition_id => signature.petition_id)
          matcher = matcher.where("signatures.id != ?", signature.id) unless signature.new_record?
          existing_email_address_count = matcher.count
          next if existing_email_address_count == 0
          if existing_email_address_count > 1
            signature.errors.add(:email, 'This email address is not allowed to sign this petition again')
            next
          end
          existing_signature =  matcher.first
          if (existing_signature.name.strip.downcase == signature.name.strip.downcase)
            signature.errors.add(:email, 'You cannot sign this petition again')
            next
          end
          if (existing_signature.postcode.gsub(/\s+/,'').downcase !=
              signature.postcode.gsub(/\s+/,'').downcase)
            signature.errors.add(:email, 'This email address is not allowed to sign this petition again')
            next
          end
        end
      end
    end
  end
end
