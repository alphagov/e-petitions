class Admin::PetitionsController < Admin::AdminController
  respond_to :html

  def index
    @petitions = Petition.selectable.order(:signature_count)
    @petitions = @petitions.for_state(params[:state]) unless params[:state].blank?
    @petitions = @petitions.paginate(:page => params[:page], :per_page => params[:per_page] || 20)
  end

  def show
    @petition = Petition.find(params[:id])
  end

  def edit
    @petition = Petition.todo_list.find(params[:id])
  end

  def update
    @petition = Petition.todo_list.find(params[:id])
    user_action = params['commit']
    case user_action
      when 'Publish this petition'
        publish
      when 'Reject'
        reject
      else
        raise "Don't know how to do this action"
    end

    respond_with @petition, :location => admin_root_url
  end

  def threshold
    @petitions = Petition.threshold.order(:signature_count).paginate(:page => params[:page], :per_page => params[:per_page] || 20)
  end

  def edit_response
    @petition = Petition.find(params[:id])
  end

  def update_response
    @petition = Petition.find(params[:id])
    if @petition.update_attributes(params_for_update_response)
      # if email signees has been selected then set up a delayed job to email out to all signees who opted in
      if @petition.email_signees
        # run the job at some random point beween midnight and 4 am
        EmailThresholdResponseJob.run_later_tonight(@petition)
      end

      redirect_to admin_petitions_url
    else
      render :edit_response
    end
  end

  def assign_email_signees_param
    return unless params[:petition]
    params[:petition][:email_signees] = params[:petition][:email_signees] == '1'
  end

  def params_for_update_response
    assign_email_signees_param
    params.
      require(:petition).
      permit(:internal_response, :response_required, :response, :response_summary, :email_signees)
  end

  def edit_scheduled_debate_date
    fetch_petition_for_scheduled_debate_date
  end

  def update_scheduled_debate_date
    fetch_petition_for_scheduled_debate_date
    if @petition.update(update_scheduled_debate_date_params)
      redirect_to admin_petition_path(@petition), notice: "Scheduled debate date was successfully updated."
    else
      render :edit_scheduled_debate_date
    end
  end

  def take_down
    @petition = Petition.find(params[:id])
    reject
    respond_with @petition, :location => admin_petitions_url
  end

  protected

  def fetch_petition_for_scheduled_debate_date
    @petition = Petition.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @petition.can_have_debate_added?
  end

  def publish
    @petition.publish!
    PetitionMailer.notify_creator_that_petition_is_published(@petition.creator_signature).deliver_now
  end

  def reject
    if @petition.reject(rejection_params)
      PetitionMailer.petition_rejected(@petition).deliver_now
    end
  end

  def rejection_params
    params.require(:petition).permit(:rejection_code, :rejection_text)
  end

  def update_scheduled_debate_date_params
    params.require(:petition).permit(:scheduled_debate_date)
  end
end
