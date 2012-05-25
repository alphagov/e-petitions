module SearchOrder
  def self.sort_order(params, default)
    case params[:sort]
    when 'title'
      sort_field = :title
      default_direction = :asc
    when 'count'
      sort_field = :signature_count
      default_direction = :desc
    when 'closing'
      sort_field = :closed_at
      default_direction = :asc
    when 'created'
      sort_field = :created_at
      default_direction = :asc
    else
      sort_field = default[0]
      default_direction = default[1]
    end
    direction = ['asc', 'desc'].include?(params[:order]) ? params[:order] : default_direction
    return sort_field, direction
  end
end
