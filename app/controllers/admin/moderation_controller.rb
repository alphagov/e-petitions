class Admin::ModerationController < Admin::AdminController
  before_action :fetch_petition
  before_action :require_moderator, unless: :petition_rejected?
  before_action :require_sysadmin, if: :petition_rejected?

  def update
    if @petition.moderate(moderation_params)
      send_notifications
      redirect_to [:admin, @petition], notice: :petition_updated
    else
      render 'admin/petitions/show', alert: :petition_not_saved
    end
  end

  private

  def fetch_petition
    @petition = Petition.moderatable.find(params[:petition_id])
  end

  def moderation_params
    params.require(:petition).permit(:moderation, rejection: [:code, :details, :hidden])
  end

  def send_notifications
    if send_email_to_creator_and_sponsors?
      NotifyEveryoneOfModerationDecisionJob.perform_later(@petition)
    end
  end

  def send_email_to_creator_and_sponsors?
    params.key?(:save_and_email)
  end

  def petition_rejected?
    @petition.rejection?
  end
end
