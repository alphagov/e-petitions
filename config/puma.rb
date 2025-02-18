if ENV["RAILS_ENV"] == "production"
  pidfile "#{File.expand_path('../../tmp/pids/puma.pid', __FILE__)}"
  bind "unix://#{File.expand_path('../../tmp/sockets/puma.sock', __FILE__)}"

  concurrency = {
    workers: ENV.fetch("WEB_CONCURRENCY") { 4 }.to_i,
    min_threads: ENV.fetch("WEB_CONCURRENCY_MIN_THREADS") { 8 }.to_i,
    max_threads: ENV.fetch("WEB_CONCURRENCY_MAX_THREADS") { 32 }.to_i
  }

  workers(concurrency[:workers])
  threads(concurrency[:min_threads], concurrency[:max_threads])
  preload_app!

  plugin :appsignal

  if concurrency[:workers] > 0
    on_worker_boot do
      # Establish a connection to the database
      ActiveRecord::Base.establish_connection
    end
  end
end
