class Petition < ActiveRecord::Base
  class Email < ActiveRecord::Base
    belongs_to :petition, touch: true

    validates :petition, presence: true
    validates :subject, presence: true, length: { maximum: 150 }
    validates :body, presence: true, length: { maximum: 6000 }

    class << self
      def default_scope
        order(:created_at)
      end
    end

    def to_liquid
      PetitionEmailDrop.new(self)
    end
  end
end
