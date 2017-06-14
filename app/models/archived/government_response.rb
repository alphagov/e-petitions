module Archived
  class GovernmentResponse < ActiveRecord::Base
    belongs_to :petition, touch: true

    validates :petition, presence: true
    validates :summary, length: { maximum: 200 }, allow_blank: true
    validates :details, length: { maximum: 10000 }, allow_blank: true

    after_create do
      petition.touch(:government_response_at)
    end
  end
end
