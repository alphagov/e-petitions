class TrackersController < ApplicationController
  include FormTracking

  before_action :fetch_petition
  before_action :verify_petition
  before_action :verify_form_token
  before_action :do_not_cache

  def show
    cookies.encrypted[form_token] = current_time

    respond_to do |format|
      format.gif
    end
  end

  private

  def petition_id
    @petition_id ||= Integer(params[:petition_id])
  end

  def fetch_petition
    @petition = Petition.visible.find(petition_id)
  end

  def verify_petition
    if @petition.closed_for_signing?
      raise ActionController::BadRequest, "Petition has been closed"
    end
  end

  def verify_form_token
    unless form_token == params[:id]
      raise ActionController::BadRequest, "The token in the session doesn't match the url token"
    end
  end
end
