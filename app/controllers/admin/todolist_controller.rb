class Admin::TodolistController < Admin::AdminController
  
  def index
    @petitions = Petition.for_state(Petition::VALIDATED_STATE).order(:created_at).paginate(:page => params[:page], :per_page => params[:per_page] || 20)
  end
end
