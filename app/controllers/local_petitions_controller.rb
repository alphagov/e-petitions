require 'postcode_sanitizer'

class LocalPetitionsController < ApplicationController
  respond_to :html

  def index
    if sanitized_postcode.blank?
      render 'no_postcode_provided'
    else
      begin
        constituencies = ConstituencyApi::Client.constituencies(sanitized_postcode)
        if constituencies.any?
          @constituency = constituencies.first
          @petitions = Petition.popular_in_constituency(@constituency.id, 3)
        else
          render 'constituency_lookup_failed'
        end
      rescue ConstituencyApi::Error => e
        Rails.logger.error("Failed to fetch constituency - #{e}")
        render 'constituency_lookup_failed'
      end
    end
  end

  private

  def sanitized_postcode
    PostcodeSanitizer.call(params[:postcode])
  end
end
