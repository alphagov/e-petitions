class Topic < ActiveRecord::Base
  include Browseable

  query :code, :name

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
  end

  private

  def remove_topic_from_petitions
    Petition.for_topic(id).update_all(["topics = array_remove(topics, ?)", id])
  end

  def remove_topic_from_archived_petitions
    Archived::Petition.for_topic(id).update_all(["topics = array_remove(topics, ?)", id])
  end
end
