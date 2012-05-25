class Admin::SearchesController < Admin::AdminController

  def new
    @query = ""
  end

  def result
    @query = params[:search][:query]
    if (/^\d+$/ =~ @query)
      find_by_id(@query)
    else
      @signatures = Signature.for_email(@query).paginate(:page => params[:page], :per_page => 20)
    end
  end

  private
  def find_by_id(query)
    begin
      petition = Petition.find(query.to_i)
      redirect_to path_for_petition_state(petition)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Cannot find petition with id: #{query}"
      redirect_to new_admin_search_path
    end
  end

  def path_for_petition_state(petition)
    return admin_petition_path(petition) unless petition.editable_by?(current_user)
    return edit_admin_petition_path(petition) if petition.awaiting_moderation?

    if (petition.response_editable_by?(current_user))
      edit_response_admin_petition_path(petition)
    else
      edit_internal_response_admin_petition_path(petition)
    end
  end
end
