require 'uri'

module ApplicationHelper
  INDEXED_PAGES = [
    %w[pages index],
    %w[pages show],
    %w[feedback new],
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

  def open_petition_page?
    petition_page? && @petition.open?
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

  def original_url
    request.original_url.force_encoding('utf-8')
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
