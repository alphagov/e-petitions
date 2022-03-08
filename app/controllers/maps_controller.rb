class MapsController < LocalizedController
  layout 'map'

  before_action :retrieve_petition, only: [:show]

  def show
  end

  private

  def retrieve_petition
    @petition = Petition.show.find(petition_id)
  end

  def petition_id
    Integer(params[:petition_id])
  rescue ArgumentError => e
    raise ActionController::BadRequest, "Invalid petition id: #{params[:petition_id]}"
  end
end
