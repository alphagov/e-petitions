class Member < ActiveRecord::Base
  URL_EN = "https://senedd.wales/people/%{slug}/"
  URL_CY = "https://senedd.cymru/pobl/%{slug}/"

  PARTY_COLOURS = {
    'Welsh Liberal Democrats' => '#FDBB30',
    'Welsh Labour and Co-operative Party' => '#CC0000',
    'Welsh Labour' => '#DC241F',
    'Welsh Conservative Party' => '#0087DC',
    'Plaid Cymru' => '#008142'
  }

  include Translatable

  translate :name, :party

  belongs_to :region, optional: true
  belongs_to :constituency, optional: true

  default_scope { order(:name) }

  with_options prefix: true, allow_nil: true do
    delegate :name, to: :region
    delegate :name, to: :constituency
  end

  class << self
    def for(id, &block)
      find_or_initialize_by(id: id).tap(&block)
    end
  end

  def url
    I18n.locale == :"cy-GB" ? url_cy : url_en
  end

  def colour
    PARTY_COLOURS.fetch(party_en)
  end

  private

  def url_en
    URL_EN % { slug: name_en.parameterize }
  end

  def url_cy
    URL_CY % { slug: name_cy.parameterize }
  end
end
