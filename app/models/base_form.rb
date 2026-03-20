module BaseForm
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Dirty
  include ActiveModel::Validations::Callbacks
  include ActiveRecord::Normalization

  Stripper = ->(attribute) { attribute.strip }

  class_methods do
    def strip_attribute(*names)
      names.each { |name| normalizes(name, with: Stripper) }
    end
  end

  attr_reader :params, :request
  delegate :param_key, to: :model_name

  def initialize(params, request)
    @params = params
    @request = request

    super(model_params)
  end

  def save
    return false unless valid?
    block_given? ? yield : true
  end

  private

  def model_params
    params.fetch(param_key, {}).permit(permitted_params)
  end

  def permitted_params
    self.class.attribute_names
  end
end
