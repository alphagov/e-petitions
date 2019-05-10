class Admin::DomainsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :fetch_domains
  before_action :build_domain, only: %i[new create]
  before_action :find_domain, only: %i[edit update destroy]

  def index
    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @domain.save
      redirect_to admin_domains_url, notice: :domain_created
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
    if @domain.update(domain_params)
      redirect_to admin_domains_url, notice: :domain_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def destroy
    if @domain.destroy
      redirect_to admin_domains_url, notice: :domain_deleted
    else
      redirect_to admin_domains_url, alert: :domain_not_deleted
    end
  end

  private

  def fetch_domains
    @domains = Domain.by_name.paginate(page: params[:page], per_page: 25)
  end

  def find_domain
    @domain = Domain.find(params[:id])
  end

  def build_domain
    @domain = Domain.new(domain_params)
  end

  def domain_params
    if params.key?(:domain)
      params.require(:domain).permit(*domain_attributes)
    else
      {}
    end
  end

  def domain_attributes
    %i[name strip_characters strip_extension aliased_domain]
  end
end
