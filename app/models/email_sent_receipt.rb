class EmailSentReceipt < ActiveRecord::Base
  belongs_to :signature, touch: true

  validates :signature, presence: true
  validates :signature_id, uniqueness: true

  def get(name)
    raise ArgumentError unless valid_timestamp?(name)
    self[name]
  end

  def set(name, time)
    raise ArgumentError unless valid_timestamp?(name)
    update_column(name, time)
  end

  private
  def valid_timestamp?(name)
    possible_timestamps.include? name
  end

  def possible_timestamps
    @_possiblities ||= attributes.keys - ['id', 'signature_id', 'created_at', 'updated_at']
  end
end
