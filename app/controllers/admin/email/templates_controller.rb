class Admin::Email::TemplatesController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_templates, only: [:index]
  before_action :find_template, only: [:edit, :update, :destroy, :activate, :deactivate]
  before_action :build_template, only: [:new, :create]
  before_action :destroy_template, only: [:destroy]

  def index
    respond_to do |format|
      format.html
      format.yaml
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @template.save
      redirect_to preview_url, notice: :email_template_created
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @template.update(template_params)
      redirect_to preview_url, notice: :email_template_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def destroy
    redirect_to index_url, notice: :email_template_deleted
  end

  def activate
    if @template.activate
      redirect_to index_url, notice: :email_template_activated
    else
      redirect_to index_url, notice: :email_template_not_activated
    end
  end

  def activate_all
    Email::Template.activate

    redirect_to index_url, notice: :email_templates_activated
  end

  def deactivate
    if @template.deactivate
      redirect_to index_url, notice: :email_template_deactivated
    else
      redirect_to index_url, notice: :email_template_not_deactivated
    end
  end

  def deactivate_all
    Email::Template.deactivate

    redirect_to index_url, notice: :email_templates_deactivated
  end

  private

  def find_templates
    @templates = Email::Template.search(params)
  end

  def find_template
    @template = Email::Template.find(params[:id])
  end

  def build_template
    @template = Email::Template.new(template_params)
  end

  def destroy_template
    @template.destroy
  end

  def template_params
    if params.key?(:template)
      params.require(:template).permit(:name, :subject, :content, :active)
    else
      {}
    end
  end

  def index_url
    admin_email_templates_url
  end

  def preview_url
    admin_email_template_preview_url(@template, inline: 'true')
  end
end
