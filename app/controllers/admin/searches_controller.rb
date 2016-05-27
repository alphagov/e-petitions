class Admin::SearchesController < Admin::AdminController

  def show
    if query_is_number?
      find_petition_by_id
    elsif query_is_email?
      find_signatures_by_email
    elsif query_is_name?
      find_signatures_by_name
    elsif query_is_tag?
      find_petitions_by_tag
    else
      find_petitions_by_keyword
    end
  end

  private
  def query
    @query ||= params.fetch(:q, '')
  end

  def name
    @name ||= @query.gsub(/\A"|"\Z/, '')
  end

  def tag
    @tag ||= @query.gsub(/\A\[|\]\Z/, '')
  end

  def find_petition_by_id
    begin
      redirect_to admin_petition_url(Petition.find(query.to_i))
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_petitions_url, alert: "Cannot find petition with id: #{query}"
    end
  end

  def find_signatures_by_email
    @signatures = Signature.for_email(query).paginate(page: params[:page], per_page: 50)
  end

  def find_signatures_by_name
    @signatures = Signature.for_name(name).paginate(page: params[:page], per_page: 50)
  end

  def find_petitions_by_keyword
    redirect_to(controller: 'admin/petitions', action: 'index', q: query)
  end

  def find_petitions_by_tag
    redirect_to(controller: 'admin/petitions', action: 'index', t: tag)
  end

  def query_is_number?
    /^\d+$/ =~ query
  end

  def query_is_email?
    query.include?('@')
  end

  def query_is_name?
    query.starts_with?('"') && query.ends_with?('"')
  end

  def query_is_tag?
    query.starts_with?('[') && query.ends_with?(']')
  end
end
