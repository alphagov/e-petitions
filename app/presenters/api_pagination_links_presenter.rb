class ApiPaginationLinksPresenter
  include Rails.application.routes.url_helpers

  # results should be a Browseable::Search instance that
  # exposes the attributes delegated to it below
  def initialize(results, params)
    @results, @params = results, params
  end

  def serialize
    {
      first: first_url,
      last: last_url,
      next: next_url,
      prev: prev_url
    }
  end

  private

  attr_reader :results, :params

  delegate :total_pages, :first_page?, :second_page?, :last_page?, to: :results

  # Sense check that the current page cannot be greater than the total number of pages
  def current_page
    [results.current_page, results.total_pages].min
  end

  def first_url
    url_for url_params
  end

  def last_url
    # If there are no results then the first_page == last_page
    if total_pages == 1
      first_url
    else
      url_for url_params.merge(page: total_pages)
    end
  end

  def next_url
    unless results.last_page?
      url_for url_params.merge(page: current_page + 1)
    else
      nil
    end
  end

  def prev_url
    # first page of results does not need the :page param to improve caching
    return first_url if second_page?

    # use the last_url if we have paged off the end of the results
    return last_url if results.current_page > total_pages

    # only supply a link if there is a page of results before the current_page
    if current_page > 1
      url_for url_params.merge(page: current_page - 1)
    else
      nil
    end
  end

  def url_params
    params.permit(*api_links_allowed_components)
  end

  def api_links_allowed_components
    [:protocol, :host, :port, :controller, :action, :q, :count, :state, :format]
  end
end
