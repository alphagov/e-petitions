class SystemSetting < ActiveRecord::Base
  THRESHOLD_SIGNATURE_COUNT = "threshold_signature_count"
  GET_AN_MP_SIGNATURE_COUNT = "get_an_mp_signature_count"

  # = Validations =
  validates_length_of :key, :maximum => 64
  validates_uniqueness_of :key
  validates_format_of :key, :with => /\A[a-z0-9_]+\z/i

  # = Finders =
  scope :by_key, -> { order(:key) }

  # = Methods =
  def to_param
    self.key
  end

  def self.human_name(options = {})
    'System setting'
  end

  def self.seed(key, options = {})
    initial_value = options.delete(:initial_value)

    system_setting = find_or_initialize_by(key: key)
    if system_setting.new_record?
      system_setting.value =  initial_value || ""
    end
    system_setting.description = options.delete(:description) || system_setting.description || ""
    raise "Unknown options: %s" % options.keys.join(", ") unless options.empty?
    system_setting.save!
  end

  def self.value_of_key(key)
    ss = SystemSetting.find_by(key: key)
    ss && ss.value
  end
end
