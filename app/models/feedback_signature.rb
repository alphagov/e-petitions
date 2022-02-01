FeedbackSignature = Struct.new(:petition, :name, :email) do
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

  def anonymized?
    false
  end

  private

  def rfc2822
    @rfc2822 ||= Mail::Address.new(Site.feedback_email)
  end
end
