class RejectionReason < ActiveRecord::Base
  with_options presence: true, uniqueness: true do
    validates :code, length: { maximum: 30 }, format: { with: /\A[-a-z]+\z/ }
    validates :title, length: { maximum: 100 }
  end

  with_options presence: true do
    validates :description, length: { maximum: 1000 }
  end

  before_destroy do
    throw :abort if used?
  end

  class << self
    def default_scope
      order(:created_at)
    end

    def codes
      pluck(:code)
    end

    def hidden
      where(hidden: true)
    end

    def hidden_codes
      hidden.pluck(:code)
    end
  end

  def label
    hidden ? "#{title} (will be hidden)" : title
  end

  def used?
    Rejection.used?(code) || Archived::Rejection.used?(code)
  end
end
