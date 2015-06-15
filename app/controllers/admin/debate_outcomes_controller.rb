class Admin::DebateOutcomesController < Admin::AdminController
  respond_to :html

  def show
    @petition = Petition.find(params[:petition_id])
    if @petition.can_have_debate_added?

    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
