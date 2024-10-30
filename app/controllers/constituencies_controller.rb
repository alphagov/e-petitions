class ConstituenciesController < ApplicationController
  before_action :set_cors_headers, only: [:index], if: :json_request?
  before_action :fetch_parliament, only: [:index]

  def index
    @constituencies = @parliament.constituencies.by_ons_code

    respond_to do |format|
      format.json
    end
  end

  private

  def fetch_parliament
    case params[:period]
    when Parliament::PERIOD_FORMAT
      @parliament = Parliament.archived.find_by!(period: params[:period])
    else
      @parliament = Parliament.instance
    end
  end
end
