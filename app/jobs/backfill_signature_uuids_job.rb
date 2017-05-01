require 'active_support/core_ext/digest/uuid'

class BackfillSignatureUuidsJob < ApplicationJob
  queue_as :low_priority

  def perform
    Signature.find_each do |signature|
      next if signature.uuid?

      if signature.email?
        signature.update_uuid
      end
    end
  end
end
