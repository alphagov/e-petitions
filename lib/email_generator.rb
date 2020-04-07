require 'securerandom'

class EmailGenerator
  def self.call(number)
    new(number).call
  end

  attr_reader :number

  def initialize(number)
    @number = number
  end

  def call
    "#{signature}@example.com"
  end

  private

  def signature
    "signature-#{number}-#{suffix}"
  end

  def suffix
    SecureRandom.hex(2)
  end
end
