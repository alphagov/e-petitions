module Archived
  class Note < ApplicationRecord
    belongs_to :petition, touch: true

    validates :petition, presence: true
  end
end
