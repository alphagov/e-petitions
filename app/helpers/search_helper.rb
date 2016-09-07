module SearchHelper
  def paginate(petitions)
    options = {
      scope: :"petitions.pagination",
      previous_page: petitions.previous_page,
      next_page: petitions.next_page,
      total_pages: petitions.total_pages,
      previous_link: petitions_path(petitions.previous_params),
      next_link: petitions_path(petitions.next_params)
    }

    concat(t :previous_html, options) unless petitions.first_page?
    concat(t :next_html, options) unless petitions.last_page?
  end

  def filtered_petition_count(petitions)
    total_entries = petitions.total_entries
    noun = petitions.search? ? 'result' : 'petition'
    "#{number_with_delimiter(total_entries)} #{noun.pluralize(total_entries)}"
  end
end
