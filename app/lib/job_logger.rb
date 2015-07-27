class JobLogger

  #
  # Custom logger for ActiveJob classes that adds the Job class name into the log event
  # to make filtering / tracking easier
  #

  def initialize(job_class_name, logger = nil)
    @job_class_name = job_class_name
    @logger = logger
  end

  def debug(msg)
    logger.debug message: msg, job_class: job_class_name
  end

  def info(msg)
    logger.info message: msg, job_class: job_class_name
  end

  def warn(msg)
    logger.warn message: msg, job_class: job_class_name
  end

  def error(msg)
    logger.error message: msg, job_class: job_class_name
  end

  private

  attr_reader :job_class_name

  def logger
    @logger ||= Rails.logger
  end

end
