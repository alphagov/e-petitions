class Feedback
  include ActiveModel::Validations
  include ActiveModel::Conversion

  validates_presence_of :comment, :message => "%{attribute} must be completed"
  validates_format_of :email, :with => EMAIL_REGEX, :unless => 'email.blank?', :message => "Email not recognised."

  attr_accessor :email, :petition_link_or_title, :comment

  def initialize(options = {})
    @email = options[:email]
    @petition_link_or_title = options[:petition_link_or_title]
    @comment = options[:comment]
  end

  def persisted?
    false
  end
end
