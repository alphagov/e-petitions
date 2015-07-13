class Feedback
  include ActiveModel::Validations
  include ActiveModel::Conversion

  validates_presence_of :comment
  validates_format_of :email, with: EMAIL_REGEX, allow_blank: true

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
