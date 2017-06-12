module SearchHelper
  def paginate(petitions)
    options = {
      scope: :"petitions.pagination",
      previous_page: petitions.previous_page,
      next_page: petitions.next_page,
      total_pages: petitions.total_pages,
      previous_link: polymorphic_path(petitions.model, petitions.previous_params),
      next_link: polymorphic_path(petitions.model, petitions.next_params)
    }

    capture do
      concat t(:previous_html, options) unless petitions.first_page?
      concat t(:next_html, options) unless petitions.last_page?
    end
  end

  def filtered_petition_count(petitions)
    total_entries = petitions.total_entries
    noun = petitions.search? ? 'result' : 'petition'
    "#{number_with_delimiter(total_entries)} #{noun.pluralize(total_entries)}"
  end

  def search_form_search_types
    [
      { display_name: "Keyword", value: "keyword" },
      { display_name: "Signature Name", value: "sig_name" },
      { display_name: "Signature Email", value: "sig_email" },
      { display_name: "IP Address", value: "ip_address" },
      { display_name: "Petition ID", value: "petition_id" },
      { display_name: "Tag", value: "tag" },
    ]
  end

  def check_tag_filter?(tags, tag)
    return false unless tags.kind_of?(Array)
    tags.include?(tag)
  end

  def check_search_type?(current_search_type, radio_button_value)
    current_search_type == radio_button_value || radio_button_value == "keyword" ? true : false
  end
end
