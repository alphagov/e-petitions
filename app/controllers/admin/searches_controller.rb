class Admin::SearchesController < Admin::AdminController

  def show
    if signature_search?
      perform_signature_search
    elsif find_petition_by_id?
      find_petition_by_id
    else
      find_petitions
    end
  end

  private

  def query
    @query ||= params.fetch(:q, '')
  end

  def search_type
    @search_type ||= params.fetch(:search_type, "keyword")
  end

  def tag_filters
    @tag_filters ||= params.fetch(:tag_filters, [])
  end

  def find_petition_by_id
    begin
      redirect_to admin_petition_url(Petition.find(query.to_i))
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_petitions_url, alert: [:petition_not_found, query: query.inspect]
    end
  end

  def find_petition_by_id?
    search_type == "petition_id"
  end

  def find_signatures(query_method)
    @signatures = Signature.send(query_method, query).paginate(page: params[:page], per_page: 50)
  end

  def find_petitions
    redirect_to(controller: 'admin/petitions', action: 'index', q: query, tag_filters: tag_filters)
  end

  def signature_search?
    search_type == "sig_name" || search_type == "sig_email" || search_type == "ip_address"
  end

  def perform_signature_search
    case search_type
    when "sig_name"
      find_signatures(:for_name)
    when "sig_email"
      find_signatures(:for_email)
    when "ip_address"
      find_signatures(:for_ip)
    end
  end
end
