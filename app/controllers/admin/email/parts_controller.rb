class Admin::Email::PartsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_template

  layout false

  helper_method :inline_preview?

  def show
    @email = @template.preview(inline_preview?)

    if text_part?
      render plain: text_part
    else
      render html: html_part
    end
  end

  private

  def part
    params.fetch(:part)
  end

  def text_part?
    part == 'text'
  end

  def text_part
    @email.text_part.decoded
  end

  def html_part
    @email.html_part.decoded.html_safe
  end

  def find_template
    @template = Email::Template.find(params[:template_id])
  end

  def inline_preview?
    params[:inline] == 'true'
  end
end
