class Admin::TakeDownController < Admin::AdminController
  before_action :require_moderator
  before_action :fetch_petition

  def show
    render 'admin/petitions/show'
  end

  def update
    if @petition.moderate(moderation_params)
      send_notifications
      redirect_to [:admin, @petition]
    else
      render 'admin/petitions/show', alert: :petition_not_taken_down
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def moderation_params
    rejection_params.merge(moderation: "reject")
  end

  def rejection_params
    params.require(:petition).permit(*rejection_attributes)
  end

  def rejection_attributes
    [ rejection: [:code, :details, :hidden] ]
  end

  def send_notifications
    if send_email_to_creator_and_sponsors?
      NotifyEveryoneOfModerationDecisionJob.perform_later(@petition)
    end
  end

  def send_email_to_creator_and_sponsors?
    params.key?(:save_and_email)
  end
end
