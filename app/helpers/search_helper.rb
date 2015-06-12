module SearchHelper
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
end
