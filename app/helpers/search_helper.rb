module SearchHelper
  def petition_search_lists(petition_search, params)
    search_list_links = Petition::SEARCHABLE_STATES.map do |state|
      link_text = petition_list_url_link_text(state.capitalize, petition_search.result_count_for_state(state))
      link_to(link_text.html_safe, petition_list_url(state, params))
    end
    safe_join(search_list_links)
  end

  private

  def petition_list_url(state, params)
    url_for(params.merge(:state => state, :page => nil, :order => nil, :sort => nil))
  end

  def petition_list_url_link_text(list_name, count)
    "#{list_name} (#{number_with_delimiter(count)})"
  end
end
