class Admin::EditorController < Admin::AdminController
  layout 'editor'

  def show
    respond_to do |format|
      format.html
    end
  end
end
