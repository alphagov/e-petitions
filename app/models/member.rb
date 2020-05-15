class Member < ActiveRecord::Base
  URL_EN = "https://senedd.wales/en/memhome/Pages/MemberProfile.aspx?mid=%{id}"
  URL_CY = "https://senedd.cymru/cy/memhome/Pages/MemberProfile.aspx?mid=%{id}"

  include Translatable

  translate :name, :party

  belongs_to :region, optional: true
  belongs_to :constituency, optional: true

  default_scope { order(:name) }

  class << self
    def for(id, &block)
      find_or_initialize_by(id: id).tap(&block)
    end
  end

  def url
    I18n.locale == :"cy-GB" ? url_cy : url_en
  end

  private

  def url_en
    URL_EN % { id: id }
  end

  def url_cy
    URL_CY % { id: id }
  end
end
