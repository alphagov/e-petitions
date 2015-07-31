# Stop the AppSignal agent thread and restart it when the workers are forked
Appsignal.agent.stop_thread if defined?(Appsignal) && Appsignal.config.active?
