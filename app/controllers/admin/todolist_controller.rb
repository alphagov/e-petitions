class Admin::TodolistController < Admin::AdminController
  
  def index
    if current_user.is_a_sysadmin? or current_user.is_a_threshold?
      scope = Petition
    else
      scope = Petition.for_departments(current_user.departments)
    end
    @petitions = scope.for_state(Petition::SPONSORED_STATE).order(:created_at).paginate(:page => params[:page], :per_page => params[:per_page] || 20)
  end
end
