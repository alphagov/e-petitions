class Admin::ModerationController < Admin::AdminController
  respond_to :html

  def update
    @petition = Petition.todo_list.find(params[:petition_id])
    user_action = params['moderation']
    case user_action
    when 'approve'
      approve_petition
    when 'reject'
      reject_petition
    else
      @petition.errors.add(:base, 'Must choose to approve or reject')
    end

    if @petition.errors.any?
      # NOTE: reset the state if the save failed, so it's still
      # "in_todolist?" - a question that will be asked by the view
      @petition.state = @petition.state_was
      render 'admin/petitions/show'
    else
      redirect_to admin_petition_path(@petition)
    end
  end

  private
  def approve_petition
    @petition.publish!
    PetitionMailer.notify_creator_that_petition_is_published(@petition.creator_signature).deliver_now
  end

  def reject_petition
    if @petition.reject(rejection_params)
      PetitionMailer.petition_rejected(@petition).deliver_now
    end
  end

  def rejection_params
    params.require(:petition).permit(:rejection_code, :rejection_text)
  end

end
