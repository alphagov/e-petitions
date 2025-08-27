class Admin::SearchesController < Admin::AdminController
  def show
    if petition_search?
      redirect_to admin_petitions_url(search_params)
    elsif signature_search?
      redirect_to admin_signatures_url(search_params)
    else
      redirect_to admin_root_url, notice: "Sorry, we didn’t understand your query"
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
      permitted_params = [:q]
      permitted_nested_params = {}

      if params[:dmatch] == "none"
        permitted_params << :dmatch
      elsif params[:depts].present?
        permitted_params << :dmatch
        permitted_nested_params[:depts] = []
      end

      if params[:tmatch] == "none"
        permitted_params << :tmatch
      elsif params[:tags].present?
        permitted_params << :tmatch
        permitted_nested_params[:tags] = []
      end

      params.permit(*permitted_params, permitted_nested_params)
    elsif signature_search?
      params.permit(:q, :window)
    else
      {}
    end
  end
end
