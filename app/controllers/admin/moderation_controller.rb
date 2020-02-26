class Admin::ModerationController < Admin::AdminController
  before_action :fetch_petition

  def update
    if @petition.moderate(moderation_params)
      send_notifications
      redirect_to [:admin, @petition], notice: :petition_updated
    else
      render 'admin/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = Petition.todo_list.find(params[:petition_id])
  end

  def moderation_params
    params.require(:petition).permit(:moderation, rejection: [:code, :details_en, :details_cy])
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
