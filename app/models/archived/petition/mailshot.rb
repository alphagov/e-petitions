module Archived
  class Petition < ActiveRecord::Base
    class Mailshot < ActiveRecord::Base
      belongs_to :petition, touch: true

      validates :petition, presence: true
      validates :subject, presence: true, length: { maximum: 100 }
      validates :body, presence: true, length: { maximum: 10000 }

      class << self
        def default_scope
          order(:created_at)
        end
      end

      def send_preview(name: nil, email: nil)
        signature = FeedbackSignature.new(petition, name, email)
        Archived::PetitionMailer.mailshot_for_signer(petition, signature, self).deliver_now
      end
    end
  end
end
