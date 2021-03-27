require_dependency 'constituency/api_client'
require_dependency 'constituency/api_query'

class Constituency < ActiveRecord::Base
  MP_URL = "https://members.parliament.uk/member/%{mp_id}/contact"

  belongs_to :region, primary_key: :external_id, optional: true
  has_many :signatures, primary_key: :external_id
  has_many :petitions, through: :signatures

  validates :name, presence: true, length: { maximum: 100 }
  validates :external_id, presence: true, length: { maximum: 30 }
  validates :ons_code, presence: true, format: %r[\A(?:E|W|S|N)\d{8}\z]
  validates :mp_id, length: { maximum: 30 }
  validates :mp_name, length: { maximum: 100 }
  validates :example_postcode, presence: true

  delegate :query, :example_postcodes, to: "self.class"

  before_validation unless: :example_postcode? do
    self.example_postcode = example_postcodes[ons_code]
  end

  before_validation if: :name_changed? do
    self.slug = name.parameterize
  end

  validate on: :update, if: :example_postcode_changed? do
    results = query.fetch(example_postcode)
    attributes = results.first

    if attributes.nil? || external_id != attributes[:external_id]
      errors.add :example_postcode, :invalid
    end
  end

  class << self
    def for(external_id, &block)
      find_or_initialize_by(external_id: external_id).tap(&block)
    end

    def by_ons_code
      order(ons_code: :asc)
    end

    def find_by_postcode(postcode)
      return if Site.disable_constituency_api?

      results = query.fetch(postcode)

      if attributes = results.first
        constituency = find_or_initialize_by(external_id: attributes[:external_id])
        constituency.attributes = attributes
        if constituency.changed? || constituency.new_record?
          constituency.save!
        end

        constituency
      end
    end

    def query
      ApiQuery.new
    end

    def example_postcodes
      @example_postcodes ||= YAML.load_file(Rails.root.join("data", "example_postcodes.yml"))
    end
  end

  def sitting_mp?
    mp_id?
  end

  def mp_url
    MP_URL % { mp_id: mp_id }
  end

  def to_param
    slug
  end
end
