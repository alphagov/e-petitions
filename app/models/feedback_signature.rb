FeedbackSignature = Struct.new(:petition, :name, :email) do
  def model_name
    @_model_name ||= ActiveModel::Name.new(self, nil, "Signature")
  end

  def to_model
    self
  end

  def persisted?
    true
  end

  def name
    self[:name] || 'Petitions team'
  end

  def email
    self[:email] || rfc2822.address
  end

  def unsubscribe_token
    'ThisIsNotAToken'
  end

  def to_param
    '0'
  end

  def creator?
    false
  end

  def sponsor?
    false
  end

  def anonymized?
    false
  end

  private

  def rfc2822
    @rfc2822 ||= Mail::Address.new(Site.feedback_email)
  end
end
