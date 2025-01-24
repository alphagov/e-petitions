class Admin::PagesController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_pages
  before_action :find_page, only: %i[edit update]

  def index
    respond_to do |format|
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @page.update(page_params)
      redirect_to admin_pages_url, notice: :page_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  private

  def find_pages
    @pages = Page.by_slug
  end

  def find_page
    @page = Page.find_by!(slug: params[:slug])
  end

  def page_params
    params.require(:page).permit(*page_attributes)
  end

  def page_attributes
    %i[title content]
  end
end
