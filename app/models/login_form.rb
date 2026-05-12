class LoginForm
  include BaseForm

  attribute :username, :string
  attribute :password, :string

  strip_attribute :username, :password

  validate do
    errors.add(:username, :blank) unless username.present?
    errors.add(:password, :blank) unless password.present?

    if errors.none?
      errors.add(:username, :invalid) unless authenticated?
    end
  end

  delegate :username, :password_digest, to: :Site, prefix: :site

  private

  def authenticated?
    site_username == username && site_password_digest == password
  end
end
