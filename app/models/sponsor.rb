class Sponsor < ApplicationRecord

  # = Relationships =
  belongs_to :petition
  belongs_to :signature

  # = Validations =
  validates_presence_of :petition

  def self.supporting_the_petition
    joins(:signature).merge(Signature.validated)
  end
  def supports_the_petition?
    signature.present? && signature.validated?
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
