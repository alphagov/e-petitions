module SearchHelper
  def search_count_for(state)
    count = @petition_search.state_counts[state]
    "<span class='count'>(#{number_with_delimiter(count)})</span>"
  end

  def sort_link_tag link_text, field_name, options={}
    default_order = options[:default_order] || 'asc'

    if params[:sort] == field_name.to_s
      link_display = (params[:order] == default_order) ? 'normal' : 'inverse'
      next_order = (params[:order] == 'asc') ? 'desc' : 'asc'
      is_active = true
    else
      link_display = 'normal'
      next_order = default_order
      is_active = false
    end

    link_to link_text,
            url_for(params.merge(:sort => field_name,
                                 :order => next_order)),
            :class => "#{ 'active_' if is_active}search_#{link_display}",
            :title => options[:title]
  end
end
