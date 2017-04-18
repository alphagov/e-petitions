module SearchHelper
  def paginate(petitions)
    petition_class = petitions.klass.first.class
    options = {
      scope: :"petitions.pagination",
      previous_page: petitions.previous_page,
      next_page: petitions.next_page,
      total_pages: petitions.total_pages,
      previous_link: polymorphic_path(petition_class, petitions.previous_params),
      next_link: polymorphic_path(petition_class, petitions.next_params)
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
