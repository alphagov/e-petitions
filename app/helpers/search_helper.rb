module SearchHelper
  def will_paginate_petitions(collection_or_options = nil, options = {})
    options[:page_links] = false
    options[:previous_label] =
      "<span class='icon icon-paginate-previous paginate paginate-previous'></span>
       <span class='paginate paginate-previous'>Previous</span>"
    options[:next_label] =
      "<span class='icon icon-paginate-next paginate paginate-next'></span>
       <span class='paginate paginate-next'>Next</span>"
    will_paginate *[collection_or_options, options].compact
  end

  def filtered_petition_count(petitions)
    total_entries = petitions.total_entries
    noun = petitions.search? ? 'result' : 'petition'
    "#{number_with_delimiter(total_entries)} #{noun.pluralize(total_entries)}"
  end
end
