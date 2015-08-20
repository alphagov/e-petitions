require_dependency 'constituency/api_client'
require_dependency 'constituency/api_query'

class Constituency < ActiveRecord::Base
  MP_URL = "http://www.parliament.uk/biographies/commons"

  has_many :signatures, primary_key: :external_id
  has_many :petitions, through: :signatures

  validates :name, presence: true, length: { maximum: 100 }
  validates :external_id, presence: true, length: { maximum: 30 }
  validates :ons_code, presence: true, format: %r[\A(?:E|W|S|N)\d{8}\z]
  validates :mp_id, length: { maximum: 30 }
  validates :mp_name, length: { maximum: 100 }

  before_validation if: :name_changed? do
    self.slug = name.parameterize
  end

  class << self
    def find_by_postcode(postcode)
      results = query.fetch(postcode)

      if attributes = results.first
        find_or_initialize_by(external_id: attributes[:external_id]) do |constituency|
          constituency.attributes = attributes

          if constituency.changed? || constituency.new_record?
            constituency.save!
          end
        end
      end
    end

    private

    def query
      ApiQuery.new
    end
  end

  def mp_url
    "#{MP_URL}/#{mp_name.parameterize}/#{mp_id}"
  end
end
