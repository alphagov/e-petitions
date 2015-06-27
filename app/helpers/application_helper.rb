module ApplicationHelper
  def increment(amount = 1)
    @counter ||= 0
    @counter += amount
  end
end
