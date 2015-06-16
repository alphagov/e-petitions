class Admin::PetitionDetailsController < Admin::AdminController
  respond_to :html
  before_action :find_petition

  def show
    if @petition.in_todo_list?
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def update
  end

  private

  def find_petition
    @petition = Petition.find(params[:petition_id])
  end
end