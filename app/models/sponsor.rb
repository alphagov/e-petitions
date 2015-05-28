# == Schema Information
#
# Table name: sponsors
#
#  id               :integer          not null, primary key
#  encrypted_email  :string(255)
#  perishable_token :string(255)
#  petition_id      :integer
#  signature_id     :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null


class Sponsor < ActiveRecord::Base

  # = Relationships =
  belongs_to :petition
  belongs_to :signature

  # = Validations =
  validates_presence_of :petition, message: "Needs a petition"

  def self.supporting_the_petition
    where.not(signature_id: nil)
  end
  def supports_the_petition?
    signature.present?
  end

  def self.for(signature)
    find_by(signature_id: signature.id)
  end

  def self.for_email(email)
    joins(:signature).merge(Signature.for_email(email))
  end

  def build_signature(new_attributes = {})
    super(new_signature_attributes_with_defaults(new_attributes))
  end

  def create_signature(new_attributes = {})
    super(new_signature_attributes_with_defaults(new_attributes))
  end

  def create_signature!(new_attributes = {})
    super(new_signature_attributes_with_defaults(new_attributes))
  end

  private
  def new_signature_attributes_with_defaults(new_attributes)
    new_attributes.symbolize_keys.except(:petition_id).merge(default_signature_attributes)
  end

  def default_signature_attributes
    {petition: petition}
  end
end
