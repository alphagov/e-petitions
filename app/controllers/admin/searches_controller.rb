class Admin::SearchesController < Admin::AdminController
  before_action :set_search_params

  def show
    if find_petition_by_id?
      find_petition_by_id
    elsif signature_search?
      find_signatures
    else
      find_petitions
    end
  end

  private

  def set_search_params
    @query = params.fetch(:q, '')
    @search_type = params.fetch(:search_type, "petition")
    @tag_filters = params.fetch(:tag_filters, [])
  end

  def find_petition_by_id?
    @query =~ /^\d+$/
  end

  def signature_search?
    @search_type == "signature"
  end

  def find_petition_by_id
    begin
      redirect_to admin_petition_url(Petition.find(@query.to_i))
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_petitions_url, alert: [:petition_not_found, query: @query.inspect]
    end
  end

  def find_signatures
    redirect_to(controller: 'admin/signatures', action: 'index', q: @query)
  end

  def find_petitions
    redirect_to(controller: 'admin/petitions', action: 'index', q: @query, tag_filters: @tag_filters)
  end
end
