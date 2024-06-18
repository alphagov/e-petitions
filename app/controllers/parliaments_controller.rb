class ParliamentsController < ApplicationController
  before_action :set_cors_headers, only: [:index], if: :json_request?

  def index
    @parliaments = Parliament.order(:period)

    respond_to do |format|
      format.json
    end
  end

  def show
    @parliament = Parliament.find_by(period: params[:period])

    respond_to do |format|
      format.json
    end
  end
end
