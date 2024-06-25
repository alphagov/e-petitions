class ParliamentsController < ApplicationController
  before_action :set_cors_headers, if: :json_request?

  def index
    @parliaments = Parliament.archived.order(:period)

    respond_to do |format|
      format.json
    end
  end

  def show
    @parliament = Parliament.archived.find_by!(period: params[:period])

    respond_to do |format|
     format.json
    end
  end
end
