module ApplicationHelper
  def increment(amount = 1)
    @counter ||= 0
    @counter += amount
  end

  def home_page?
    params.values_at(:controller, :action) == %w[static_pages home]
  end
end
