require 'textacular/searchable'

class Topic < ActiveRecord::Base
  extend Searchable(:code, :name)
  include Browseable, Translatable

  translate :code, :name

  with_options presence: true, uniqueness: true do
    validates :code_en, :code_cy, length: { maximum: 100 }
    validates :name_en, :name_cy, length: { maximum: 100 }
  end

  after_destroy :remove_topic_from_petitions

  facet :all, -> { by_name }

  class << self
    def by_name
      order(name: :asc)
    end

    def map
      all.map { |t| [t.id, t] }.to_h
    end
  end

  private

  def remove_topic_from_petitions
    Petition.for_topic(id).update_all(["topics = array_remove(topics, ?)", id])
  end
end
