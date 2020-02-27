FeedbackSignature = Struct.new(:petition) do
  def name
    'Petitions team'
  end

  def email
    rfc2822.address
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
