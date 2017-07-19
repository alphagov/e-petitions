class ModerationDelay
  include ActiveModel::Model

  attr_accessor :subject, :body

  validates :subject, presence: true, length: { maximum: 100 }
  validates :body, presence: true, length: { maximum: 2000 }

  def attributes
    { "subject" => subject, "body" => body }
  end

  def attributes=(hash)
    hash = hash.stringify_keys

    hash.each do |key, value|
      if respond_to?("#{key}=")
        public_send("#{key}=", value)
      end
    end
  end
end
