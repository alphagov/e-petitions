class MapsController < LocalizedController
  before_action :retrieve_petition
  before_action :redirect_to_gathering_support_url, if: :collecting_sponsors?
  before_action :redirect_to_moderation_info_url, if: :in_moderation?

  skip_forgery_protection

  def show
    respond_to do |format|
      format.html
      format.js
    end
  end

  protected

  def petition_id
    Integer(params[:petition_id])
  rescue ArgumentError => e
    raise ActionController::BadRequest, "Invalid petition id: #{params[:id]}"
  end

  def retrieve_petition
    @petition = Petition.show.find(petition_id)
  end

  def collecting_sponsors?
    @petition.collecting_sponsors?
  end

  def redirect_to_gathering_support_url
    redirect_to gathering_support_petition_url(@petition)
  end

  def in_moderation?
    @petition.in_moderation?
  end

  def redirect_to_moderation_info_url
    redirect_to moderation_info_petition_url(@petition)
  end
end
