class Admin::SearchesController < Admin::AdminController

  def new
    @query = ""
  end

  def result
    @query = params[:search][:query]
    if is_number?(@query)
      find_petition_by_id(@query)
    elsif is_email?(@query)
      find_signatures_by_email(@query)
    else
      find_petitions_by_keyword(@query)
    end
  end

  private
  def find_petition_by_id(query)
    begin
      petition = Petition.find(query.to_i)
      redirect_to url_for_petition_state(petition)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Cannot find petition with id: #{query}"
      redirect_to new_admin_search_url
    end
  end

  def find_signatures_by_email(query)
    @signatures = Signature.for_email(query).paginate(:page => params[:page], :per_page => 20)
  end

  def find_petitions_by_keyword(query)
    redirect_to(controller: 'admin/petitions', action: 'index', q: query)
  end
  
  def url_for_petition_state(petition)
    return admin_petition_url(petition) unless petition.editable_by?(current_user)
    return admin_petition_url(petition) if petition.awaiting_moderation?

    if (petition.response_editable_by?(current_user))
      edit_response_admin_petition_url(petition)
    end
  end

  def is_number?(query)
    /^\d+$/ =~ query
  end

  def is_email?(query)
    query.include?('@')
  end
end
