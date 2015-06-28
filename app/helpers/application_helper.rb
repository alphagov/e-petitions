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
end
