require 'textacular/searchable'

class ArchivedPetition < ActiveRecord::Base
  OPEN_STATE = 'open'
  REJECTED_STATE = 'rejected'
  STATES = [OPEN_STATE, REJECTED_STATE]

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :state, presence: true, inclusion: STATES

  extend Searchable(:title, :description)

  class << self
    def search(params)
      query = params[:q].to_s
      page  = [params[:page].to_i, 1].max

      basic_search(query).
        except(:select).
        select(arel_table[Arel.star]).
        reorder(:created_at).
        paginate(page: page, per_page: 20)
    end
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
