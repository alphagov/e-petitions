class Admin::Archived::NotesController < Admin::AdminController
  before_action :fetch_petition
  before_action :fetch_note

  rescue_from ActiveRecord::RecordNotUnique do
    @note = @petition.note(true) and update
  end

  def show
    render 'admin/archived/petitions/show'
  end

  def update
    if @note.update(note_params)
      redirect_to admin_archived_petition_url(@petition)
    else
      render 'admin/archived/petitions/show'
    end
  end

  private

  def fetch_note
    @note = @petition.note || @petition.build_note
  end

  def fetch_petition
    @petition = ::Archived::Petition.find(params[:petition_id])
  end

  def note_params
    params.require(:archived_note).permit(:details)
  end
end
