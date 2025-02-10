module PetitionHelper
  def public_petition_facets_with_counts(petition_search)
    petition_search.facets.slice(*public_petition_facets)
  end

  def current_threshold(petition)
    if petition.debate_threshold_reached_at? || petition.debate_outcome_at?
      petition.threshold_for_debate
    elsif petition.response_threshold_reached_at? || petition.government_response_at?
      petition.threshold_for_debate
    else
      petition.threshold_for_response
    end
  end

  def signatures_threshold_percentage(petition)
    threshold = current_threshold(petition).to_f
    percentage = petition.signature_count / threshold * 100
    if percentage > 100
      percentage = 100
    elsif percentage < 1
      percentage = 1
    end
    number_to_percentage(percentage, precision: 2)
  end

  def petition_list_header
    @_petition_list_header ||= if @petitions.semantic_search?
      t(:"semantic_html", scope: :"petitions.list_headers", query: @petitions.url_safe_query, default: "")
    else
      t(:"#{@petitions.scope}_html", scope: :"petitions.list_headers", query: @petitions.url_safe_query, default: "")
    end
  end

  def petition_list_header?
    petition_list_header.present?
  end

  def reveal_government_response?
    params[:reveal_response] == "yes"
  end
end
