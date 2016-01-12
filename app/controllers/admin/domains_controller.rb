class Admin::DomainsController < Admin::AdminController
  before_filter :require_sysadmin
  before_filter :retrieve_domain, only: [:allow, :block]

  def index
    @domains = Domain.watchlist(rate: rate, limit: limit)
  end

  def search
    @domains = Domain.search(params[:q], limit: limit)
  end

  def create
    begin
      Domain.create!(name: params[:name])
      redirect_to admin_domains_url, notice: "Domain successfully created"
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_domains_url, alert: "Domain could not be created - please contact support"
    end
  end

  def allow
    begin
      @domain.allow!
      redirect_to admin_domains_url, notice: "Domain successfully whitelisted"
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_domains_url, alert: "Domain could not be whitelisted - please contact support"
    end
  end

  def block
    begin
      @domain.block!
      redirect_to admin_domains_url, notice: "Domain successfully blocked"
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_domains_url, alert: "Domain could not be blocked - please contact support"
    end
  end

  protected

  def retrieve_domain
    @domain = Domain.find(params[:id])
  end

  def rate
    [params[:rate].to_i, 0].max
  end

  def limit
    [[params[:size].to_i, 50].min, 10].max
  end
end
