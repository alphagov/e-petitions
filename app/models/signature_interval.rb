class SignatureInterval
  attr_reader :starts_at, :ends_at, :count

  def initialize(starts_at:, ends_at:, count:)
    @starts_at = starts_at
    @ends_at = ends_at
    @count = count
  end
end
