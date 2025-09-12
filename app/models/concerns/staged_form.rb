module StagedForm
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Dirty
  include ActiveModel::Validations::Callbacks
  include ActiveRecord::Normalization

  Stripper = ->(attribute) { attribute.strip }

  included do
    class_attribute :stages, instance_writer: false, default: []
  end

  class_methods do
    def stage(name)
      self.stages << name.to_s
    end

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

  def stage
    @stage ||= stage_param.in?(stages) ? stage_param : stages.first
  end

  def save
    if moving_backwards?
      @stage = previous_stage and return false
    end

    unless valid?(stage.to_sym)
      return false
    end

    if last_stage?
      yield if block_given?

      return true
    else
      @stage = next_stage and return false
    end
  end

  private

  def stage_param
    @stage_param ||= params[:stage].to_s
  end

  def model_params
    params.fetch(param_key, {}).permit(permitted_params)
  end

  def permitted_params
    self.class.attribute_names
  end

  def stage_index
    stages.index(stage)
  end

  def clamp_stage(index)
    index.clamp(0, stages.size - 1)
  end

  def previous_stage
    stages[clamp_stage(stage_index - 1)]
  end

  def next_stage
    stages[clamp_stage(stage_index + 1)]
  end

  def last_stage?
    stage == stages.last
  end

  def moving_backwards?
    params.key?(:move_back)
  end
end
