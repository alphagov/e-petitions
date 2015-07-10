class Admin::ModerationController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition

  def update
    if @petition.moderate(moderation_params)
      if @petition.published?
        send_published_email
      elsif @petition.rejected? || @petition.hidden?
        send_rejected_email
      end

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

  def send_published_email
    PetitionMailer.notify_creator_that_petition_is_published(@petition.creator_signature).deliver_later

    @petition.sponsor_signatures.each do |signature|
      PetitionMailer.notify_sponsor_that_petition_is_published(signature).deliver_later
    end
  end

  def send_rejected_email
    PetitionMailer.petition_rejected(@petition).deliver_now
  end
end
