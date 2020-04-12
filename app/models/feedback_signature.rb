class FeedbackSignature
  include GlobalID::Identification

  attr_reader :petition

  class << self
    def find(id)
      new(Petition.find(id))
    end
  end

  def initialize(petition)
    unless petition.is_a?(Petition) && petition.persisted?
      raise ArgumentError, "requires a petition that has been saved to the database"
    end

    @petition = petition
  end

  def ==(other)
    return false unless other.is_a?(self.class)
    petition == other.petition
  end
  alias :eql? :==

  def name
    "Petitions team"
  end

  def email
    Site.feedback_address
  end

  def uuid
    Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, "mailto:#{email}")
  end

  def notify_by_email?
    true
  end

  def locale
    "en-GB"
  end

  def unsubscribe_token
    'ThisIsNotAToken'
  end

  def id
    petition.id
  end

  def to_param
    "0"
  end
end
