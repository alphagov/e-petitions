require 'textacular/searchable'

class Topic < ActiveRecord::Base
  extend Searchable(:code, :name)
  include Browseable

  with_options presence: true, uniqueness: true do
    validates :code, length: { maximum: 100 }
    validates :name, length: { maximum: 100 }
  end

  after_destroy :remove_topic_from_petitions
  after_destroy :remove_topic_from_archived_petitions

  facet :all, -> { by_name }

  class << self
    def by_name
      order(name: :asc)
    end

    def map
      all.map { |t| [t.id, t] }.to_h
    end

    def last_modified_at
      [maximum(:updated_at), Site.package_built_at].compact.max
    end

    def cache_control(max_age: 1.minute)
      {
        max_age: max_age,
        stale_while_revalidate: max_age * 2,
        stale_if_error: max_age * 5
      }
    end
  end

  private

  def remove_topic_from_petitions
    Petition.for_topic(id).update_all(["topics = array_remove(topics, ?)", id])
  end

  def remove_topic_from_archived_petitions
    Archived::Petition.for_topic(id).update_all(["topics = array_remove(topics, ?)", id])
  end
end
