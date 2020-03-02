require 'textacular/searchable'

class Department < ActiveRecord::Base
  extend Searchable(:name, :acronym)
  include Browseable

  validates :external_id, length: { maximum: 30 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :acronym, length: { maximum: 10 }
  validates :url, length: { maximum: 100 }

  after_destroy :remove_department_from_petitions
  after_destroy :remove_department_from_archived_petitions

  facet :all, -> { by_name }

  class << self
    def by_name
      order(name: :asc)
    end

    def for(external_id, &block)
      find_or_initialize_by(external_id: external_id).tap(&block)
    end
  end

  def label
    acronym || name
  end

  private

  def remove_department_from_petitions
    Petition.for_department(id).update_all(["departments = array_remove(departments, ?)", id])
  end

  def remove_department_from_archived_petitions
    Archived::Petition.for_department(id).update_all(["departments = array_remove(departments, ?)", id])
  end
end
