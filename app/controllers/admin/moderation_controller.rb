class Admin::ModerationController < Admin::AdminController
  before_action :fetch_petition

  def update
    if @petition.moderate(moderation_params)
      send_notifications
      redirect_to [:admin, @petition]
    else
      render 'admin/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = Petition.todo_list.find(params[:petition_id])
  end

  def moderation_params
    params.require(:petition).permit(:moderation, rejection: [:code, :details])
  end

  def send_notifications
    NotifyEveryoneOfModerationDecisionJob.perform_later(@petition)
  end
end
