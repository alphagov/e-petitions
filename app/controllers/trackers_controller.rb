class TrackersController < ApplicationController
  before_action :do_not_cache

  def show
    cookies.encrypted[form_token] = current_time

    respond_to do |format|
      format.gif
    end
  end

  private

  def form_token
    params[:id]
  end
end
