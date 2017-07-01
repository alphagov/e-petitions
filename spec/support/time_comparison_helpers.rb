RSpec::Matchers.define :be_usec_precise_with do |expected|
  match do |actual|
    expect(actual).to be_within(usec_precision).of expected
  end

  failure_message do |actual|
    "\nexpected #{formatted(actual)} to #{description}\n\n\n"
  end

  failure_message_when_negated do |actual|
    "\nexpected #{formatted(actual)} not to #{description}\n\n\n"
  end

  description do
    "be within 1 microsecond of #{formatted(expected)}"
  end

  private

  def usec_precision
    @_usec ||= 0.000001.seconds
  end

  def formatted(object)
    RSpec::Support::ObjectFormatter.format(object)
  end
end
