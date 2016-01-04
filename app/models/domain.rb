class Domain < ActiveRecord::Base
  validates_presence_of :name
  validates_length_of :name, maximum: 255
  validates_format_of :name, with: /\A([a-z0-9]+(-[a-z0-9]+)*\.)*[a-z]{2,}\z/
  validates_numericality_of :current_rate, greater_than_or_equal_to: 0, only_integer: true
  validates_numericality_of :maximum_rate, greater_than_or_equal_to: 0, only_integer: true

  class << self
    def by_current_rate
      order(current_rate: :desc)
    end

    def exceeding(rate)
      where(arel_table[:current_rate].gt(rate))
    end

    def find_or_create_by_email(email)
      begin
        find_or_create_by!(name: parse_domain_from_email(email))
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end

    def unresolved
      where(resolved_at: nil)
    end

    def update_rate(name, rate)
      begin
        domain = find_or_create_by!(name: name)
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end

      domain.update_rate(rate)
    end

    def watchlist(rate: 0, limit: nil)
      unresolved.exceeding(rate).by_current_rate.limit(limit)
    end

    private

    def parse_domain_from_email(email)
      begin
        Mail::Address.new(email).domain || 'localhost'
      rescue Mail::Field::ParseError
        'localhost'
      end
    end
  end

  def allow!(now = Time.current)
    update!(resolved_at: now, state: 'allow')
  end

  def allowed?
    if top_level? || resolved?
      state != 'block'
    else
      parent_allowed?
    end
  end

  def block!(now = Time.current)
    update!(resolved_at: now, state: 'block')
  end

  def blocked?
    if top_level? || resolved?
      state == 'block'
    else
      parent_blocked?
    end
  end

  def resolved?
    resolved_at?
  end

  def update_rate(rate)
    update(current_rate: rate, maximum_rate: [rate, maximum_rate].max)
  end

  private

  def parent_allowed?
    parent_domain.allowed?
  end

  def parent_blocked?
    parent_domain.blocked?
  end

  def parent_domain
    begin
      Domain.find_or_create_by!(name: parent_name)
    rescue ActiveRecord::RecordNotUnique => e
      retry
    end
  end

  def parent_name
    if defined?(@parent_name)
      @parent_name
    else
      @parent_name = name.partition('.').last.presence
    end
  end

  def top_level?
    parent_name.nil?
  end
end
