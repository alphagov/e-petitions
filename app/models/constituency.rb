require 'postcode_sanitizer'

class Constituency < ActiveRecord::Base
  include Translatable

  translate :name

  belongs_to :region
  has_one :member
  has_many :postcodes

  has_many :signatures
  has_many :petitions, through: :signatures

  delegate :name, :url, to: :member, prefix: true

  default_scope { preload(:member, :region).order(:id) }

  class << self
    def find_by_postcode(query)
      joins(:postcodes).where(postcode.eq(sanitize_postcode(query))).take
    end

    private

    def postcode
      Postcode.arel_table[:id]
    end

    def sanitize_postcode(postcode)
      PostcodeSanitizer.call(postcode)
    end
  end

  def slug
    name.parameterize
  end
end
