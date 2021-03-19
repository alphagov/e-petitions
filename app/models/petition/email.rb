class Petition < ActiveRecord::Base
  class Email < ActiveRecord::Base
    belongs_to :petition, touch: true

    validates :petition, presence: true
    validates :subject, presence: true, length: { maximum: 100 }
    validates :body, presence: true, length: { maximum: 5000 }

    class << self
      def default_scope
        order(:created_at)
      end
    end
  end
end
