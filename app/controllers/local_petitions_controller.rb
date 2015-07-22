require 'postcode_sanitizer'

class LocalPetitionsController < ApplicationController
  respond_to :html

  before_action :sanitize_postcode
  before_action :find_constituency, if: :postcode?
  before_action :find_petitions, if: :constituency?

  def index
    respond_with(@petitions)
  end

  private

  def sanitize_postcode
    @postcode = PostcodeSanitizer.call(params[:postcode])
  end

  def postcode?
    @postcode.present?
  end

  def find_constituency
    @constituency = ConstituencyApi.constituency(@postcode)
  end

  def constituency?
    @constituency.present?
  end

  def find_petitions
    @petitions = Petition.popular_in_constituency(@constituency.id, 50)
  end
end
