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

  def error(msg, backtrace = nil)
    hoptoad_params = {
      :error_class => @error_class,
      :error_message => msg.dup
    }
    if backtrace
      hoptoad_params[:backtrace] = backtrace
      msg = "#{msg}\n" + backtrace.join("\n")
    end
    HoptoadNotifier.notify(hoptoad_params)

    add(ERROR, nil, msg)
  end
end
