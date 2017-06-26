module Archived
  class Petition < ApplicationRecord
    class Email < ApplicationRecord
      belongs_to :petition, touch: true

      validates :petition, presence: true
      validates :subject, presence: true, length: { maximum: 100 }
      validates :body, presence: true, length: { maximum: 5000 }
    end
  end
end
