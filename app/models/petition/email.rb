class Petition < ActiveRecord::Base
  class Email < ActiveRecord::Base
    include Translatable

    belongs_to :petition, touch: true

    translate :subject, :body

    validates :petition, presence: true
    validates :subject_en, :subject_cy, presence: true, length: { maximum: 100 }
    validates :body_en, :body_cy, presence: true, length: { maximum: 5000 }
  end
end
