class Region < ActiveRecord::Base
  has_many :constituencies, primary_key: :external_id

  validates :external_id, presence: true, length: { maximum: 30 }
  validates :name, presence: true, length: { maximum: 50 }
  validates :ons_code, presence: true, length: { maximum: 10 }

  class << self
    def default_scope
      order(:ons_code)
    end

    def for(external_id, &block)
      find_or_initialize_by(external_id: external_id).tap(&block)
    end
  end
end
