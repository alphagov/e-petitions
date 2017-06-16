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
    noun = petitions.keyword_search? ? 'result' : 'petition'
    "#{number_with_delimiter(total_entries)} #{noun.pluralize(total_entries)}"
  end

  def search_form_search_types
    [
      { display_name: "Petition", value: "petition" },
      { display_name: "Signature", value: "signature" },
    ]
  end

  def check_tag_filter?(tags, tag)
    return false unless tags.kind_of?(Array)
    tags.include?(tag)
  end

  def check_search_type?(current_search_type, radio_button_value)
    current_search_type == radio_button_value || radio_button_value == "petition" ? true : false
  end
end
