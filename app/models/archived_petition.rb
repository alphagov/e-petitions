class ArchivedPetition < ActiveRecord::Base
  OPEN_STATE = 'open'
  REJECTED_STATE = 'rejected'
  STATES = [OPEN_STATE, REJECTED_STATE]

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :state, presence: true, inclusion: STATES

  searchable do
    text :title
    text :description
  end

  def open?
    state == OPEN_STATE && closed_at.nil?
  end

  def closed?(time = Time.current)
    state == OPEN_STATE && !!closed_at && closed_at <= time
  end

  def rejected?
    state == REJECTED_STATE
  end
end
