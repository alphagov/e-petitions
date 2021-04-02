class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    value = record.read_attribute_before_type_cast(attribute)

    if value.present? && value.acts_like?(:string)
      begin
        Date.parse(value.to_s)
      rescue ArgumentError
        record.errors.add(attribute, (options[:message] || :invalid))
      end
    end
  end
end
