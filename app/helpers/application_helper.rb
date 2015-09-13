require 'uri'

module ApplicationHelper
  INDEXED_PAGES = [
    %w[pages index],
    %w[pages help],
    %w[pages privacy],
    %w[local_petitions index],
    %w[local_petitions show],
    %w[petitions index],
    %w[petitions show],
    %w[petitions new],
    %w[archived/petitions index],
    %w[archived/petitions show]
  ]

  def increment(amount = 1)
    @counter ||= 0
    @counter += amount
  end

  def home_page?
    params.values_at(:controller, :action) == %w[pages index]
  end

  def create_petition_page?
    params[:controller] == 'petitions' && params[:action].in?(%w[check create new])
  end

  def petition_page?
    params.values_at(:controller, :action) == %w[petitions show]
  end

  def archived_petition_page?
    params[:controller] == 'archived/petitions' && params[:action] == 'show'
  end

  def back_url
    referer_url || 'javascript:history.back()'
  end

  def noindex_page?
    !params.values_at(:controller, :action).in?(INDEXED_PAGES)
  end

  private

  def referer_url
    begin
      uri = URI.parse(request.referer)
      %i[scheme host port].all?{ |k| uri.send(k) == request.send(k) } ? request.referer : nil
    rescue URI::InvalidURIError => e
      nil
    end
  end
end
