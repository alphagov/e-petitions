module Archived
  class Petition < ActiveRecord::Base
    class Email < ActiveRecord::Base
      belongs_to :petition, touch: true

      validates :petition, presence: true
      validates :subject, presence: true, length: { maximum: 150 }
      validates :body, presence: true, length: { maximum: 10000 }

      class << self
        def default_scope
          order(:created_at)
        end
      end

      def occurred_on
        super || default_occurred_on
      end

      private

      def default_occurred_on
        persisted? ? created_at.to_date : nil
      end
    end
  end
end
