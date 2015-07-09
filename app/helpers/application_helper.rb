require 'uri'

module ApplicationHelper
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

  def back_url
    referer_url || 'javascript:history.back()'
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
