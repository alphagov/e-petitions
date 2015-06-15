class Admin::DebateOutcomesController < Admin::AdminController
  respond_to :html

  def show
    @petition = Petition.find(params[:petition_id])
    if @petition.open? || @petition.closed?

    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
