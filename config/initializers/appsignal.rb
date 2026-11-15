if ENV["SERVER_TYPE"] == "counter"
  Appsignal::Probes.register :delayed_job_probe, -> {
    Appsignal.set_gauge("delayed_job_queue_length", Delayed::Job.count)
  }
end
