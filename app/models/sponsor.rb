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

  include EmailEncrypter
  include PerishableTokenGenerator

  # = Relationships =
  belongs_to :petition
  belongs_to :signature

  # = Validations =
  validates :encrypted_email,
            uniqueness: { scope: :petition,
                          message: "Sponsor Emails for Petition should be unique" }
  validates_presence_of :petition, message: "Needs a petition"

  validates :email, exclusion: {
    in: -> (sponsor) { Array(sponsor.petition.creator_signature.email) },
    message: 'Petition creator cannot sponsor the petition',
    if: :petition
  }

  def build_signature(new_attributes = {})
    super(new_attributes.merge(default_signature_attribtues))
  end

  def create_signature(new_attributes = {})
    super(new_attributes.merge(default_signature_attribtues))
  end

  def create_signature!(new_attributes = {})
    super(new_attributes.merge(default_signature_attribtues))
  end

  private
  def default_signature_attribtues
    {petition: petition, email: email, email_confirmation: email}
  end
end
