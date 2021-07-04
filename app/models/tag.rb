class Tag < ActiveRecord::Base
  include Browseable

  query :name
  query :description, null: true

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, maximum: 50
  validates_length_of :description, maximum: 200

  facet :all, -> { by_name }

  after_destroy :remove_tag_from_petitions
  after_destroy :remove_tag_from_archived_petitions

  class << self
    def by_name
      order(name: :asc)
    end
  end

  private

  def remove_tag_from_petitions
    Petition.tagged_with(id).update_all(["tags = array_remove(tags, ?)", id])
  end

  def remove_tag_from_archived_petitions
    Archived::Petition.tagged_with(id).update_all(["tags = array_remove(tags, ?)", id])
  end
end
