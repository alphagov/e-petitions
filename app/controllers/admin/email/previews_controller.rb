class Admin::Email::PreviewsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_template

  layout false

  helper_method :ignore_email_header?
  helper_method :inline_preview?

  def show
    @email = @template.preview(inline_preview?)
    @headers = @email.header_fields

    respond_to do |format|
      format.html
    end
  end

  private

  def find_template
    @template = Email::Template.find(params[:template_id])
  end

  def ignored_headers
    %w[content-type mime-version]
  end

  def ignore_email_header?(header)
    ignored_headers.include?(header.downcase)
  end

  def inline_preview?
    params[:inline] == 'true'
  end
end
