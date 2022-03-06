module Anonymize
  extend ActiveSupport::Concern

  module ClassMethods
    def not_anonymized
      where(arel_table[:anonymized_at].eq(nil))
    end
  end

  def anonymized?
    anonymized_at?
  end

  def anonymize!(timestamp)
    return if anonymized?

    self.name = "Signature #{id}"
    self.email = "signature-#{id}@example.com"
    self.ip_address = "192.168.1.1"
    self.anonymized_at = timestamp

    if constituency_id && constituency
      self.postcode = constituency.example_postcode
    else
      self.postcode = nil
    end

    if postcode.blank? && united_kingdom?
      # Validations require a postcode for the UK so use the NHS
      # 'address not known' pseudo-postcode when we didn't find
      # an example postcode for the constituency:
      # https://adoxoblog.wordpress.com/2012/01/21/the-hitchhikers-guide-to-the-nhs/
      self.postcode = "ZZ993WZ"
    end

    save!
  end
end
