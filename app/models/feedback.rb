class Feedback
  include ActiveModel::Validations
  include ActiveModel::Conversion

  validates_presence_of :name, :email, :email_confirmation, :comment, :message => "%{attribute} must be completed"
  validates_format_of :email, :with => Authlogic::Regex.email, :unless => 'email.blank?', :message => "Email not recognised."
  validates_confirmation_of :email

  attr_accessor :name, :email, :petition_link_or_title, :comment, :response_required

  def initialize(options = {})
    @name = options[:name]
    @email = options[:email]
    @email_confirmation = options[:email_confirmation]
    @petition_link_or_title = options[:petition_link_or_title]
    @comment = options[:comment]
    @response_required = options[:response_required] == '1'
  end

  def persisted?
    false
  end
end
