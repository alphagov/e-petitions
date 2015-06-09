module SearchHelper
  def petition_search_lists(petition_search, params)
    search_list_links = Petition::SEARCHABLE_STATES.map do |state|
      link_text = petition_list_url_link_text(state.capitalize, petition_search.result_count_for_state(state))
      link_to(link_text.html_safe, petition_list_url(state, params))
    end
    safe_join(search_list_links)
  end

  def will_paginate_petitions(collection_or_options = nil, options = {})
    options[:page_links] = false
    options[:previous_label] =
      "<span class='icon icon-paginate-previous paginate paginate-previous' aria-hidden='true'></span>
       <span class='paginate paginate-previous'>Previous</span>"
    options[:next_label] =
      "<span class='icon icon-paginate-next paginate paginate-next' aria-hidden='true'></span>
       <span class='paginate paginate-next'>Next</span>"
    will_paginate *[collection_or_options, options].compact
  end

  private

  def petition_list_url(state, params)
    url_for(params.merge(:state => state, :page => nil, :order => nil, :sort => nil))
  end

  def petition_list_url_link_text(list_name, count)
    "#{list_name} (#{number_with_delimiter(count)})"
  end
end
