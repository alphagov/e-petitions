class Admin::NotesController < Admin::AdminController
  before_action :fetch_petition
  before_action :fetch_note

  rescue_from ActiveRecord::RecordNotUnique do
    @note = @petition.reload_note and update
  end

  def show
    render 'admin/petitions/show'
  end

  def update
    if @note.update(note_params)
      redirect_to [:admin, @petition]
    else
      render 'admin/petitions/show'
    end
  end

  private

  def fetch_note
    @note = @petition.note || @petition.build_note
  end

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def note_params
    params.require(:note).permit(:details)
  end
end
