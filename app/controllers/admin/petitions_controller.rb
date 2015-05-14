class Admin::PetitionsController < Admin::AdminController
  before_filter :assign_departments, :only => [:edit, :update]

  respond_to :html

  def index
    if current_user.is_a_sysadmin? or current_user.is_a_threshold?
      @petitions = Petition
    else
      @petitions = Petition.for_departments(current_user.departments)
    end
    @petitions = @petitions.moderated.order(:signature_count)
    @petitions = @petitions.for_state(params[:state]) unless params[:state].blank?
    @petitions = @petitions.paginate(:page => params[:page], :per_page => params[:per_page] || 20)
  end

  def show
    @petition = Petition.find(params[:id])
  end

  def edit
    @petition = Petition.for_state(Petition::SPONSORED_STATE).find(params[:id])
  end

  def update
    @petition = Petition.for_state(Petition::SPONSORED_STATE).find(params[:id])
    user_action = params['commit']
    case user_action
      when 'Publish this petition'
        publish
      when 'Re-assign'
        reassign
      when 'Reject'
        reject
      else
        raise "Don't know how to do this action"
    end

    respond_with @petition, :location => admin_root_path
  end

  def threshold
    @petitions = Petition.threshold.order(:signature_count).paginate(:page => params[:page], :per_page => params[:per_page] || 20)
  end

  def edit_response
    @petition = Petition.find(params[:id])
  end

  def update_response
    @petition = Petition.find(params[:id])
    @petition.internal_response = params[:petition][:internal_response]
    @petition.response_required = params[:petition][:response_required]
    @petition.response = params[:petition][:response]
    @petition.email_signees = params[:petition][:email_signees] == '1'
    if @petition.save
      # if email signees has been selected then set up a delayed job to email out to all signees who opted in
      if @petition.email_signees
        # run the job at some random point beween midnight and 4 am
        requested_at = Time.zone.now
        @petition.update_attribute(:email_requested_at, requested_at)
        Delayed::Job.enqueue EmailThresholdResponseJob.new(@petition.id, requested_at, Petition, PetitionMailer), :run_at => 1.day.from_now.at_midnight + rand(240).minutes + rand(60).seconds
      end

      redirect_to threshold_admin_petitions_path
    else
      render :edit_response
    end
  end

  def take_down
    @petition = Petition.find(params[:id])
    reject
    respond_with @petition, :location => admin_petitions_path
  end

  def edit_internal_response
    @petition = Petition.find(params[:id])
  end

  def update_internal_response
    @petition = Petition.find(params[:id])
    @petition.internal_response = params[:petition][:internal_response]
    @petition.response_required = params[:petition][:response_required]
    @petition.save!
    redirect_to admin_petitions_path
  end
  
  protected
  
  def publish
    @petition.state = Petition::OPEN_STATE
    @petition.open_at = Time.zone.now
    @petition.closed_at = @petition.duration.to_i.months.from_now
    @petition.save!
    PetitionMailer.notify_creator_that_petition_is_published(@petition.creator_signature).deliver_now
  end

  def reassign
    department = Department.find(params[:petition][:department_id])
    @petition.reassign!(department)
  end

  def reject
    @petition.rejection_code = params[:petition][:rejection_code]
    @petition.rejection_text = params[:petition][:rejection_text]

    # if a petition is rejected for a reason that means it should be hidden, then set the state accordingly
    reason = RejectionReason.for_code(@petition.rejection_code)
    if reason and ! reason.published
      @petition.state = Petition::HIDDEN_STATE
    else
      @petition.state = Petition::REJECTED_STATE
    end

    # send rejection email
    if @petition.save
      PetitionMailer.notify_creator_that_petition_is_rejected(@petition.creator_signature).deliver_now
    end
  end
end
