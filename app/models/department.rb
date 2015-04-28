# == Schema Information
#
# Table name: departments
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)     not null
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#  website_url :string(255)
#

class Department < ActiveRecord::Base

  # = Relationships =
  has_many :petitions

  # = Validations =
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false

  # = Finders =
  scope :by_name, -> { order(:name) }
  scope :by_petition_count, -> { joins(:petitions).order("count('petitions.id') DESC").group('departments.id') }

  # = Methods =
  def count_petitions_for_state(state)
    petitions.for_state(state).count
  end
end
