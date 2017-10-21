class Admin::SearchesController < Admin::AdminController
  def show
    if petition_search?
      redirect_to admin_petitions_url(search_params)
    elsif signature_search?
      redirect_to admin_signatures_url(search_params)
    else
      redirect_to admin_root_url, notice: "Sorry, we didn't understand your query"
    end
  end

  private

  def petition_search?
    params[:type] == "petition"
  end

  def signature_search?
    params[:type] == "signature"
  end

  def search_params
    if petition_search?
      if params[:match] == "none"
        params.slice(:q, :match)
      elsif params[:tags].present?
        params.slice(:q, :tags, :match)
      else
        params.slice(:q)
      end
    elsif signature_search?
      params.slice(:q)
    else
      {}
    end
  end
end
