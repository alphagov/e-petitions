class ActiveJob::Base
  def logger
    @logger ||= JobLogger.new(self.class.name)
  end
end
