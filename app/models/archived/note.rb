module Archived
  class Note < ActiveRecord::Base
    belongs_to :petition, touch: true

    validates :petition, presence: true
  end
end
