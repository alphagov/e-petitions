class Contact < ActiveRecord::Base
  belongs_to :signature

  validates :signature, presence: true
  validates :address, presence: true, length: { maximum: 500 }
  validates :phone_number, presence: true, length: { maximum: 31 }

  def address=(value)
    super(value.to_s.strip)
  end

  def phone_number=(value)
    super(value.to_s.tr('^1234567890', ''))
  end
end
