class Admin::Archived::PetitionDetailsController < Admin::AdminController
  before_action :fetch_petition

  def show
  end

  def update
    if @petition.update(petition_params)
      redirect_to admin_archived_petition_url(@petition), notice: :petition_updated
    else
      render :show, alert: :petition_not_saved
    end
  end

  private

  def fetch_petition
    @petition = ::Archived::Petition.find(params[:petition_id])
  end

  def petition_attributes
    %i[
      action
      background
      additional_details
      committee_note
      special_consideration
      do_not_anonymize
    ]
  end

  def petition_params
    params.require(:archived_petition).permit(*petition_attributes)
  end
end
