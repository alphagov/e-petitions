class ConstituenciesController < ApplicationController
  before_action :set_cors_headers, only: [:index], if: :json_request?

  def index
    @constituencies = Constituency.by_ons_code

    respond_to do |format|
      format.json
    end
  end
end
