class Admin::Archived::NotesController < Admin::AdminController
  before_action :fetch_petition
  before_action :fetch_note

  rescue_from ActiveRecord::RecordNotUnique do
    @note = @petition.reload_note and update
  end

  def show
    render 'admin/archived/petitions/show'
  end

  def update
    if @note.update(note_params)
      respond_to do |format|
        format.html { redirect_to admin_archived_petition_url(@petition) }
        format.json { render json: { updated: true } }
      end
    else
      respond_to do |format|
        format.html { render 'admin/archived/petitions/show', alert: :petition_not_updated }
        format.json { render json: { updated: false } }
      end
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
