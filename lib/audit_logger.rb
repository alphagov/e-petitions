class AuditLogger < Logger

  def initialize(logdev, error_class, shift_age = 0, shift_size = 1048576)
    super(logdev, shift_age, shift_size)
    @level = ['test', 'cucumber'].include?(Rails.env) ? WARN : INFO
    @error_class = error_class
  end

  def format_message(severity, timestamp, progname, msg)
    puts "#{severity} #{msg}" if self.level == Logger::DEBUG
    "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n"
  end

  def error(msg, exception = nil)
    airbrake_params = {
      :error_message => msg.dup,
      :environment_name => Rails.env
    }
    airbrake_params[:error_class] = exception.nil? ? @error_class : exception.class.name
    airbrake_params[:backtrace] = exception.backtrace if ! exception.nil?
    Airbrake.notify(airbrake_params)

    add(ERROR, nil, msg)
  end
end
