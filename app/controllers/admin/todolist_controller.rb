class Admin::TodolistController < Admin::AdminController
  def index
    if params[:petition] == 'collecting_sponsors'
      petitions = Petition.collecting_sponsors
    else
      petitions = Petition.in_moderation
    end
    @petitions = petitions.by_oldest.paginate(page: params[:page], per_page: 50)
  end
end

