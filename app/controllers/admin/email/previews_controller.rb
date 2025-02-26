class Admin::Email::PreviewsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_template

  layout false

  def show
    @email = @template.preview
    @headers = @email.header_fields

    respond_to do |format|
      format.html
    end
  end

  private

  def find_template
    @template = Email::Template.find(params[:template_id])
  end
end
