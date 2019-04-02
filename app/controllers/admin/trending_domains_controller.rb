class Admin::TrendingDomainsController < Admin::AdminController
  before_action :fetch_petition
  before_action :fetch_trending_domains

  def index
    respond_to do |format|
      format.html
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def fetch_trending_domains
    @trending_domains = @petition.trending_domains.search(params[:q], page: params[:page])
  end
end
